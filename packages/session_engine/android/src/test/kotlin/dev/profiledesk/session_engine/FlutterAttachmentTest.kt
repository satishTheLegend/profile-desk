package dev.profiledesk.session_engine

import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.platform.PlatformViewRegistry
import java.nio.ByteBuffer
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class FlutterAttachmentTest {
    private lateinit var context:Context
    private lateinit var registry:NativeRegistry
    @Before fun setup(){
        context=ApplicationProvider.getApplicationContext()
        context.deleteDatabase("profiledesk_registry.db")
        registry=NativeRegistry(context)
        field(SessionEnginePlugin::class.java,"processEngine").set(null,null)
    }
    @After fun close(){
        field(SessionEnginePlugin::class.java,"processEngine").set(null,null)
        registry.close();context.deleteDatabase("profiledesk_registry.db")
    }
    private fun field(type:Class<*>,name:String)=type.getDeclaredField(name).apply{isAccessible=true}
    private fun engine(plugin:SessionEnginePlugin)=field(SessionEnginePlugin::class.java,"engine").get(plugin) as AndroidSessionEngine
    // This plugin uses only context, messenger and platform-view registration.
    // Reflection avoids constructing a real FlutterEngine/native renderer in a JVM test.
    private fun binding(messenger:Messenger)=FlutterPlugin.FlutterPluginBinding::class.java.constructors.single().newInstance(context,null,messenger,null,PlatformViewRegistry{_,_->true},null,null) as FlutterPlugin.FlutterPluginBinding
    private class Messenger:BinaryMessenger {
        val handlers=mutableMapOf<String,BinaryMessenger.BinaryMessageHandler>()
        override fun send(channel:String,message:ByteBuffer?){}
        override fun send(channel:String,message:ByteBuffer?,callback:BinaryMessenger.BinaryReply?){callback?.reply(null)}
        override fun setMessageHandler(channel:String,handler:BinaryMessenger.BinaryMessageHandler?){if(handler==null)handlers.remove(channel)else handlers[channel]=handler}
    }
    @Test fun replacementFlutterEngineStartsFreshOrderingWithoutRetainingOldOwner(){
        val first=SessionEnginePlugin();val firstBinding=binding(Messenger());first.onAttachedToEngine(firstBinding)
        val runtime=engine(first)
        val generation=field(AndroidSessionEngine::class.java,"latestGeneration")
        val owner=field(AndroidSessionEngine::class.java,"owner")
        generation.setLong(runtime,42)
        owner.set(runtime,ViewHandle("prior-profile","prior-view","prior-operation",42))
        // Rotation may retain the same Dart coordinator, so it preserves ordering.
        runtime.onActivityDetached()
        assertEquals(42,generation.getLong(runtime))
        first.onDetachedFromEngine(firstBinding)
        val second=SessionEnginePlugin();val secondBinding=binding(Messenger());second.onAttachedToEngine(secondBinding)
        assertSame(runtime,engine(second))
        assertNull(owner.get(runtime))
        assertEquals("A replacement Dart coordinator starts its selection counter at zero",Long.MIN_VALUE,generation.getLong(runtime))
        second.onDetachedFromEngine(secondBinding)
    }
    @Test fun queuedOldAttachmentMutationCannotChangeTheReplacementRegistry(){
        val first=SessionEnginePlugin();val messenger=Messenger();val firstBinding=binding(messenger);first.onAttachedToEngine(firstBinding)
        val runtime=engine(first)
        field(AndroidSessionEngine::class.java,"initialized").setBoolean(runtime,true)
        val row=registry.reserve("Original",0)
        val oldHandler=messenger.handlers.getValue("dev.flutter.pigeon.session_contract.SessionHostApi.renameProfile")
        first.onDetachedFromEngine(firstBinding)
        val second=SessionEnginePlugin();val secondBinding=binding(Messenger());second.onAttachedToEngine(secondBinding)
        var reply:Any?=null
        // Models a Pigeon callback already captured before handler unregistration.
        val message=SessionHostApi.codec.encodeMessage(listOf(row.id,"Stale rename",0L))!!.apply{flip()}
        oldHandler.onMessage(message){value->value?.flip();reply=SessionHostApi.codec.decodeMessage(value)}
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals("Original",registry.get(row.id)!!.alias)
        assertEquals("staleAttachment",(reply as List<*>).first())
        second.onDetachedFromEngine(secondBinding)
    }
    @Test fun lateOldPluginDetachAndLifecycleCallbacksCannotDetachReplacement(){
        val first=SessionEnginePlugin();val firstBinding=binding(Messenger());first.onAttachedToEngine(firstBinding)
        val runtime=engine(first)
        // A replacement arrives before the old plugin's delayed detach notification.
        val second=SessionEnginePlugin();val secondBinding=binding(Messenger());second.onAttachedToEngine(secondBinding)
        val current=field(SessionEnginePlugin::class.java,"attachment").get(second) as AttachedSessionHostApi
        val eventSink=runtime.eventSink
        val owner=ViewHandle("new-profile","new-view","new-operation",1)
        field(AndroidSessionEngine::class.java,"owner").set(runtime,owner)
        first.onDetachedFromActivity()
        first.onDetachedFromEngine(firstBinding)
        assertTrue(current.isAttached)
        assertSame(eventSink,runtime.eventSink)
        assertSame(owner,field(AndroidSessionEngine::class.java,"owner").get(runtime))
        runBlocking{current.queryCapabilities()}
        second.onDetachedFromEngine(secondBinding)
        assertFalse(current.isAttached)
    }
}
