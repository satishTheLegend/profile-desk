package dev.profiledesk.session_engine

import android.app.Activity
import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import java.io.File
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class DiagnosticsPrivacyTest {
    @Test fun actualSharePayloadContainsTechnicalCountsButNoPrivateMarkers(){
        val context=ApplicationProvider.getApplicationContext<Context>()
        context.deleteDatabase("profiledesk_registry.db")
        val activity=Robolectric.buildActivity(Activity::class.java).setup()
        val registry=NativeRegistry(context)
        val engine=AndroidSessionEngine(context).also{it.activity=activity.get()}
        val alias="synthetic-secret-alias-7bb03f"
        val token="synthetic-secret-token-70ad52"
        val filename="synthetic-private-document.pdf"
        var staged:File?=null
        try {
            runBlocking{engine.initialize()}
            val row=registry.reserve(alias,0)
            registry.recordTransfer("synthetic-transfer",row.id,token,"synthetic-operation")
            staged=File(context.cacheDir,"profiledesk-staging/${row.id}/$filename").also{it.parentFile!!.mkdirs();it.writeText(token)}
            runBlocking{engine.exportDiagnostics()}
            val chooser=shadowOf(activity.get()).nextStartedActivity
            assertEquals(Intent.ACTION_CHOOSER,chooser.action)
            @Suppress("DEPRECATION")
            val share=chooser.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)!!
            assertEquals(Intent.ACTION_SEND,share.action)
            assertEquals("text/plain",share.type)
            val report=share.getStringExtra(Intent.EXTRA_TEXT)!!
            listOf("Profile Desk Android diagnostics","OS:","Provider:","MULTI_PROFILE:","DELETE_BROWSING_DATA:","Saved slots: 1","Pending cleanup:").forEach{assertTrue(it,report.contains(it))}
            listOf(alias,token,filename,staged.absolutePath,row.id,row.platformId,"synthetic-transfer","synthetic-operation").forEach{assertFalse("Private marker escaped into diagnostics",report.contains(it))}
        }finally{
            staged?.parentFile?.deleteRecursively()
            registry.close();context.deleteDatabase("profiledesk_registry.db")
            activity.pause().stop().destroy()
        }
    }
}
