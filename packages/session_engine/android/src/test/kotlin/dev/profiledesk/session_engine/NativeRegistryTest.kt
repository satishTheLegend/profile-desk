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
class NativeRegistryTest {
    private lateinit var db:NativeRegistry
    private lateinit var context:Context
    @Before fun setup(){context=ApplicationProvider.getApplicationContext();context.deleteDatabase("profiledesk_registry.db");db=NativeRegistry(context)}
    @After fun close(){db.close();context.deleteDatabase("profiledesk_registry.db")}
    @Test fun tenReservationsBlockTheEleventhBeforeNativeAllocation(){repeat(10){db.reserve("Account $it",0)};assertThrows(IllegalStateException::class.java){db.reserve("Eleventh",0)};assertEquals(10,db.rows().size)}
    @Test fun aliasesAreUniqueAndRenamePreservesIdentity(){val first=db.reserve("Work",1);assertThrows(IllegalArgumentException::class.java){db.reserve(" work ",2)};db.rename(first.id,"Personal",5);val renamed=db.get(first.id)!!;assertEquals(first.platformId,renamed.platformId);assertEquals(5L,renamed.color);assertEquals("Personal",renamed.alias)}
    @Test fun tombstonePersistsAndUsesOriginalOperationId(){val row=db.reserve("A",0);val original=db.tombstone(row.id,"operation-a");db.tombstone(row.id,"operation-b");assertEquals("operation-a",db.cleanup().single().operation);db.close();db=NativeRegistry(context);assertEquals("removing",db.get(row.id)!!.state);assertEquals(original.operation,db.cleanup().single().operation)}
    @Test fun capacityReleasesOnlyAfterScopedWipeAndAppCleanup(){val rows=(0..9).map{db.reserve("A$it",0)};db.tombstone(rows[4].id);assertThrows(IllegalStateException::class.java){db.reserve("New",0)};db.advance(rows[4].id,"websiteWipePending");assertThrows(IllegalStateException::class.java){db.reserve("New",0)};db.advance(rows[4].id,"containerDeletionPending");val replacement=db.reserve("New",0);assertNotEquals(rows[4].platformId,replacement.platformId);rows.filterIndexed{index,_->index!=4}.forEach{assertEquals(it.platformId,db.get(it.id)!!.platformId)}}
    @Test fun cleanupForInactiveProfileCannotChangeAnotherProfile(){val a=db.reserve("A",0);val b=db.reserve("B",0);db.state(a.id,"available");db.state(b.id,"available");db.tombstone(b.id);db.advance(b.id,"websiteWiped");db.complete(b.id);assertEquals("available",db.get(a.id)!!.state);assertNull(db.get(b.id));assertTrue(db.cleanup().isEmpty())}
    @Test fun reorderRejectsDuplicateOrIncompleteIdentityLists(){val a=db.reserve("A",0);val b=db.reserve("B",0);assertThrows(IllegalArgumentException::class.java){db.reorder(listOf(a.id,a.id))};db.reorder(listOf(b.id,a.id));assertEquals(listOf(b.id,a.id),db.rows().map{it.id})}
    @Test fun repeatedCleanupBacklogIsBounded(){repeat(10){val row=db.reserve("A$it",0);db.tombstone(row.id);db.advance(row.id,"containerDeletionPending")};assertThrows(IllegalStateException::class.java){db.reserve("Another",0)}}
    @Test fun cleanupRequiresMatchingTombstoneAndOperation(){
        val intended=db.reserve("Removing",0);val survivor=db.reserve("Survivor",0)
        db.state(intended.id,"available");db.state(survivor.id,"available")
        val task=db.tombstone(intended.id,"original-operation")
        assertTrue(db.cleanupAuthorized(task))
        assertFalse(db.cleanupAuthorized(task.copy(operation="stale-operation")))
        // Simulate a valid-UUID journal retargeted to an otherwise available account.
        db.writableDatabase.execSQL("UPDATE cleanup SET profile_id=? WHERE profile_id=?",arrayOf(survivor.id,intended.id))
        val retargeted=db.cleanup().single()
        assertFalse(db.cleanupAuthorized(retargeted))
        assertEquals("available",db.get(survivor.id)!!.state)
        assertFalse(db.cleanupAuthorized(task))
        db.writableDatabase.execSQL("UPDATE cleanup SET profile_id=? WHERE profile_id=?",arrayOf(intended.id,survivor.id))
        db.advance(intended.id,"containerDeletionPending")
        assertTrue(db.cleanupAuthorized(db.cleanup().single()))
    }
}
