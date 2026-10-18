package dev.profiledesk.session_engine

import android.app.Activity
import android.annotation.SuppressLint
import android.app.Application
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** Registers a persistent native host; no WebView is constructed during registration. */
class SessionEnginePlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener,
    Application.ActivityLifecycleCallbacks {
    companion object {
        // The runtime stores applicationContext; attached Activity/host references are
        // explicitly released by onActivityDetached on both activity/engine detach.
        @SuppressLint("StaticFieldLeak")
        private var processEngine:AndroidSessionEngine?=null
    }
    private lateinit var engine:AndroidSessionEngine
    private var attachment:AttachedSessionHostApi?=null
    private var flutterBinding:FlutterPlugin.FlutterPluginBinding?=null
    private var activityBinding:ActivityPluginBinding?=null
    private var application:Application?=null
    override fun onAttachedToEngine(binding:FlutterPlugin.FlutterPluginBinding){
        engine=processEngine?:AndroidSessionEngine(binding.applicationContext).also{processEngine=it}
        val current=engine.attachFlutterHost()
        attachment=current;flutterBinding=binding
        engine.eventSink=SessionFlutterApi(binding.binaryMessenger)
        SessionHostApi.setUp(binding.binaryMessenger,current)
        binding.platformViewRegistry.registerViewFactory("profile_desk/session",object:PlatformViewFactory(StandardMessageCodec.INSTANCE){
            override fun create(context:Context,viewId:Int,args:Any?):PlatformView {
                val frame=FrameLayout(context)
                if(!current.isAttached||!engine.attachHost(frame))frame.addView(TextView(context).apply{setText(R.string.profiledesk_workspace_already_open)})
                return object:PlatformView{override fun getView():View=frame;override fun dispose(){if(current.isAttached)engine.detachHost(frame)}}
            }
        })
    }
    override fun onDetachedFromEngine(binding:FlutterPlugin.FlutterPluginBinding){
        SessionHostApi.setUp(binding.binaryMessenger,null)
        if(flutterBinding!==binding)return
        attachment?.let{if(engine.detachFlutterHost(it))engine.eventSink=null}
        detach();attachment=null;flutterBinding=null
    }
    override fun onAttachedToActivity(binding:ActivityPluginBinding){
        if(attachment?.isAttached!=true)return
        activityBinding=binding;engine.activity=binding.activity;binding.addActivityResultListener(this)
        application=binding.activity.application.also{it.registerActivityLifecycleCallbacks(this)}
        engine.onResume()
    }
    override fun onDetachedFromActivityForConfigChanges()=detach()
    override fun onReattachedToActivityForConfigChanges(binding:ActivityPluginBinding)=onAttachedToActivity(binding)
    override fun onDetachedFromActivity()=detach()
    private fun detach(){activityBinding?.removeActivityResultListener(this);activityBinding=null;application?.unregisterActivityLifecycleCallbacks(this);application=null;if(attachment?.isAttached==true)engine.onActivityDetached()}
    override fun onActivityResult(requestCode:Int,resultCode:Int,data:Intent?):Boolean=if(attachment?.isAttached==true)engine.onActivityResult(requestCode,resultCode,data)else false
    override fun onActivityPrePaused(activity:Activity){if(attachment?.isAttached==true&&activity===engine.activity)engine.onPause()}
    override fun onActivityPaused(activity:Activity){}
    override fun onActivityResumed(activity:Activity){if(attachment?.isAttached==true&&activity===engine.activity)engine.onResume()}
    override fun onActivityCreated(activity:Activity,state:Bundle?){}
    override fun onActivityStarted(activity:Activity){}
    override fun onActivityStopped(activity:Activity){}
    override fun onActivitySaveInstanceState(activity:Activity,state:Bundle){}
    override fun onActivityDestroyed(activity:Activity){}
}
