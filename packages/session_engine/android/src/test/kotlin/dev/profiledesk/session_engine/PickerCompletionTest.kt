package dev.profiledesk.session_engine

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class PickerCompletionTest {
    class MissingPickerActivity:Activity(){
        override fun startActivityForResult(intent:Intent,requestCode:Int,options:Bundle?){throw IllegalStateException("No picker installed")}
        override fun startActivityForResult(intent:Intent,requestCode:Int){throw IllegalStateException("No picker installed")}
    }
    private fun field(name:String)=AndroidSessionEngine::class.java.getDeclaredField(name).apply{isAccessible=true}
    @Test fun missingPickerAndThrowingCallbackStillFinishTheOwnedTransfer(){
        val context=ApplicationProvider.getApplicationContext<Context>()
        context.deleteDatabase("profiledesk_registry.db")
        val registry=NativeRegistry(context)
        val activity=Robolectric.buildActivity(MissingPickerActivity::class.java).setup()
        val engine=AndroidSessionEngine(context).also{it.activity=activity.get()}
        val view=WebView(activity.get())
        try {
            val row=registry.reserve("Picker owner",0);registry.state(row.id,"available")
            val owner=ViewHandle(row.id,"picker-view","picker-operation",1)
            field("owner").set(engine,owner);field("locked").setBoolean(engine,false)
            AndroidSessionEngine::class.java.getDeclaredMethod("configure",WebView::class.java,ViewHandle::class.java).apply{isAccessible=true}.invoke(engine,view,owner)
            view.loadUrl(NavigationPolicy.WORKSPACE)
            var completions=0
            val callback=ValueCallback<Array<Uri>>{uris->completions++;assertNull(uris);throw IllegalStateException("Renderer callback ended")}
            val parameters=object:WebChromeClient.FileChooserParams(){
                override fun getMode()=MODE_OPEN
                override fun getAcceptTypes()=arrayOf("image/*")
                override fun isCaptureEnabled()=false
                override fun getTitle():CharSequence?=null
                override fun getFilenameHint():String?=null
                override fun createIntent()=Intent(Intent.ACTION_OPEN_DOCUMENT)
            }
            assertTrue(view.webChromeClient!!.onShowFileChooser(view,callback,parameters))
            assertEquals(1,completions)
            assertNull(field("picker").get(engine))
            registry.readableDatabase.rawQuery("SELECT COUNT(*) FROM transfers",null).use{it.moveToFirst();assertEquals(0,it.getInt(0))}
        }finally{
            view.destroy();registry.close();context.deleteDatabase("profiledesk_registry.db")
            activity.pause().stop().destroy()
        }
    }
}
