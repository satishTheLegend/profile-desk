package dev.profiledesk.session_engine

import android.app.Activity
import android.annotation.SuppressLint
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.hardware.biometrics.BiometricPrompt
import android.net.Uri
import android.net.http.SslError
import android.os.Build
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.webkit.PermissionRequest
import android.webkit.RenderProcessGoneDetail
import android.webkit.SslErrorHandler
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.TextView
import androidx.webkit.ProfileStore
import androidx.webkit.WebStorageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull
import java.io.File
import java.util.UUID
import kotlin.coroutines.resume

/** Main-thread process-wide runtime. Flutter view disposal does not destroy its journal. */
internal class AndroidSessionEngine(context: Context) : SessionHostApi {
    // A process runtime must never retain a constructor-supplied Activity context.
    private val context=context.applicationContext
    private val registry=NativeRegistry(context)
    private val importJournal=ImportAllocationJournal(File(this.context.noBackupFilesDir,"profiledesk-setup-allocation-journal.json"))
    private val scope=CoroutineScope(SupervisorJob()+Dispatchers.Main.immediate)
    private val network=NetworkMonitor(this.context){emit(EngineEvent(EngineEventKind.NETWORK_CHANGED,network=it))}
    var eventSink: SessionFlutterApi?=null
    var activity: Activity?=null
    private var initialized=false
    private var restoreTrusted=false
    private var host: FrameLayout?=null
    private var web:WebView?=null
    private var cover:View?=null
    private val windowCover=WindowPrivacyCover()
    private var owner:ViewHandle?=null
    private var ready=false
    private var covered=true
    private var foreground=true
    private var locked=true
    private var lockEpoch=0L
    private var latestGeneration=Long.MIN_VALUE
    private var flutterAttachmentEpoch=0L
    private var authSignal:CancellationSignal?=null
    private val loadedProfiles=mutableSetOf<String>()
    private val wipes=mutableMapOf<String,CompletableDeferred<Unit>>()
    private var picker:Picker?=null
    private var nextPickerCode=4200
    private var authInProgress=false
    private val setupDocuments=AccountSetupDocuments(this.context,scope)
    private var workspaceLayout=WorkspaceLayout.PHONE
    private var layoutInstalled=false
    private var layoutRevision=0L
    private var presentationEligibilityEpoch=0L
    private val layoutScript:String by lazy{this.context.assets.open("workspace_layout.js").bufferedReader().use{it.readText()}}
    private data class Picker(val requestCode:Int,val taskId:String,val owner:ViewHandle,val callback:ValueCallback<Array<Uri>>)

    /** The registry outlives Flutter, but a coordinator's counter and calls do not. */
    fun attachFlutterHost():AttachedSessionHostApi {
        // Invalidate any queued calls before disposing their view/authentication owner.
        val epoch=++flutterAttachmentEpoch
        onActivityDetached()
        latestGeneration=Long.MIN_VALUE
        return AttachedSessionHostApi(this){epoch==flutterAttachmentEpoch}
    }
    fun detachFlutterHost(attachment:AttachedSessionHostApi):Boolean {
        if(!attachment.isAttached)return false
        flutterAttachmentEpoch++;onActivityDetached();latestGeneration=Long.MIN_VALUE
        return true
    }

