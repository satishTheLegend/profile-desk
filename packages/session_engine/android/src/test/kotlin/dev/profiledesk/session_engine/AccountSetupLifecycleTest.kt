package dev.profiledesk.session_engine

import android.app.Activity
import android.content.Context
import android.content.ContentProvider
import android.content.ContentValues
import android.content.pm.ProviderInfo
import android.database.Cursor
import android.net.Uri
import android.os.Looper
import android.os.ParcelFileDescriptor
import java.io.File
import org.robolectric.shadows.ShadowContentResolver
import android.content.Intent
import android.os.Bundle
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ActivityController
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class AccountSetupLifecycleTest {
    class MissingActivity:Activity(){
        override fun startActivityForResult(intent:Intent,requestCode:Int,options:Bundle?){error("Provider path must not escape")}
        override fun startActivityForResult(intent:Intent,requestCode:Int){error("Provider path must not escape")}
    }
    class FixtureDocumentProvider:ContentProvider(){
        lateinit var file:File
        override fun onCreate()=true
        override fun openFile(uri:Uri,mode:String):ParcelFileDescriptor=ParcelFileDescriptor.open(file,ParcelFileDescriptor.parseMode(mode))
        override fun getType(uri:Uri)="application/json"
        override fun query(uri:Uri,projection:Array<out String>?,selection:String?,selectionArgs:Array<out String>?,sortOrder:String?):Cursor?=null
        override fun insert(uri:Uri,values:ContentValues?):Uri?=null
        override fun delete(uri:Uri,selection:String?,selectionArgs:Array<out String>?)=0
        override fun update(uri:Uri,values:ContentValues?,selection:String?,selectionArgs:Array<out String>?)=0
    }
    private lateinit var context:Context
    private lateinit var engine:AndroidSessionEngine
    private lateinit var activity:ActivityController<Activity>
    private fun field(name:String)=AndroidSessionEngine::class.java.getDeclaredField(name).apply{isAccessible=true}
    @Before fun setup(){
        context=ApplicationProvider.getApplicationContext();context.deleteDatabase("profiledesk_registry.db")
        activity=Robolectric.buildActivity(Activity::class.java).setup();engine=AndroidSessionEngine(context)
        engine.activity=activity.get();field("initialized").setBoolean(engine,true);field("locked").setBoolean(engine,false)
    }
    @After fun cleanup(){
        engine.onActivityDetached();(field("registry").get(engine) as NativeRegistry).close()
        activity.pause().stop().destroy();context.deleteDatabase("profiledesk_registry.db")
    }
    @Test fun systemCancelReturnsNoArchiveAndUnrelatedActivityResultCannotFinishRequest()=runBlocking {
        val result=async(start=CoroutineStart.UNDISPATCHED){engine.pickAccountSetupArchive()}
        val started=shadowOf(activity.get()).nextStartedActivityForResult
        assertEquals(Intent.ACTION_OPEN_DOCUMENT,started.intent.action)
        assertFalse(engine.onActivityResult(started.requestCode+1,Activity.RESULT_CANCELED,null));assertFalse(result.isCompleted)
        assertTrue(engine.onActivityResult(started.requestCode,Activity.RESULT_CANCELED,null));assertNull(result.await())
        assertFalse(engine.onActivityResult(started.requestCode,Activity.RESULT_CANCELED,null))
    }
    @Test fun ownedPickerPauseKeepsImmediateCoverWithoutCancellingTheLegitimateHandoff()=runBlocking {
        val registry=field("registry").get(engine) as NativeRegistry;registry.setPref("lockEnabled","true")
        val result=async(start=CoroutineStart.UNDISPATCHED){engine.pickAccountSetupArchive()}
        val started=shadowOf(activity.get()).nextStartedActivityForResult
        val overlap=try{engine.exportAccountSetupArchive();null}catch(error:FlutterError){error}
        assertEquals("busy",overlap!!.code)
        engine.onPause()
        assertTrue(field("covered").getBoolean(engine));assertFalse(field("foreground").getBoolean(engine))
        assertFalse("Owned system picker is the existing bounded handoff exception",field("locked").getBoolean(engine))
        assertFalse(result.isCompleted)
        engine.onResume();assertTrue(field("covered").getBoolean(engine))
        assertTrue(engine.onActivityResult(started.requestCode,Activity.RESULT_CANCELED,null));assertNull(result.await())
        // A subsequent real background transition has no owned picker exception.
        engine.onPause();assertTrue(field("locked").getBoolean(engine))
    }
    @Test fun ordinaryBackgroundLocksAndCannotStartAnArchiveOperation()=runBlocking {
        (field("registry").get(engine) as NativeRegistry).setPref("lockEnabled","true")
        engine.onPause()
        assertTrue(field("locked").getBoolean(engine));assertTrue(field("covered").getBoolean(engine))
        val error=try{engine.pickAccountSetupArchive();null}catch(error:FlutterError){error}
        assertEquals("authentication",error!!.code)
    }
    @Test fun lockCancelsPickerAndLateResultCannotReturnPreview()=runBlocking {
        val result=async(start=CoroutineStart.UNDISPATCHED){engine.pickAccountSetupArchive()}
        val started=shadowOf(activity.get()).nextStartedActivityForResult
        engine.lockApp();assertNull(result.await())
        assertFalse(engine.onActivityResult(started.requestCode,Activity.RESULT_OK,Intent().setData(android.net.Uri.parse("content://example/archive"))))
        assertTrue((field("registry").get(engine) as NativeRegistry).rows().isEmpty())
    }
    @Test fun detachCancelsExportAndDoesNotRetainDestinationGrant()=runBlocking {
        val result=async(start=CoroutineStart.UNDISPATCHED){engine.exportAccountSetupArchive()}
        val started=shadowOf(activity.get()).nextStartedActivityForResult
        assertEquals(Intent.ACTION_CREATE_DOCUMENT,started.intent.action)
        assertEquals(0,started.intent.flags and Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        engine.onActivityDetached();assertFalse(result.await())
        assertFalse(engine.onActivityResult(started.requestCode,Activity.RESULT_OK,Intent().setData(android.net.Uri.parse("content://example/archive"))))
    }
    private fun installFixtureProvider(file:File):Uri {
        val provider=FixtureDocumentProvider().also{it.file=file}
        provider.attachInfo(context,ProviderInfo().apply{authority="profiledesk.setup.fixture"})
        ShadowContentResolver.registerProviderInternal("profiledesk.setup.fixture",provider)
        return Uri.parse("content://profiledesk.setup.fixture/archive.json")
    }
    private suspend fun drainUntilComplete(done:()->Boolean){
        val deadline=System.nanoTime()+5_000_000_000L
        while(!done()&&System.nanoTime()<deadline){shadowOf(Looper.getMainLooper()).idle();kotlinx.coroutines.yield();Thread.sleep(5)}
        shadowOf(Looper.getMainLooper()).idle();assertTrue("Bounded document I/O must finish",done())
    }
    @Test fun selectedOwnedDocumentReadsValidatedMetadataWithoutImportingProfiles()=runBlocking {
        val file=File.createTempFile("setup-import",".json",context.cacheDir)
        try{
            val archive=AccountSetupArchive(listOf(AccountSetupArchive.Entry("Synthetic",42)),"dark")
            file.writeText(archive.encode());val uri=installFixtureProvider(file)
            val result=async(start=CoroutineStart.UNDISPATCHED){engine.pickAccountSetupArchive()}
            val started=shadowOf(activity.get()).nextStartedActivityForResult
            assertTrue(engine.onActivityResult(started.requestCode,Activity.RESULT_OK,Intent().setData(uri)))
            drainUntilComplete{result.isCompleted}
            assertEquals(archive,AccountSetupArchive.parse(result.await()!!))
            assertTrue((field("registry").get(engine) as NativeRegistry).rows().isEmpty())
        }finally{file.delete()}
    }
    @Test fun exportWritesOnlySetupMetadataToUserSelectedDestination()=runBlocking {
        val file=File.createTempFile("setup-export",".json",context.cacheDir)
        try{
            val registry=field("registry").get(engine) as NativeRegistry
            val row=registry.reserve("Synthetic export",123);registry.state(row.id,"available");registry.observe(row.id,"userConfirmed")
            registry.setPref("lockEnabled","true");registry.setPref("theme","dark")
            val uri=installFixtureProvider(file)
            val result=async(start=CoroutineStart.UNDISPATCHED){engine.exportAccountSetupArchive()}
            val started=shadowOf(activity.get()).nextStartedActivityForResult
            assertTrue(engine.onActivityResult(started.requestCode,Activity.RESULT_OK,Intent().setData(uri)))
            drainUntilComplete{result.isCompleted};assertTrue(result.await())
            val text=file.readText();val archive=AccountSetupArchive.parse(text)
            assertEquals(listOf(AccountSetupArchive.Entry("Synthetic export",123)),archive.accounts);assertEquals("dark",archive.theme)
            for(secret in listOf(row.id,row.platformId,"userConfirmed","lockEnabled"))assertFalse(text.contains(secret))
        }finally{file.delete()}
    }
    @Test fun unavailablePickerUsesSafeErrorAndUnlockIsRequired()=runBlocking {
        val missing=Robolectric.buildActivity(MissingActivity::class.java).setup()
        engine.activity=missing.get()
        try{
            val error=try{engine.pickAccountSetupArchive();null}catch(error:FlutterError){error}
            assertNotNull(error);assertEquals("archiveUnavailable",error!!.code);assertFalse(error.message!!.contains("Provider path"))
            field("locked").setBoolean(engine,true)
            val locked=try{engine.pickAccountSetupArchive();null}catch(error:FlutterError){error}
            assertEquals("authentication",locked!!.code)
        }finally{missing.pause().stop().destroy()}
    }
}
