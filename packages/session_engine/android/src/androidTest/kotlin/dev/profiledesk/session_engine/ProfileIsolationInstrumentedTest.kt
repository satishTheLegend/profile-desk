package dev.profiledesk.session_engine

import android.content.Context
import android.content.Intent
import android.os.Debug
import android.util.Log
import java.util.Random
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.webkit.ProfileStore
import androidx.webkit.WebStorageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.json.JSONTokener
import org.junit.Assert.*
import org.junit.Test
import org.junit.Assume.assumeTrue
import org.junit.runner.RunWith
import java.net.URI
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/** Uses only a developer-owned HTTPS origin, and exists only in the test APK. */
@RunWith(AndroidJUnit4::class)
class ProfileIsolationInstrumentedTest {
    private val instrumentation=InstrumentationRegistry.getInstrumentation()
    private val context:Context get()=instrumentation.targetContext
    private fun <T> main(action:()->T):T {
        val value=AtomicReference<T>();val error=AtomicReference<Throwable>()
        instrumentation.runOnMainSync{try{value.set(action())}catch(t:Throwable){error.set(t)}}
        error.get()?.let{throw it};return value.get()
    }
    private fun await(latch:CountDownLatch){assertTrue("Native callback timed out",latch.await(30,TimeUnit.SECONDS))}
    private fun evaluate(view:WebView,script:String):String {
        val latch=CountDownLatch(1);val output=AtomicReference<String>()
        main{view.evaluateJavascript(script){output.set(it);latch.countDown()}};await(latch);return output.get()
    }
    private fun open(name:String,origin:String):WebView {
        val loaded=CountDownLatch(1)
        val view=main{
            val created=WebView(context)
            WebViewCompat.setProfile(created,name) // First operation, also in the test factory.
            created.settings.javaScriptEnabled=true;created.settings.domStorageEnabled=true
            created.webViewClient=object:WebViewClient(){override fun onPageFinished(view:WebView,url:String){loaded.countDown()}}
            created.loadUrl(origin);created
        }
        await(loaded);return view
    }
    private fun destroy(view:WebView)=main{view.stopLoading();view.destroy()}