    private fun emit(event:EngineEvent){ val sink=eventSink ?: return;scope.launch{try{sink.onEvent(event)}catch(_:Exception){ /* Dart can detach; journal remains authoritative. */ }} }
    private fun changed(){emit(EngineEvent(EngineEventKind.PROFILES_CHANGED))}
    private inline fun <T> guarded(block:()->T):T {
        check(Looper.myLooper()==Looper.getMainLooper())
        try {return block()} catch(e:FlutterError){throw e} catch(e:Exception){
            val code=when {
                e.message?.startsWith("invalidArchive")==true->"invalidArchive"
                e.message?.startsWith("archiveTooLarge:")==true->"archiveTooLarge"
                e.message?.startsWith("capacity:")==true->"capacity"
                e.message?.startsWith("cleanupRequired:")==true->"cleanupRequired"
                e.message?.startsWith("duplicateAlias")==true->"duplicateAlias"
                e is IllegalArgumentException->"invalidArgument"
                e is IllegalStateException->"invalidState"
                else->"nativeFailure"
            }
            throw FlutterError(code,"The operation could not finish. Review account status and retry.",null)
        }
    }
    private fun checkInitialized(){if(!initialized)throw FlutterError("notInitialized","Initialize the native registry first.")}
    private fun capabilities():EngineCapabilities {
        var provider="unavailable";var multiple=false;var deletion=false
        try {
            WebViewCompat.getCurrentWebViewPackage(context)?.let{provider="${it.packageName} ${it.versionName}"}
            if(provider!="unavailable") {multiple=WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE);deletion=WebViewFeature.isFeatureSupported(WebViewFeature.DELETE_BROWSING_DATA)}
        }catch(_:Exception){ /* Unsupported providers remain blocked, without fallback. */ }
        val auth=(context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager).isDeviceSecure
        return EngineCapabilities(multiple&&deletion,"android",Build.VERSION.RELEASE,provider,multiple,deletion,auth,false,false,
            if(!multiple||!deletion)"This WebView provider needs both isolated profiles and scoped browsing-data deletion. Update Android System WebView or Chrome, then restart." else null)
    }
    private fun requireSupported(){if(!capabilities().supported)throw FlutterError("unsupportedProvider","Update the WebView provider. Account management and local removal remain available.")}
    private fun preferences()=AppPreferences(registry.pref("lockEnabled","false")=="true",registry.pref("welcomeSeen","false")=="true",registry.pref("switchWarningSeen","false")=="true",registry.pref("theme","system"))
    private fun profiles():List<AccountProfile>{val cleanup=registry.cleanup().associateBy{it.profileId};return registry.rows().map{r->
        val stage=cleanup[r.id]
        AccountProfile(r.id,r.platformId,r.alias,r.color,r.position,r.created,r.opened,when(r.state){"allocating"->StoreState.ALLOCATING;"available"->StoreState.AVAILABLE;"removing"->StoreState.REMOVING;"cleanupPending"->StoreState.CLEANUP_PENDING;"missing"->StoreState.MISSING;else->StoreState.QUARANTINED},when(r.observation){"userConfirmed"->AuthObservation.USER_CONFIRMED;"relinkRequested"->AuthObservation.RELINK_REQUESTED;else->AuthObservation.UNKNOWN},stage?.operation,stage?.stage)
    }}
    override suspend fun initialize():EngineSnapshot=guarded {
        if(!initialized){
            // Open SQLite and authenticate restore provenance BEFORE any profile getter.
            registry.writableDatabase
            restoreTrusted=registry.verifyInstallBinding()
            if(!restoreTrusted) registry.rows().filter{it.state !in listOf("removing","cleanupPending")}.forEach{registry.state(it.id,"quarantined")}
            registry.rows().filter{!NativeRegistry.validIdentity(it.id,it.platformId)}.forEach{registry.state(it.id,"quarantined")}
            registry.cancelInterruptedTransfers()
            File(context.cacheDir,"profiledesk-staging").deleteRecursively()
            reconcile()
            locked=preferences().lockEnabled
            initialized=true
        }
        network.start()
        EngineSnapshot(capabilities(),profiles(),preferences(),locked,picker!=null||setupDocuments.isActive,network=network.observation)
    }
    override suspend fun queryCapabilities():EngineCapabilities=guarded {capabilities()}
    override suspend fun listProfiles():List<AccountProfile> =guarded {checkInitialized();profiles()}
    override suspend fun allocateProfile(alias:String,color:Long):AccountProfile=guarded {
        checkInitialized();requireSupported()
        if(!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE))throw FlutterError("unsupportedProvider","Isolated profiles are unavailable.")
        if(!restoreTrusted)throw FlutterError("restoreQuarantined","Restored registry access is quarantined. Remove local profiles and reset application storage before pairing again.")
        requireImportRecoveryComplete()
        val row=registry.reserve(alias,color)
        try {ProfileStore.getInstance().getOrCreateProfile(row.platformId);loadedProfiles.add(row.platformId);registry.state(row.id,"available")}
        catch(e:Exception){registry.state(row.id,"quarantined");changed();throw e}
        changed();profiles().first{it.id==row.id}
    }
    override suspend fun renameProfile(profileId:String,alias:String,color:Long)=guarded{checkInitialized();registry.rename(profileId,alias,color);changed()}
    override suspend fun reorderProfiles(profileIds:List<String>)=guarded{checkInitialized();registry.reorder(profileIds);changed()}
    override suspend fun setObservation(profileId:String,observation:AuthObservation)=guarded{checkInitialized();registry.observe(profileId,when(observation){AuthObservation.USER_CONFIRMED->"userConfirmed";AuthObservation.RELINK_REQUESTED->"relinkRequested";else->"unknown"});changed()}

    private fun reconcile(){
        // An inherited journal is not fresh user authorization after a restore mismatch.
        if(!restoreTrusted)return
        val caps=capabilities()
        if(!caps.supported || !WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE))return
        val stores=ProfileStore.getInstance()
        // Failed setup imports retain exact creation provenance outside the SQLite transaction.
        // Reclaim only unassigned owned IDs, before any profile getter loads them.
        runCatching{importJournal.reconcile(registry.rows().map{it.platformId}.toSet(),loadedProfiles,stores.allProfileNames.toSet()){stores.deleteProfile(it)}}
        // Enumeration does not load the named profiles. Never call getters before these tombstones.
        val names=stores.allProfileNames.toSet()
        for(cleanup in registry.cleanup()){
            if(!registry.cleanupAuthorized(cleanup)){
                registry.state(cleanup.profileId,"quarantined")
                registry.advance(cleanup.profileId,"identityQuarantined","invalidCleanupOwnership")
                continue
            }
            if(cleanup.platformId in loadedProfiles)continue
            try {
                if(cleanup.platformId in names)stores.deleteProfile(cleanup.platformId)
                registry.advance(cleanup.profileId,"containerDeletionAccepted")
                File(context.cacheDir,"profiledesk-staging/${cleanup.profileId}").deleteRecursively()
                registry.complete(cleanup.profileId)
                emit(EngineEvent(EngineEventKind.CLEANUP_CHANGED,profileId=cleanup.profileId,cleanupOperationId=cleanup.operation,cleanupStage="containerDeletionAccepted"))
            }catch(_:Exception){registry.advance(cleanup.profileId,cleanup.stage,"containerDeletionFailed")}
        }
        val existing=stores.allProfileNames.toSet()
        registry.rows().filter{it.state !in listOf("removing","cleanupPending","quarantined")}.forEach{row->
            when {
                row.platformId !in existing->registry.state(row.id,"missing")
                row.state=="allocating"->registry.state(row.id,"available")
            }
        }
        // Unknown native profiles are never assigned to an account or deleted without provenance.
        val known=registry.rows().map{it.platformId}.toSet()
        registry.setPref("orphanCount",existing.count{it.startsWith(NativeRegistry.PREFIX)&&it !in known}.toString())
    }

    fun attachHost(frame:FrameLayout):Boolean {
        if(host!=null && host!==frame)return false
        host=frame
        web?.let{if(it.parent==null)frame.addView(it,FrameLayout.LayoutParams(-1,-1))}
        cover=TextView(frame.context).apply{setBackgroundColor(Color.rgb(244,247,245));setTextColor(Color.rgb(25,55,45));setText(R.string.profiledesk_workspace_protected);gravity=android.view.Gravity.CENTER;importantForAccessibility=View.IMPORTANT_FOR_ACCESSIBILITY_YES;isClickable=true;isFocusable=true}
        frame.addView(cover,FrameLayout.LayoutParams(-1,-1));applyCover();return true
    }
    fun detachHost(frame:FrameLayout){if(host===frame){disposeCurrent();host=null;cover=null}}
    private fun showCover(){presentationEligibilityEpoch++;covered=true;applyCover()}
    private fun applyCover(){
        cover?.visibility=if(covered||locked||!foreground)View.VISIBLE else View.GONE
        cover?.bringToFront()
        web?.importantForAccessibility=if(covered||locked||!foreground)View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS else View.IMPORTANT_FOR_ACCESSIBILITY_AUTO
        if(!foreground||(initialized&&locked))windowCover.show(activity,foreground&&locked,authInProgress){
            emit(EngineEvent(EngineEventKind.UNLOCK_REQUESTED))
        }else windowCover.hide()
    }
    private fun isCurrent(candidate:ViewHandle)=owner==candidate && registry.get(candidate.profileId)?.state=="available"
    override suspend fun openProfile(profileId:String,operationId:String,selectionGeneration:Long):ViewHandle=guarded {
        checkInitialized();requireSupported()
        if(!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE))throw FlutterError("unsupportedProvider","Isolated profiles are unavailable.")
        if(locked)throw FlutterError("locked","Unlock before opening an account.")
        if(selectionGeneration<latestGeneration)throw FlutterError("superseded","A newer selection is active.")
        val row=registry.get(profileId)?:throw FlutterError("profileUnavailable","This profile is unavailable.")
        if(!NativeRegistry.validIdentity(row.id,row.platformId)){registry.state(row.id,"quarantined");changed();throw FlutterError("restoreQuarantined","The saved profile identity is invalid. Reset application storage before pairing again.")}
        if(row.state!="available")throw FlutterError("profileUnavailable","This profile needs recovery or cleanup.")
        if(profileId in registry.cleanup().map{it.profileId})throw FlutterError("profileRemoving","This profile is being removed.")
        if(!ProfileStore.getInstance().allProfileNames.contains(row.platformId)){registry.state(profileId,"missing");changed();throw FlutterError("missingStore","The browser store is missing. Remove this local profile and link a new one.")}
        if(picker!=null||setupDocuments.isActive)throw FlutterError("transferActive","Finish or cancel file selection before switching.")
        val targetHost=host?:throw FlutterError("hostUnavailable","The workspace view is not attached yet.")
        latestGeneration=selectionGeneration;showCover();disposeCurrent()
        val handle=ViewHandle(profileId,UUID.randomUUID().toString(),operationId,selectionGeneration)
        // CRITICAL: this is the first operation on the newly constructed WebView.
        val view=WebView(activity?:context)
        try {WebViewCompat.setProfile(view,row.platformId)}catch(e:Exception){view.destroy();throw e}
        loadedProfiles.add(row.platformId)
        owner=handle;web=view;ready=false;layoutInstalled=false;workspaceLayout=WorkspaceLayout.PHONE
        try {
            configure(view,handle)
            targetHost.addView(view,0,FrameLayout.LayoutParams(-1,-1));applyCover()
            registry.opened(profileId)
            view.loadUrl(NavigationPolicy.WORKSPACE)
            Handler(Looper.getMainLooper()).postDelayed({if(isCurrent(handle)&&!ready){showCover();emit(EngineEvent(EngineEventKind.VIEW_FAILED,profileId=handle.profileId,view=handle,errorCode="navigationTimeout"))}},45000)
        } catch(e:Exception){disposeCurrent();throw e}
        handle
    }
    // The anonymous client below implements onRenderProcessGone and returns true.
    // WebKit lint currently fails to recognize that override in this Kotlin client.
    // JavaScript is essential for the allowlisted hosted application; no bridge is installed.
    @SuppressLint("MissingOnRenderProcessGone", "SetJavaScriptEnabled")
    private fun configure(view:WebView,handle:ViewHandle){
        WebView.setWebContentsDebuggingEnabled(false)
        view.settings.apply{
            // Required by the hosted application. No JavaScript bridge or credential extraction.
            javaScriptEnabled=true;domStorageEnabled=true
            allowFileAccess=false;allowContentAccess=true
            mixedContentMode=WebSettings.MIXED_CONTENT_NEVER_ALLOW
            safeBrowsingEnabled=true;mediaPlaybackRequiresUserGesture=true
            javaScriptCanOpenWindowsAutomatically=false;setSupportMultipleWindows(false)
            setGeolocationEnabled(false);builtInZoomControls=true;displayZoomControls=false
        }
        view.webViewClient=object:WebViewClient(){
            override fun shouldOverrideUrlLoading(view:WebView,request:WebResourceRequest):Boolean {
                if(!isCurrent(handle))return true
                val url=request.url.toString()
                if(!request.isForMainFrame)return false
                if(NavigationPolicy.trusted(url))return false
                if(request.hasGesture() && NavigationPolicy.external(url))try{openExternal(request.url)}catch(_:Exception){emit(EngineEvent(EngineEventKind.VIEW_FAILED,profileId=handle.profileId,view=handle,errorCode="browserUnavailable"))}
                else if(request.hasGesture() && request.url.scheme=="tel")try{activity?.startActivity(Intent(Intent.ACTION_DIAL,request.url))}catch(_:Exception){ }
                return true
            }
            override fun onPageStarted(view:WebView,url:String?,favicon:android.graphics.Bitmap?){if(isCurrent(handle)){layoutRevision++;ready=false;layoutInstalled=false;showCover()}}
            override fun onPageFinished(view:WebView,url:String?){
                if(isCurrent(handle)&&web===view&&host!=null&&!layoutInstalled&&!locked&&foreground&&NavigationPolicy.trusted(url)&&NavigationPolicy.trusted(view.url))installLayout(view)
            }
            override fun onPageCommitVisible(view:WebView,url:String?){
                if(isCurrent(handle)&&NavigationPolicy.trusted(url))view.postVisualStateCallback(0,object:WebView.VisualStateCallback(){override fun onComplete(requestId:Long){if(isCurrent(handle)&&web===view&&NavigationPolicy.trusted(view.url)){ready=true;if(!locked&&foreground&&!layoutInstalled)installLayout(view);emit(EngineEvent(EngineEventKind.VIEW_READY,profileId=handle.profileId,view=handle))}}})
            }
            override fun onReceivedError(view:WebView,request:WebResourceRequest,error:WebResourceError){if(request.isForMainFrame&&isCurrent(handle)){showCover();emit(EngineEvent(EngineEventKind.VIEW_FAILED,profileId=handle.profileId,view=handle,errorCode="navigationFailed"))}}
            override fun onReceivedSslError(view:WebView,handler:SslErrorHandler,error:SslError){handler.cancel();if(isCurrent(handle)){showCover();emit(EngineEvent(EngineEventKind.VIEW_FAILED,profileId=handle.profileId,view=handle,errorCode="tlsRejected"))}}
            override fun onRenderProcessGone(view:WebView,detail:RenderProcessGoneDetail):Boolean {
                if(isCurrent(handle)){showCover();disposeCurrent();emit(EngineEvent(EngineEventKind.VIEW_FAILED,profileId=handle.profileId,view=handle,errorCode="rendererGone"))}else{(view.parent as? ViewGroup)?.removeView(view);view.destroy()}
                return true
            }
        }
        view.webChromeClient=object:WebChromeClient(){
            override fun onShowFileChooser(webView:WebView,callback:ValueCallback<Array<Uri>>,params:FileChooserParams):Boolean {
                if(!isCurrent(handle)||locked||!foreground||setupDocuments.isActive||!NavigationPolicy.trusted(webView.url)||params.isCaptureEnabled){deliverPickerCallback(callback,null);emit(EngineEvent(EngineEventKind.TRANSFER_CHANGED,profileId=handle.profileId,view=handle,errorCode="captureUnsupported"));return true}
                cancelPicker()
                val currentActivity=activity
                if(currentActivity==null){deliverPickerCallback(callback,null);return true}
                val task=UUID.randomUUID().toString()
                val requestCode=nextPickerCode++
                if(nextPickerCode>=65000)nextPickerCode=4200
                val intent=Intent(Intent.ACTION_OPEN_DOCUMENT).apply{
                    addCategory(Intent.CATEGORY_OPENABLE);type="*/*";addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE,params.mode==FileChooserParams.MODE_OPEN_MULTIPLE)
                    val types=params.acceptTypes.filter{it.matches(Regex("[a-zA-Z0-9.+-]+/(?:[a-zA-Z0-9.+-]+|\\*)"))}.toTypedArray()
                    if(types.isNotEmpty())putExtra(Intent.EXTRA_MIME_TYPES,types)
                }
                try{registry.recordTransfer(task,handle.profileId,handle.viewInstanceId,handle.operationId);picker=Picker(requestCode,task,handle,callback);currentActivity.startActivityForResult(intent,requestCode);emit(EngineEvent(EngineEventKind.TRANSFER_CHANGED,profileId=handle.profileId,view=handle,transferActive=true))}
                catch(_:Exception){picker=null;finishPicker(Picker(requestCode,task,handle,callback),null);emit(EngineEvent(EngineEventKind.TRANSFER_CHANGED,profileId=handle.profileId,view=handle,errorCode="pickerUnavailable",transferActive=false))}
                return true
            }
            override fun onPermissionRequest(request:PermissionRequest){
                // Capture is a conditional feature, not proven for this embedded client.
                request.deny()
                if(isCurrent(handle)&&NavigationPolicy.trusted(request.origin.toString()))request.resources.forEach{registry.recordDeniedPermission(handle.profileId,"https://web.whatsapp.com",when(it){PermissionRequest.RESOURCE_AUDIO_CAPTURE->"microphone";PermissionRequest.RESOURCE_VIDEO_CAPTURE->"camera";else->"unsupported"})}
                emit(EngineEvent(EngineEventKind.TRANSFER_CHANGED,profileId=handle.profileId,view=handle,errorCode="captureUnsupported"))
            }
            override fun onGeolocationPermissionsShowPrompt(origin:String,callback:android.webkit.GeolocationPermissions.Callback){callback.invoke(origin,false,false)}
            override fun onCreateWindow(view:WebView,isDialog:Boolean,isUserGesture:Boolean,resultMsg:android.os.Message):Boolean=false
        }
        view.setDownloadListener { _,_,_,_,_->if(isCurrent(handle))emit(EngineEvent(EngineEventKind.TRANSFER_CHANGED,profileId=handle.profileId,view=handle,errorCode="downloadUnsupported")) }
    }
    override suspend fun disposeView(view:ViewHandle)=guarded{if(owner==view){showCover();disposeCurrent()}}
    private fun disposeCurrent(){
        layoutRevision++;showCover();ready=false
        val old=web;val oldOwner=owner;web=null;owner=null
        cancelPicker()
        old?.let{
            // Keep the renderer-loss handler installed until destroy has completed.
            try{if(NavigationPolicy.trusted(it.url))it.evaluateJavascript(WorkspaceLayoutCommands.dispose,null);it.stopLoading();it.webChromeClient=null;it.setDownloadListener(null)}catch(_:RuntimeException){ }
            finally{(it.parent as? ViewGroup)?.removeView(it);try{it.destroy()}catch(_:RuntimeException){ }}
        }
        flushCookies(oldOwner)
    }
    private fun flushCookies(candidate:ViewHandle?){
        if(candidate==null||!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE))return
        val row=registry.get(candidate.profileId)?:return
        // Never touch another identity, missing store, tombstone or the default profile.
        if(row.state!="available"||!NativeRegistry.validIdentity(row.id,row.platformId)||row.platformId !in loadedProfiles)return
        try{ProfileStore.getInstance().getProfile(row.platformId)?.let{ProfilePersistence.flushCookies(it)}}
        catch(_:Exception){showCover();emit(EngineEvent(EngineEventKind.VIEW_FAILED,profileId=candidate.profileId,view=candidate,errorCode="persistenceFailed"))}
    }
    override suspend fun reloadProfileView(view:ViewHandle)=guarded{if(!isCurrent(view))throw FlutterError("staleView","The selected view changed.");if(locked)throw FlutterError("locked","Unlock first.");if(!ready)throw FlutterError("navigationBusy","Wait for loading, or reopen this profile.");if(picker!=null||setupDocuments.isActive)throw FlutterError("transferActive","Finish or cancel file selection.");showCover();ready=false;web?.reload();Unit}
    private fun installLayout(view:WebView){
        // Static bundled code only; there is no arbitrary script or page-to-native bridge.
        view.evaluateJavascript(layoutScript,null)
        view.evaluateJavascript(WorkspaceLayoutCommands.mode(workspaceLayout),null)
        layoutInstalled=true
    }
    private fun checkedLayoutView(handle:ViewHandle):WebView {
        checkInitialized()
        if(!isCurrent(handle)||web==null||host==null||web?.parent!==host)throw FlutterError("staleView","The selected view changed.")
        if(locked||!foreground)throw FlutterError("locked","Return to the unlocked workspace.")
        if(!ready||!NavigationPolicy.trusted(web?.url))throw FlutterError("navigationBusy","Wait for the workspace to load.")
        return requireNotNull(web)
    }
    override suspend fun setWorkspaceLayout(view:ViewHandle,layout:WorkspaceLayout)=guarded{
        val target=checkedLayoutView(view);layoutRevision++;workspaceLayout=layout
        if(!layoutInstalled)installLayout(target)
        else target.evaluateJavascript(WorkspaceLayoutCommands.mode(layout),null)
        Unit
    }
    override suspend fun showWorkspaceList(view:ViewHandle)=guarded{
        val target=checkedLayoutView(view);layoutRevision++
        // End native input without reading, clearing or rewriting the web draft.
        (context.getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager)
            ?.hideSoftInputFromWindow(target.windowToken,0)
        target.clearFocus()
        if(workspaceLayout!=WorkspaceLayout.PHONE){workspaceLayout=WorkspaceLayout.PHONE
            if(!layoutInstalled)installLayout(target)
            else target.evaluateJavascript(WorkspaceLayoutCommands.mode(workspaceLayout),null)
        }
        target.evaluateJavascript(WorkspaceLayoutCommands.list,null);Unit
    }
    override suspend fun getWorkspacePresentation(view:ViewHandle):WorkspacePresentation {
        val target=guarded{checkedLayoutView(view)}
        val revision=layoutRevision;val epoch=lockEpoch;val eligibility=presentationEligibilityEpoch;val attachment=flutterAttachmentEpoch
        // A fixed, read-only query with a bounded wait. Timeout/cancellation ends
        // ownership of its callback; a late renderer reply cannot update the app.
        val result=withTimeoutOrNull(2000){
            suspendCancellableCoroutine<WorkspacePresentation>{continuation->
                target.evaluateJavascript(WorkspaceLayoutCommands.presentation){value->
                    if(continuation.isActive)continuation.resume(WorkspaceLayoutCommands.decodePresentation(value))
                }
            }
        }?:WorkspacePresentation.UNAVAILABLE
        return guarded{
            if(checkedLayoutView(view)!==target||revision!=layoutRevision||epoch!=lockEpoch||eligibility!=presentationEligibilityEpoch||attachment!=flutterAttachmentEpoch)
                throw FlutterError("staleView","The selected view changed.")
            result
        }
    }
    private fun checkSetupTransfer(){
        checkInitialized()
        if(locked||!foreground)throw FlutterError("authentication","Unlock before transferring account setup.")
        if(picker!=null||setupDocuments.isActive||authInProgress)throw FlutterError("busy","Finish the current request first.")
    }
    override suspend fun pickAccountSetupArchive():String? {
        val current=guarded{checkSetupTransfer();activity?:throw FlutterError("archiveUnavailable","Return to the application.")}
        val attachment=flutterAttachmentEpoch;val epoch=lockEpoch
        return setupDocuments.pick(current){attachment==flutterAttachmentEpoch&&epoch==lockEpoch&&!locked&&activity===current}
    }
    override suspend fun exportAccountSetupArchive():Boolean {
        val current=guarded{checkSetupTransfer();activity?:throw FlutterError("archiveUnavailable","Return to the application.")}
        val archive=guarded{AccountSetupArchive(registry.rows().filter{it.state !in listOf("removing","cleanupPending")}.map{AccountSetupArchive.Entry(it.alias,it.color)},registry.pref("theme","system")).encode()}
        val attachment=flutterAttachmentEpoch;val epoch=lockEpoch
        return setupDocuments.export(current,archive){attachment==flutterAttachmentEpoch&&epoch==lockEpoch&&!locked&&activity===current}
    }
    private fun requireImportRecoveryComplete(){
        val pending=try{importJournal.pending().isNotEmpty()}catch(_:Exception){throw FlutterError("restoreQuarantined","The interrupted setup record could not be verified. Existing accounts remain unchanged; reset app storage before importing more accounts.")}
        if(pending)throw FlutterError("cleanupRequired","Restart the app to finish an interrupted account setup import.")
    }
    override suspend fun importAccountSetupArchive(archive:String,applyAppearance:Boolean):List<AccountProfile> = guarded{
        checkSetupTransfer();requireSupported()
        if(!restoreTrusted)throw FlutterError("restoreQuarantined","Restored account setup must be reset before importing.")
        requireImportRecoveryComplete()
        val parsed=try{AccountSetupArchive.parse(archive)}catch(e:Exception){throw FlutterError(if(e.message?.startsWith("archiveTooLarge:")==true)"archiveTooLarge" else "invalidArchive","The account setup archive is invalid.")}
        val batch=try{registry.importSetup(parsed,applyAppearance){row->
            importJournal.record(row.platformId)
            ProfileStore.getInstance().getOrCreateProfile(row.platformId);loadedProfiles.add(row.platformId)
        }}catch(e:Exception){
            // SQLite rolls back metadata. Any provider artifact remains unassigned, never a login.
            runCatching{val known=registry.rows().map{it.platformId}.toSet();registry.setPref("orphanCount",ProfileStore.getInstance().allProfileNames.count{it.startsWith(NativeRegistry.PREFIX)&&it !in known}.toString())}
            changed()
            if(runCatching{importJournal.pending().isNotEmpty()}.getOrDefault(true))throw FlutterError("cleanupRequired","The import did not finish. Existing accounts are unchanged. Restart the app to finish cleanup before retrying.")
            throw e
        }
        importJournal.clear()
        changed();val ids=batch.map{it.id}.toSet();profiles().filter{it.id in ids}
    }
    override suspend fun setPrivacyCover(visible:Boolean,owner:ViewHandle?)=guarded {
        if(visible){showCover()}else{
            if(owner==null||!isCurrent(owner)||!ready||locked||!foreground)throw FlutterError("revealDenied","The current workspace is not ready to reveal.")
            if(!layoutInstalled)web?.let{installLayout(it)}
            covered=false;applyCover()
        }
    }
    private fun deliverPickerCallback(callback:ValueCallback<Array<Uri>>,uris:Array<Uri>?){try{callback.onReceiveValue(uris)}catch(_:RuntimeException){ }}
    private fun finishPicker(pending:Picker,uris:Array<Uri>?){
        try{deliverPickerCallback(pending.callback,uris)}
        finally{
            try{registry.finishTransfer(pending.taskId)}catch(_:Exception){ /* Startup reconciles an interrupted record. */ }
            emit(EngineEvent(EngineEventKind.TRANSFER_CHANGED,profileId=pending.owner.profileId,view=pending.owner,transferActive=false))
        }
    }
    private fun cancelPicker(){val pending=picker?:return;picker=null;finishPicker(pending,null)}
    override suspend fun cancelTransfer()=guarded{cancelPicker();setupDocuments.cancel()}
    fun onActivityResult(requestCode:Int,resultCode:Int,data:Intent?):Boolean {
        if(setupDocuments.onActivityResult(requestCode,resultCode,data))return true
        val pending=picker?:return false
        if(pending.requestCode!=requestCode)return false
        picker=null
        val uris=if(resultCode==Activity.RESULT_OK && isCurrent(pending.owner)&&!locked){
            val values=mutableListOf<Uri>();data?.data?.let{values.add(it)};data?.clipData?.let{clip->for(index in 0 until clip.itemCount)values.add(clip.getItemAt(index).uri)}
            values.distinct().filter{it.scheme=="content"}.toTypedArray().takeIf{it.isNotEmpty()}
        }else null
        finishPicker(pending,uris)
        return true
    }

    override suspend fun requestLocalRemoval(profileId:String,cleanupOperationId:String){
        val completion=guarded{
            checkInitialized()
            if(registry.get(profileId)==null)return
            val task=registry.tombstone(profileId,cleanupOperationId)
            if(owner?.profileId==profileId){showCover();disposeCurrent()}
            if(task.stage=="requested")registry.advance(profileId,"accessBlocked")
            changed()
            startWipe(task)
        }
        if(completion!=null && withTimeoutOrNull(30000){completion.await()}==null)throw FlutterError("cleanupPending","The wipe is still pending. Access remains blocked.")
    }
    private fun startWipe(task:NativeRegistry.Cleanup):CompletableDeferred<Unit>? {
        if(!registry.cleanupAuthorized(task)){
            registry.state(task.profileId,"quarantined")
            registry.advance(task.profileId,"identityQuarantined","invalidCleanupOwnership")
            throw FlutterError("restoreQuarantined","The saved profile identity is invalid. Reset application storage to remove this data.")
        }
        wipes[task.profileId]?.let{return it}
        if(task.stage=="containerDeletionPending")return null
        if(!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)){registry.advance(task.profileId,"websiteWipePending","unsupportedProvider");return null}
        if(!WebViewFeature.isFeatureSupported(WebViewFeature.DELETE_BROWSING_DATA)){registry.advance(task.profileId,"websiteWipePending","unsupportedProvider");return null}
        val deferred=CompletableDeferred<Unit>();wipes[task.profileId]=deferred
        try{
            val profile=ProfileStore.getInstance().getProfile(task.platformId)
            if(profile==null){registry.complete(task.profileId);wipes.remove(task.profileId);deferred.complete(Unit);changed();return deferred}
            loadedProfiles.add(task.platformId)
            // Blocks new service-worker network traffic; no unsupported stop-worker promise.
            profile.serviceWorkerController.serviceWorkerWebSettings.blockNetworkLoads=true
            val storage=profile.webStorage
            registry.advance(task.profileId,"clientsDisposed")
            registry.advance(task.profileId,"websiteWipePending")
            WebStorageCompat.deleteBrowsingData(storage){
                // Cleanup ownership is independent of the active selection and Flutter lifetime.
                try{
                    registry.advance(task.profileId,"websiteWiped")
                    registry.advance(task.profileId,"appDataCleanupPending")
                    val staging=File(context.cacheDir,"profiledesk-staging/${task.profileId}")
                    check(!staging.exists()||staging.deleteRecursively())
                    registry.cleanAppRecords(task.profileId)
                    registry.advance(task.profileId,"containerDeletionPending")
                    emit(EngineEvent(EngineEventKind.CLEANUP_CHANGED,profileId=task.profileId,cleanupOperationId=task.operation,cleanupStage="containerDeletionPending"));changed();deferred.complete(Unit)
                }catch(_:Exception){registry.advance(task.profileId,"appDataCleanupPending","appCleanupFailed");deferred.completeExceptionally(FlutterError("cleanupPending","Local cleanup remains pending."))}
                finally{wipes.remove(task.profileId)}
            }
        }catch(_:Exception){registry.advance(task.profileId,"websiteWipePending","wipeFailed");wipes.remove(task.profileId);deferred.completeExceptionally(FlutterError("cleanupPending","Website cleanup remains pending."))}
        return deferred
    }
    override suspend fun retryPendingCleanup()=guarded{checkInitialized();reconcile();registry.cleanup().forEach{startWipe(it)};changed()}
    override suspend fun resetProfilePermissions(profileId:String)=guarded{registry.resetPermissions(profileId)}
    fun onPause(){foreground=false;showCover();if(picker==null&&!setupDocuments.isActive&&!authInProgress){if(initialized&&preferences().lockEnabled){locked=true;lockEpoch++};cancelPicker()};web?.onPause();flushCookies(owner);if(locked)emit(EngineEvent(EngineEventKind.PRIVACY_CHANGED,locked=true))}
    fun onResume(){foreground=true;activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_SECURE);if(initialized&&!capabilities().supported){showCover();disposeCurrent()};web?.onResume();applyCover();emit(EngineEvent(EngineEventKind.PRIVACY_CHANGED,locked=locked))}
    fun onActivityDetached(){lockEpoch++;if(initialized&&preferences().lockEnabled)locked=true;authSignal?.cancel();cancelPicker();setupDocuments.cancel();showCover();disposeCurrent();host?.removeAllViews();host=null;cover=null;windowCover.hide();activity=null;foreground=false}
    override suspend fun lockApp()=guarded{checkInitialized();locked=true;lockEpoch++;authSignal?.cancel();showCover();cancelPicker();setupDocuments.cancel();emit(EngineEvent(EngineEventKind.PRIVACY_CHANGED,locked=true))}
    override suspend fun authenticate():Boolean {
        checkInitialized()
        if(authInProgress)throw FlutterError("authenticationBusy","Authentication is already in progress.")
        val current=activity?:throw FlutterError("activityUnavailable","Return to the application and retry.")
        if(!capabilities().authenticationAvailable)throw FlutterError("authenticationUnavailable","Set up a device screen lock in Android settings.")
        showCover();authInProgress=true
        val requestedLockEpoch=lockEpoch
        return suspendCancellableCoroutine { continuation ->
            val signal=CancellationSignal();authSignal=signal
            fun finish(success:Boolean){if(!continuation.isActive)return;authSignal=null;authInProgress=false;val accepted=success&&requestedLockEpoch==lockEpoch&&foreground&&activity===current;if(accepted){locked=false};applyCover();emit(EngineEvent(EngineEventKind.PRIVACY_CHANGED,locked=locked));continuation.resume(accepted)}
            val builder=BiometricPrompt.Builder(current).setTitle(context.getString(R.string.profiledesk_unlock_title)).setSubtitle(context.getString(R.string.profiledesk_unlock_subtitle))
            if(Build.VERSION.SDK_INT>=30)builder.setAllowedAuthenticators(android.hardware.biometrics.BiometricManager.Authenticators.BIOMETRIC_STRONG or android.hardware.biometrics.BiometricManager.Authenticators.DEVICE_CREDENTIAL)
            else {@Suppress("DEPRECATION") builder.setDeviceCredentialAllowed(true)}
            try{builder.build().authenticate(signal,current.mainExecutor,object:BiometricPrompt.AuthenticationCallback(){override fun onAuthenticationSucceeded(result:BiometricPrompt.AuthenticationResult){finish(true)};override fun onAuthenticationError(errorCode:Int,errString:CharSequence){finish(false)}})}catch(_:Exception){finish(false)}
            continuation.invokeOnCancellation{signal.cancel();authInProgress=false;authSignal=null}
        }
    }
    override suspend fun setPreferences(preferences:AppPreferences)=guarded{
        checkInitialized()
        if(preferences.lockEnabled&&!capabilities().authenticationAvailable)throw FlutterError("authenticationUnavailable","Set a device passcode before enabling app lock.")
        if(registry.pref("lockEnabled","false")=="true"&&!preferences.lockEnabled&&locked)throw FlutterError("locked","Unlock before disabling app lock.")
        require(preferences.theme in listOf("system","light","dark"))
        if(preferences.lockEnabled&&registry.pref("lockEnabled","false")!="true"&&!authenticate())throw FlutterError("authenticationCancelled","App lock was not enabled because device authentication did not finish.")
        registry.setPref("lockEnabled",preferences.lockEnabled.toString());registry.setPref("welcomeSeen",preferences.welcomeSeen.toString());registry.setPref("switchWarningSeen",preferences.switchWarningSeen.toString());registry.setPref("theme",preferences.theme)
    }
    override suspend fun openHelp(topic:HelpTopic)=guarded{openExternal(Uri.parse("https://faq.whatsapp.com/"))}
    private fun openExternal(uri:Uri){try{activity?.startActivity(Intent(Intent.ACTION_VIEW,uri).addCategory(Intent.CATEGORY_BROWSABLE))}catch(_:Exception){throw FlutterError("browserUnavailable","A system browser is unavailable.")}}
    override suspend fun exportDiagnostics()=guarded{
        checkInitialized();val c=capabilities()
        // Deliberately omit aliases, profile identifiers, URL, file information and page content.
        val report="Profile Desk Android diagnostics\nOS: ${c.osVersion}\nProvider: ${c.providerVersion}\nMULTI_PROFILE: ${c.multiProfile}\nDELETE_BROWSING_DATA: ${c.scopedDeletion}\nSaved slots: ${registry.rows().size}\nPending cleanup: ${registry.cleanup().size}\nUnknown stores quarantined: ${registry.pref("orphanCount","0")}\nCapture validated: false\nDownloads validated: false\n"
        val intent=Intent(Intent.ACTION_SEND).apply{type="text/plain";putExtra(Intent.EXTRA_TEXT,report)}
        (activity?:throw FlutterError("activityUnavailable","Return to the application.")).startActivity(Intent.createChooser(intent,context.getString(R.string.profiledesk_export_diagnostics)))
    }
}
