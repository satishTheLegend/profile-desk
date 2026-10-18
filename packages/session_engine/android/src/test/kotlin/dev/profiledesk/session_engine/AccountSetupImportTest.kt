package dev.profiledesk.session_engine

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class AccountSetupImportTest {
    private lateinit var db:NativeRegistry
    private lateinit var context:Context
    @Before fun setup(){context=ApplicationProvider.getApplicationContext();context.deleteDatabase("profiledesk_registry.db");db=NativeRegistry(context)}
    @After fun close(){db.close();context.deleteDatabase("profiledesk_registry.db")}
    private fun archive(vararg names:String)=AccountSetupArchive(names.map{AccountSetupArchive.Entry(it,0xff123456L)},"dark")
    @Test fun successfulBatchAppendsFreshIsolatedUnknownProfilesAndOnlyOptionalAppearance(){
        val existing=db.reserve("Existing",7);db.state(existing.id,"available");db.observe(existing.id,"userConfirmed")
        db.setPref("lockEnabled","true");db.setPref("theme","light");db.setPref("welcomeSeen","true")
        val allocated=mutableListOf<String>()
        val first=db.importSetup(archive("A","B"),false){allocated.add(it.platformId)}
        assertEquals(2,first.size);assertEquals(2,allocated.toSet().size)
        first.forEach{assertTrue(NativeRegistry.validIdentity(it.id,it.platformId));assertEquals("available",it.state);assertEquals("unknown",it.observation);assertNull(it.opened);assertNotEquals(existing.id,it.id)}
        assertEquals(listOf("Existing","A","B"),db.rows().map{it.alias});assertEquals("light",db.pref("theme",""))
        assertEquals("userConfirmed",db.get(existing.id)!!.observation)
        db.importSetup(archive("C"),true){}
        assertEquals("dark",db.pref("theme",""));assertEquals("true",db.pref("lockEnabled",""));assertEquals("true",db.pref("welcomeSeen",""))
    }
    @Test fun capacityAndConflictsAreCheckedBeforeAnyProviderAllocation(){
        repeat(9){db.reserve("Existing $it",0)};var calls=0
        assertThrows(IllegalStateException::class.java){db.importSetup(archive("A","B"),false){calls++}}
        assertThrows(IllegalArgumentException::class.java){db.importSetup(archive(" existing 0 "),false){calls++}}
        assertEquals(0,calls);assertEquals(9,db.rows().size)
        db.importSetup(archive("Tenth"),false){calls++};assertEquals(1,calls);assertEquals(10,db.rows().size)
    }
    @Test fun providerFailureRollsBackWholeRegistryBatchAndAppearance(){
        val original=db.reserve("Keep",42);db.setPref("theme","light");var calls=0
        assertThrows(IllegalStateException::class.java){db.importSetup(archive("A","B"),true){calls++;if(calls==2)error("provider unavailable")}}
        assertEquals(2,calls);assertEquals(listOf(original),db.rows());assertEquals("light",db.pref("theme",""))
        // Provider allocations are outside SQLite. The runtime records unassigned stores,
        // which blocks further imports until recovery instead of binding them to aliases.
        db.setPref("orphanCount","1")
        assertThrows(IllegalStateException::class.java){db.importSetup(archive("Retry"),false){fail("Must not provision while orphans require recovery")}}
    }
    @Test fun malformedOrEmptyBatchDoesNotAllocate(){
        assertThrows(IllegalArgumentException::class.java){db.importSetup(archive(),false){fail()}}
        assertThrows(IllegalArgumentException::class.java){db.importSetup(archive("A","a"),false){fail()}}
        assertTrue(db.rows().isEmpty())
    }
}
