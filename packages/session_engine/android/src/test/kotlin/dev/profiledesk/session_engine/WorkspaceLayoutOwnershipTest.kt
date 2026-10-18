package dev.profiledesk.session_engine

import android.content.Context
import android.webkit.ValueCallback
import android.webkit.WebView
import android.widget.FrameLayout
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class WorkspaceLayoutOwnershipTest {
    private class RecordingWebView(context:Context):WebView(context){
        val scripts=mutableListOf<String>()
        var presentationReply:String?="\"list\""
        var deferPresentation=false
        var pendingPresentation:ValueCallback<String>?=null
        override fun evaluateJavascript(script:String,callback:ValueCallback<String>?){
            scripts.add(script)
            if(script==WorkspaceLayoutCommands.presentation){
                if(deferPresentation)pendingPresentation=callback else callback?.onReceiveValue(presentationReply)
            }else callback?.onReceiveValue("null")
        }
    }
    private lateinit var context:Context
    private lateinit var engine:AndroidSessionEngine
    private lateinit var registry:NativeRegistry
    private lateinit var view:RecordingWebView
    private lateinit var owner:ViewHandle
    private lateinit var host:FrameLayout
    private fun field(name:String)=AndroidSessionEngine::class.java.getDeclaredField(name).apply{isAccessible=true}
    @Before fun setup(){
        context=ApplicationProvider.getApplicationContext();context.deleteDatabase("profiledesk_registry.db")
        engine=AndroidSessionEngine(context);registry=field("registry").get(engine) as NativeRegistry
        val row=registry.reserve("Owned",0);registry.state(row.id,"available");owner=ViewHandle(row.id,"owned-view","owned-operation",1)
        host=FrameLayout(context);engine.attachHost(host);view=RecordingWebView(context);host.addView(view,0)
        view.loadUrl(NavigationPolicy.WORKSPACE);field("web").set(engine,view);field("owner").set(engine,owner)
        field("initialized").setBoolean(engine,true);field("locked").setBoolean(engine,false);field("ready").setBoolean(engine,true)
    }
    @After fun cleanup(){
        field("owner").set(engine,null);engine.onActivityDetached();registry.close();context.deleteDatabase("profiledesk_registry.db")
    }
    @Test fun currentTrustedAttachedViewAcceptsOnlyTypedCommands()=runBlocking {
        engine.setWorkspaceLayout(owner,WorkspaceLayout.ORIGINAL)
        assertEquals(WorkspaceLayout.ORIGINAL,field("workspaceLayout").get(engine))
        assertEquals(2,view.scripts.size);assertTrue(view.scripts.last().contains("setMode('original')"))
        engine.showWorkspaceList(owner);assertTrue(view.scripts.last().contains("showList()"))
        assertEquals(WorkspaceLayout.PHONE,field("workspaceLayout").get(engine))
        assertTrue(view.scripts[view.scripts.lastIndex-1].contains("setMode('phone')"))
        val previous=view.scripts.size;engine.showWorkspaceList(owner)
        assertEquals(previous+1,view.scripts.size) // Already-phone back preserves adapter ownership.
    }
    @Test fun staleHandleCannotChangeNewerViewsMode()=runBlocking {
        val stale=owner.copy(viewInstanceId="stale-view")
        val error=try{engine.setWorkspaceLayout(stale,WorkspaceLayout.ORIGINAL);null}catch(error:FlutterError){error}
        assertEquals("staleView",error!!.code);assertTrue(view.scripts.isEmpty());assertEquals(WorkspaceLayout.PHONE,field("workspaceLayout").get(engine))
    }
    @Test fun repeatedModeCommandsKeepTheInstalledAdapterAndListReturnDismissesFocus()=runBlocking {
        engine.setWorkspaceLayout(owner,WorkspaceLayout.PHONE)
        val installed=view.scripts.size
        engine.setWorkspaceLayout(owner,WorkspaceLayout.PHONE)
        assertEquals(installed+1,view.scripts.size)
        assertTrue(view.scripts.last().contains("setMode('phone')"))
        view.isFocusableInTouchMode=true;view.requestFocus()
        engine.showWorkspaceList(owner)
        assertFalse(view.hasFocus())
        assertTrue(view.scripts.last().contains("showList()"))
        assertEquals(1,view.scripts.count{it.contains("const rootClass = 'profile-desk-phone-layout'")})
    }
    @Test fun lockBackgroundUntrustedNavigationAndDetachedHostRejectCommands()=runBlocking {
        field("locked").setBoolean(engine,true)
        assertEquals("locked",failureCode());field("locked").setBoolean(engine,false)
        field("foreground").setBoolean(engine,false);assertEquals("locked",failureCode());field("foreground").setBoolean(engine,true)
        view.loadUrl("https://example.com/");assertEquals("navigationBusy",failureCode())
        view.loadUrl(NavigationPolicy.WORKSPACE);host.removeView(view);assertEquals("staleView",failureCode())
        assertTrue(view.scripts.isEmpty())
    }
    @Test fun presentationReturnsOnlyExactAllowlistedJsonStrings()=runBlocking {
        val expected=mapOf("\"original\"" to WorkspacePresentation.ORIGINAL,"\"list\"" to WorkspacePresentation.LIST,
            "\"menu\"" to WorkspacePresentation.MENU,"\"detail\"" to WorkspacePresentation.DETAIL,
            "\"unavailable\"" to WorkspacePresentation.UNAVAILABLE)
        for((reply,value) in expected){view.presentationReply=reply;assertEquals(value,engine.getWorkspacePresentation(owner))}
        for(reply in listOf(null,"null","detail","\"DETAIL\""," \"list\"","{\"state\":\"detail\"}","[\"list\"]","\"list\\n\"")){
            view.presentationReply=reply;assertEquals(WorkspacePresentation.UNAVAILABLE,engine.getWorkspacePresentation(owner))
        }
        assertTrue(view.scripts.all{it==WorkspaceLayoutCommands.presentation})
        assertFalse(WorkspaceLayoutCommands.presentation.contains("textContent"))
        assertFalse(WorkspaceLayoutCommands.presentation.contains("innerHTML"))
    }
    @Test fun presentationRejectsStaleLockedBackgroundUntrustedAndDetachedBeforeEvaluation()=runBlocking {
        assertEquals("staleView",presentationFailure(owner.copy(operationId="old-operation")))
        field("locked").setBoolean(engine,true);assertEquals("locked",presentationFailure());field("locked").setBoolean(engine,false)
        field("foreground").setBoolean(engine,false);assertEquals("locked",presentationFailure());field("foreground").setBoolean(engine,true)
        field("ready").setBoolean(engine,false);assertEquals("navigationBusy",presentationFailure());field("ready").setBoolean(engine,true)
        view.loadUrl("https://example.com/");assertEquals("navigationBusy",presentationFailure())
        view.loadUrl(NavigationPolicy.WORKSPACE);host.removeView(view);assertEquals("staleView",presentationFailure())
        assertTrue(view.scripts.isEmpty())
    }
    @Test fun presentationDiscardsReplyAfterViewOwnershipChanges()=runBlocking {
        view.deferPresentation=true
        val pending=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        assertNotNull(view.pendingPresentation)
        field("owner").set(engine,owner.copy(viewInstanceId="replacement"))
        view.pendingPresentation!!.onReceiveValue("\"detail\"")
        assertEquals("staleView",pending.await())
    }
    @Test fun presentationDiscardsReplyAfterLockOrNavigationChanges()=runBlocking {
        view.deferPresentation=true
        val lockedReply=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        field("locked").setBoolean(engine,true);view.pendingPresentation!!.onReceiveValue("\"detail\"")
        assertEquals("locked",lockedReply.await());field("locked").setBoolean(engine,false)
        val navigationReply=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        view.loadUrl("https://example.com/");view.pendingPresentation!!.onReceiveValue("\"list\"")
        assertEquals("navigationBusy",navigationReply.await())
    }
    @Test fun presentationDiscardsReplyAfterModeRevisionOrAttachmentChanges()=runBlocking {
        view.deferPresentation=true
        val modeReply=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        val callback=view.pendingPresentation!!
        engine.setWorkspaceLayout(owner,WorkspaceLayout.ORIGINAL);callback.onReceiveValue("\"detail\"")
        assertEquals("staleView",modeReply.await())
        val attachmentReply=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        field("flutterAttachmentEpoch").setLong(engine,field("flutterAttachmentEpoch").getLong(engine)+1)
        view.pendingPresentation!!.onReceiveValue("\"list\"")
        assertEquals("staleView",attachmentReply.await())
    }
    @Test fun presentationCannotRegainOwnershipAfterBackgroundRoundTripWithoutAppLock()=runBlocking {
        view.deferPresentation=true
        val pending=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        val callback=view.pendingPresentation!!
        val lockEpoch=field("lockEpoch").getLong(engine)
        engine.onPause()
        // Provider capability behavior is covered separately; this fixture keeps
        // the same owned WebView while invoking both real lifecycle entrypoints.
        field("initialized").setBoolean(engine,false);engine.onResume();field("initialized").setBoolean(engine,true)
        assertFalse(field("locked").getBoolean(engine));assertTrue(field("foreground").getBoolean(engine))
        assertEquals(lockEpoch,field("lockEpoch").getLong(engine));assertSame(view,field("web").get(engine))
        callback.onReceiveValue("\"list\"")
        assertEquals("staleView",pending.await())
        view.deferPresentation=false
        assertEquals(WorkspacePresentation.LIST,engine.getWorkspacePresentation(owner))
    }
    @Test fun presentationCannotRegainOwnershipAfterLockUnlockRoundTrip()=runBlocking {
        view.deferPresentation=true
        val pending=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        val callback=view.pendingPresentation!!
        engine.lockApp()
        // Only the success state is simulated; no actual device authentication.
        field("locked").setBoolean(engine,false)
        callback.onReceiveValue("\"detail\"")
        assertEquals("staleView",pending.await())
    }
    @Test fun presentationCannotRegainOwnershipAfterNavigationReturnsToTrustedOrigin()=runBlocking {
        view.deferPresentation=true
        val pending=async(start=CoroutineStart.UNDISPATCHED){presentationFailure()}
        val callback=view.pendingPresentation!!
        AndroidSessionEngine::class.java.getDeclaredMethod("configure",WebView::class.java,ViewHandle::class.java)
            .apply{isAccessible=true}.invoke(engine,view,owner)
        view.webViewClient.onPageStarted(view,"https://example.com/",null)
        view.loadUrl(NavigationPolicy.WORKSPACE);field("ready").setBoolean(engine,true)
        callback.onReceiveValue("\"list\"")
        assertEquals("staleView",pending.await())
    }
    @Test fun presentationTimeoutReturnsUnavailableAndIgnoresLateCallback()=runBlocking {
        view.deferPresentation=true
        val result=engine.getWorkspacePresentation(owner)
        assertEquals(WorkspacePresentation.UNAVAILABLE,result)
        val calls=view.scripts.size
        view.pendingPresentation!!.onReceiveValue("\"detail\"")
        view.pendingPresentation!!.onReceiveValue("\"list\"")
        assertEquals(WorkspacePresentation.UNAVAILABLE,result)
        assertEquals(calls,view.scripts.size)
    }
    private suspend fun presentationFailure(handle:ViewHandle=owner):String?=try{engine.getWorkspacePresentation(handle);null}catch(error:FlutterError){error.code}
    private suspend fun failureCode():String?=try{engine.showWorkspaceList(owner);null}catch(error:FlutterError){error.code}
}