    private fun harnessOrigin():String {
        val origin=InstrumentationRegistry.getArguments().getString("harnessOrigin")
            ?: throw AssertionError("Required: -e harnessOrigin https://YOUR-CONTROLLED-HOST:PORT/. No production origin is accepted.")
        val uri=URI(origin)
        require(uri.scheme=="https"&&uri.host!=null&&uri.rawUserInfo==null&&!uri.host.endsWith("whatsapp.com"))
        return origin
    }
    private fun awaitJavascript(view:WebView,expression:String):String {
        val deadline=System.nanoTime()+TimeUnit.SECONDS.toNanos(10)
        while(System.nanoTime()<deadline){
            val result=evaluate(view,expression)
            if(result!="null"&&result!="undefined")return result
            Thread.sleep(25)
        }
        throw AssertionError("Synthetic connectivity probe timed out")
    }
    private fun withConnectivityViews(action:(WebView,WebView,WebView)->Unit){
        val origin=harnessOrigin()
        assertTrue("Provider lacks MULTI_PROFILE",main{WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)})
        assertTrue("Provider lacks DELETE_BROWSING_DATA",main{WebViewFeature.isFeatureSupported(WebViewFeature.DELETE_BROWSING_DATA)})
        val names=listOf("profiledesk_channel_test_${UUID.randomUUID()}","profiledesk_channel_test_${UUID.randomUUID()}")
        val views=mutableListOf<WebView>()
        try {
            // Three simultaneous views are deliberate TEST-ONLY positive/negative controls.
            // The production process engine still owns exactly one live view.
            views.add(open(names[0],origin));views.add(open(names[0],origin));views.add(open(names[1],origin))
            action(views[0],views[1],views[2])
        }finally{
            views.forEach{destroy(it)}
            names.forEach{name->val wiped=CountDownLatch(1);main{ProfileStore.getInstance().getProfile(name)?.let{WebStorageCompat.deleteBrowsingData(it.webStorage){wiped.countDown()}}?:wiped.countDown()};await(wiped)}
        }
    }
    @Test fun broadcastChannelHasSameProfileControlAndCrossProfileIsolation(){
        withConnectivityViews{first,same,other->
            val channel="synthetic-${UUID.randomUUID()}"
            listOf(first,same,other).forEach{view->
                assertEquals("\"function\"",evaluate(view,"typeof BroadcastChannel"))
                evaluate(view,"window.__messages=[];window.__channel=new BroadcastChannel('$channel');window.__channel.onmessage=e=>window.__messages.push(e.data);void 0")
            }
            evaluate(first,"window.__channel.postMessage('synthetic-same');void 0")
            assertEquals("\"synthetic-same\"",awaitJavascript(same,"window.__messages[0]??null"))
            Thread.sleep(1000)
            assertEquals("0",evaluate(other,"window.__messages.length"))
            evaluate(other,"window.__channel.postMessage('synthetic-other');void 0")
            Thread.sleep(1000)
            assertEquals("0",evaluate(first,"window.__messages.length"))
            assertEquals("1",evaluate(same,"window.__messages.length"))
            listOf(first,same,other).forEach{evaluate(it,"window.__channel.close();void 0")}
            Log.i("ProfileDeskEvidence","broadcast_channel=same_profile_delivery_and_cross_profile_isolation_pass")
        }
    }
    @Test fun sharedWorkerHasSameProfileControlAndCrossProfileIsolationWhenSupported(){
        withConnectivityViews{first,same,other->
            val available=evaluate(first,"typeof SharedWorker")=="\"function\""
            if(!available)Log.i("ProfileDeskEvidence","shared_worker=unavailable_on_this_webview_provider;isolation_not_claimed")
            assumeTrue("SharedWorker is not exposed by this WebView provider; isolation cannot be established",available)
            val workerName="synthetic-${UUID.randomUUID()}"
            fun connect(view:WebView){
                evaluate(view,"window.__workerReplies={};window.__shared=new SharedWorker('/shared-worker.js','$workerName');window.__shared.port.onmessage=e=>window.__workerReplies[e.data.token]=e.data;window.__shared.port.start();void 0")
            }
            fun probe(view:WebView,token:String):JSONObject {
                evaluate(view,"window.__shared.port.postMessage({type:'probe',token:'$token'});void 0")
                return JSONObject(awaitJavascript(view,"window.__workerReplies['$token']??null"))
            }
            connect(first);assertEquals(1,probe(first,"synthetic-first").getInt("connections"))
            connect(same);assertEquals(2,probe(same,"synthetic-same").getInt("connections"))
            assertEquals(2,probe(first,"synthetic-control").getInt("connections"))
            connect(other);assertEquals(1,probe(other,"synthetic-other").getInt("connections"))
            assertEquals(2,probe(first,"synthetic-isolated").getInt("connections"))
            listOf(first,same,other).forEach{evaluate(it,"window.__shared.port.close();void 0")}
            Log.i("ProfileDeskEvidence","shared_worker=same_profile_connections_and_cross_profile_isolation_pass")
        }
    }
    @Test fun httpCacheWebSocketAndSyntheticFileBytesStayWithTheirProfiles(){
        val origin=harnessOrigin().trimEnd('/')+"/transport/page"
        val names=listOf("profiledesk_transport_test_${UUID.randomUUID()}","profiledesk_transport_test_${UUID.randomUUID()}")
        fun probe(view:WebView,expression:String):JSONObject {
            if(evaluate(view,"typeof ProfileDeskTransport")!="\"object\""){
                evaluate(view,"window.__transportLoaded=null;var s=document.createElement('script');s.src='/transport.js';s.onload=()=>window.__transportLoaded=true;s.onerror=()=>window.__transportLoaded=false;document.head.append(s);void 0")
                assertEquals("true",awaitJavascript(view,"window.__transportLoaded"))
            }
            assertEquals("\"object\"",evaluate(view,"typeof ProfileDeskTransport"))
            evaluate(view,"window.__transportResult=null;$expression.then(r=>window.__transportResult=r).catch(e=>window.__transportResult={result:'ERROR',error:String(e)});void 0")
            val result=JSONObject(awaitJavascript(view,"window.__transportResult"))
            assertEquals(result.toString(),"MATCH",result.getString("result"))
            return result
        }
        val hashes=mutableListOf<String>()
        try {
            names.forEachIndexed{index,name->
                val view=open(name,origin)
                try {
                    val emptyCache=probe(view,"ProfileDeskTransport.cacheProbe(null)")
                    assertFalse("Another profile's HTTP cache was reused",emptyCache.getBoolean("cacheHit"))
                    val marker="synthetic-transport-$index"
                    assertEquals("MATCH",fixture(view,marker,"seed").getString("result"))
                    assertFalse(probe(view,"ProfileDeskTransport.cacheProbe('$marker',{cache:'reload'})").getBoolean("cacheHit"))
                    assertTrue("Positive control must exercise an actual HTTP cache hit",probe(view,"ProfileDeskTransport.cacheProbe('$marker',{cache:'force-cache'})").getBoolean("cacheHit"))
                    probe(view,"ProfileDeskTransport.websocketProbe('$marker')")
                    val file=probe(view,"ProfileDeskTransport.fileProbe('$marker')")
                    assertTrue(file.getInt("bytes")>0);hashes.add(file.getString("sha256"))
                }finally{destroy(view)}
            }
            assertNotEquals("Distinct profile markers must produce distinct file bodies",hashes[0],hashes[1])
            val restored=open(names[0],origin)
            try {
                assertTrue(probe(restored,"ProfileDeskTransport.cacheProbe('synthetic-transport-0',{cache:'force-cache'})").getBoolean("cacheHit"))
                probe(restored,"ProfileDeskTransport.websocketProbe('synthetic-transport-0')")
                assertEquals(hashes[0],probe(restored,"ProfileDeskTransport.fileProbe('synthetic-transport-0')").getString("sha256"))
            }finally{destroy(restored)}
            Log.i("ProfileDeskEvidence","http_cache_wss_synthetic_file_fetch=two_profile_partition_and_reopen_pass")
        }finally{
            names.forEach{name->val wiped=CountDownLatch(1);main{ProfileStore.getInstance().getProfile(name)?.let{WebStorageCompat.deleteBrowsingData(it.webStorage){wiped.countDown()}}?:wiped.countDown()};await(wiped)}
        }
    }
    @Test fun sixStoresPersistAcrossSeparateProcessAndDeviceReboot(){
        val origin=harnessOrigin()
        val stage=InstrumentationRegistry.getArguments().getString("persistenceStage")?:"seed"
        require(stage in listOf("seed","verifyProcess","verifyReboot"))
        val saved=context.getSharedPreferences("synthetic-persistence-test",Context.MODE_PRIVATE)
        val engine=main{AndroidSessionEngine(context)}
        assertTrue(hostCall{engine.initialize()}.capabilities.supported)
        val ids=if(stage=="seed"){
            List(2){hostCall{engine.allocateProfile("Synthetic persistence $it",0)}.id}.also{values->
                assertTrue(saved.edit().putString("profile0",values[0]).putString("profile1",values[1]).commit())
            }
        }else List(2){requireNotNull(saved.getString("profile$it",null)){"Run persistence seed in an earlier process first"}}
        // A detached FrameLayout never enters WebView's foreground lifecycle. A real
        // test-only Activity exercises the same window attach/detach boundary as the app.
        val activity=instrumentation.startActivitySync(Intent(context,SyntheticHostActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) as SyntheticHostActivity
        val frame=main{activity.frame.also{assertTrue(engine.attachHost(it))}}
        try{ids.forEachIndexed{index,id->
            require(UUID.fromString(id).toString()==id)
            val owner=hostCall{engine.openProfile(id,"synthetic-persistence-$stage-$index",index.toLong()+1)}
            val view=main{(0 until frame.childCount).map{frame.getChildAt(it)}.filterIsInstance<WebView>().single()}
            // Only test code redirects the already profile-bound production view.
            main{view.stopLoading();view.loadUrl(origin)}
            try{
                assertEquals("\"function\"",awaitJavascript(view,"typeof verify==='function'?'function':null"))
                val report=fixture(view,"synthetic-persistence-$index",if(stage=="seed")"seed" else "verify")
                assertEquals(report.toString(),"MATCH",report.getString("result"))
            }finally{hostCall{engine.disposeView(owner)}}
        }}finally{main{engine.onPause();engine.detachHost(frame);activity.finish()};instrumentation.waitForIdleSync()}
        Log.i("ProfileDeskEvidence","six_store_two_profile_persistence_stage=$stage pass")
        if(stage=="verifyReboot"){
            ids.forEach{id->hostCall{engine.requestLocalRemoval(id,UUID.randomUUID().toString())}}
            saved.edit().clear().commit()
        }
    }

    private fun fixture(view:WebView, marker:String, action:String):JSONObject {
        require(marker.matches(Regex("synthetic-[a-zA-Z0-9_-]+")))
        require(action in listOf("seed","verify"))
        assertEquals("\"function\"",evaluate(view,"typeof verify"))
        evaluate(view,"window.__nativeResult=null;document.querySelector('#marker').value='$marker';$action().then(()=>verify()).then(r=>window.__nativeResult=JSON.stringify(r)).catch(e=>window.__nativeResult=JSON.stringify({result:'ERROR',error:String(e)}));")
        val deadline=System.nanoTime()+TimeUnit.SECONDS.toNanos(30)
        while(System.nanoTime()<deadline){
            val result=evaluate(view,"window.__nativeResult")
            if(result!="null"){val report=JSONObject(JSONTokener(result).nextValue() as String);if(report.optString("result")=="ERROR")throw AssertionError(report.toString());return report}
            Thread.sleep(50)
        }
        throw AssertionError("Fixture timed out")
    }
    private fun <T> hostCall(action:suspend ()->T):T {
        val output=AtomicReference<T>();val error=AtomicReference<Throwable>();val done=CountDownLatch(1)
        CoroutineScope(Dispatchers.Main).launch{try{output.set(action())}catch(t:Throwable){error.set(t)}finally{done.countDown()}}
        await(done);error.get()?.let{throw it};return output.get()
    }
    @Test fun nativeCleanupJournalAcrossProcessRestart(){
        val engine=main{AndroidSessionEngine(context)}
        val snapshot=hostCall{engine.initialize()}
        assertTrue("Supported provider required for lifecycle proof",snapshot.capabilities.supported)
        val fixture=context.getSharedPreferences("synthetic-journal-test",Context.MODE_PRIVATE)
        if(InstrumentationRegistry.getArguments().getString("lifecycleStage")=="verify"){
            val oldId=requireNotNull(fixture.getString("removedId",null)){"Run prepare stage in another process first"}
            val oldStore=requireNotNull(fixture.getString("removedStore",null))
            val survivor=requireNotNull(fixture.getString("survivorId",null))
            assertFalse(hostCall{engine.listProfiles()}.any{it.id==oldId})
            assertFalse(main{ProfileStore.getInstance().allProfileNames.contains(oldStore)})
            assertEquals(StoreState.AVAILABLE,hostCall{engine.listProfiles()}.first{it.id==survivor}.state)
            hostCall{engine.requestLocalRemoval(survivor,UUID.randomUUID().toString())}
            fixture.edit().clear().commit()
        }else{
            val first=hostCall{engine.allocateProfile("Synthetic journal A",0)}
            val second=hostCall{engine.allocateProfile("Synthetic journal B",0)}
            hostCall{engine.requestLocalRemoval(first.id,UUID.randomUUID().toString())}
            val removed=hostCall{engine.listProfiles()}.first{it.id==first.id}
            assertEquals(StoreState.CLEANUP_PENDING,removed.state)
            assertEquals("containerDeletionPending",removed.cleanupStage)
            hostCall{engine.requestLocalRemoval(first.id,UUID.randomUUID().toString())}
            val repeated=hostCall{engine.listProfiles()}.first{it.id==first.id}
            assertEquals("containerDeletionPending",repeated.cleanupStage)
            assertEquals(removed.cleanupOperationId,repeated.cleanupOperationId)
            try{hostCall{engine.openProfile(first.id,"blocked-open",1)};fail("Tombstone reopened")}
            catch(error:FlutterError){assertEquals("profileUnavailable",error.code)}
            assertEquals(StoreState.AVAILABLE,hostCall{engine.listProfiles()}.first{it.id==second.id}.state)
            fixture.edit().putString("removedId",first.id).putString("removedStore",first.platformProfileId).putString("survivorId",second.id).commit()
        }
    }
    @Test fun capabilityGateMatchesProviderAndRejectsUnsupportedAllocation(){
        main { runBlocking {
            val engine=AndroidSessionEngine(context)
            val snapshot=engine.initialize()
            val multi=WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE)
            val deletion=WebViewFeature.isFeatureSupported(WebViewFeature.DELETE_BROWSING_DATA)
            assertEquals(multi&&deletion,snapshot.capabilities.supported)
            engine.lockApp()
            assertTrue(engine.initialize().locked) // Includes devices with no enrolled credential.
            try{engine.setPrivacyCover(false,null);fail("Locked content was revealed")}
            catch(error:FlutterError){assertEquals("revealDenied",error.code)}
            if(!snapshot.capabilities.supported){
                val count=snapshot.profiles.size
                try{engine.allocateProfile("Synthetic gated account",0);fail("Unsupported provider allocated an account")}
                catch(error:FlutterError){assertEquals("unsupportedProvider",error.code)}
                assertEquals(count,engine.listProfiles().size)
                engine.retryPendingCleanup() // Management remains callable while unsupported.
            }
        } }
    }
    @Test fun rendererTerminationDisposesOwnedViewAndRetainsPersistentStore(){
        val origin=harnessOrigin()
        assumeTrue("Public renderer termination is unavailable",main{WebViewFeature.isFeatureSupported(WebViewFeature.WEB_VIEW_RENDERER_TERMINATE)})
        val events=mutableListOf<EngineEvent>()
        val engine=main{AndroidSessionEngine(context)}
        val snapshot=hostCall{engine.initialize()}
        assertTrue(snapshot.capabilities.supported)
        val profile=hostCall{engine.allocateProfile("Synthetic renderer recovery",0)}
        val seed=open(profile.platformProfileId,origin)
        try{assertEquals("MATCH",fixture(seed,"synthetic-renderer","seed").getString("result"))}finally{destroy(seed)}
        val frame=main{FrameLayout(context)}
        main{
            engine.eventSink=SessionFlutterApi(object:BinaryMessenger{
                override fun send(channel:String,message:ByteBuffer?)=send(channel,message,null)
                override fun send(channel:String,message:ByteBuffer?,callback:BinaryMessenger.BinaryReply?){
                    val read=message?.duplicate()?.apply{flip()}
                    val args=SessionFlutterApi.codec.decodeMessage(read) as List<*>
                    events.add(args[0] as EngineEvent)
                    callback?.reply(SessionFlutterApi.codec.encodeMessage(listOf(null))?.apply{flip()})
                }
                override fun setMessageHandler(channel:String,handler:BinaryMessenger.BinaryMessageHandler?){}
            })
            assertTrue(engine.attachHost(frame))
        }
        try {
            val owner=hostCall{engine.openProfile(profile.id,"synthetic-renderer-open",1)}
            val current=main{(0 until frame.childCount).map{frame.getChildAt(it)}.filterIsInstance<WebView>().single()}
            // Test code directs the already bound production view to the fixture.
            // No alternate URL, scripting or test hook is added to the production API.
            main{current.stopLoading();current.loadUrl(origin)}
            assertEquals("\"function\"",awaitJavascript(current,"typeof verify==='function'?'function':null"))
            assertTrue("The current renderer could not be terminated",main{current.webViewRenderProcess?.terminate()==true})
            val deadline=System.nanoTime()+TimeUnit.SECONDS.toNanos(15)
            while(System.nanoTime()<deadline&&!main{events.any{it.kind==EngineEventKind.VIEW_FAILED&&it.errorCode=="rendererGone"&&it.view==owner}})Thread.sleep(25)
            assertTrue(main{events.any{it.kind==EngineEventKind.VIEW_FAILED&&it.errorCode=="rendererGone"&&it.view==owner}})
            assertEquals(0,main{(0 until frame.childCount).count{frame.getChildAt(it) is WebView}})
            assertEquals(StoreState.AVAILABLE,hostCall{engine.listProfiles()}.first{it.id==profile.id}.state)
            val recovered=hostCall{engine.openProfile(profile.id,"synthetic-renderer-reopen",2)}
            assertNotEquals(owner.viewInstanceId,recovered.viewInstanceId)
            hostCall{engine.disposeView(recovered)}
            val retained=open(profile.platformProfileId,origin)
            try{assertEquals("MATCH",fixture(retained,"synthetic-renderer","verify").getString("result"))}finally{destroy(retained)}
            Log.i("ProfileDeskEvidence","renderer_termination=owned_failure_view_disposed_reopen_and_six_store_retention_pass")
        }finally{
            main{engine.detachHost(frame)}
            hostCall{engine.requestLocalRemoval(profile.id,UUID.randomUUID().toString())}
        }
    }
    @Test fun tenProfilesRetainSeparateSameOriginMarkersAndMiddleWipe(){
        val origin=harnessOrigin()
        main{
            assertTrue("Provider lacks MULTI_PROFILE",WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE))
            assertTrue("Provider lacks DELETE_BROWSING_DATA",WebViewFeature.isFeatureSupported(WebViewFeature.DELETE_BROWSING_DATA))
            val stores=ProfileStore.getInstance()
            stores.allProfileNames.filter{it.startsWith("profiledesk_test_")}.forEach{stores.deleteProfile(it)}
        }
        val names=(0..9).map{"profiledesk_test_${UUID.randomUUID()}"}.toMutableList()
        var primaryFailure:Throwable?=null
        try {
            names.forEachIndexed{index,name->
                val view=open(name,origin)
                try {
                    assertEquals("EMPTY",fixture(view,"synthetic-$index","verify").getString("result"))
                    assertEquals("MATCH",fixture(view,"synthetic-$index","seed").getString("result"))
                    assertFalse(evaluate(view,"document.cookie").contains("harness_http_only="))
                }finally{destroy(view)}
            }
            names.forEachIndexed{index,name->val view=open(name,origin);try{assertEquals("MATCH",fixture(view,"synthetic-$index","verify").getString("result"))}finally{destroy(view)}}
            val switches=InstrumentationRegistry.getArguments().getString("switches")?.toInt()?:0
            require(switches in 0..200)
            if(switches>0){
                val random=Random(20261018)
                val samples=mutableListOf<Long>()
                val baselinePss=Debug.getPss()
                repeat(switches){
                    val index=random.nextInt(10)
                    val started=System.nanoTime()
                    val switched=open(names[index],origin)
                    try{assertEquals("MATCH",fixture(switched,"synthetic-$index","verify").getString("result"))}finally{destroy(switched)}
                    samples.add(TimeUnit.NANOSECONDS.toMillis(System.nanoTime()-started))
                    if((it+1)%20==0)Log.i("ProfileDeskEvidence","synthetic_switch_progress=${it+1}/$switches")
                }
                val sorted=samples.sorted();val p95=sorted[((sorted.size*95+99)/100)-1]
                Log.i("ProfileDeskEvidence","synthetic_switches=$switches p95_navigation_and_six_store_verification_ms=$p95 first_pss_kb=$baselinePss final_pss_kb=${Debug.getPss()}")
            }
            val activeWorker=open(names[4],origin)
            assertEquals("MATCH",fixture(activeWorker,"synthetic-4","verify").getString("result"))
            evaluate(activeWorker,"workerMessage('burst','synthetic-4').catch(()=>{});void 0")
            Thread.sleep(300) // Let the bounded event.waitUntil write burst start before disposal.
            main{ProfileStore.getInstance().getProfile(names[4])!!.serviceWorkerController.serviceWorkerWebSettings.blockNetworkLoads=true}
            destroy(activeWorker)
            val wiped=CountDownLatch(1)
            main{WebStorageCompat.deleteBrowsingData(ProfileStore.getInstance().getProfile(names[4])!!.webStorage){wiped.countDown()}}
            await(wiped)
            Thread.sleep(4300) // Observe beyond the fixture's complete 4-second worker write lifetime.
            main{ProfileStore.getInstance().getProfile(names[4])!!.serviceWorkerController.serviceWorkerWebSettings.blockNetworkLoads=false}
            // Controlled destructive verification, excluded from the production API.
            val removed=open(names[4],origin);try{assertEquals("EMPTY",fixture(removed,"synthetic-4","verify").getString("result"))}finally{destroy(removed)}
            listOf(3,5).forEach{index->val adjacent=open(names[index],origin);try{assertEquals("MATCH",fixture(adjacent,"synthetic-$index","verify").getString("result"))}finally{destroy(adjacent)}}
            main{assertThrows(IllegalStateException::class.java){ProfileStore.getInstance().deleteProfile(names[4])}}
            val replacement="profiledesk_test_${UUID.randomUUID()}";names.add(replacement)
            val fresh=open(replacement,origin);try{assertEquals("EMPTY",fixture(fresh,"synthetic-new","verify").getString("result"));assertEquals("MATCH",fixture(fresh,"synthetic-new","seed").getString("result"))}finally{destroy(fresh)}
        } catch(error:Throwable){
            primaryFailure=error
            Log.e("ProfileDeskEvidence","synthetic_storage_primary_failure",error)
            throw error
        } finally {
            try{
                names.forEach{name->val wiped=CountDownLatch(1);main{ProfileStore.getInstance().getProfile(name)?.let{WebStorageCompat.deleteBrowsingData(it.webStorage){wiped.countDown()}}?:wiped.countDown()};await(wiped)}
            }catch(cleanupError:Throwable){
                if(primaryFailure!=null){primaryFailure.addSuppressed(cleanupError);Log.e("ProfileDeskEvidence","synthetic_storage_cleanup_failure",cleanupError)}else throw cleanupError
            }
            // Container removal intentionally happens on the NEXT clean instrumentation process.
        }
    }
}
