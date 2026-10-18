package dev.profiledesk.session_engine

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import java.io.File
import java.util.UUID
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class ImportAllocationJournalTest {
    private fun name()=NativeRegistry.PREFIX+UUID.randomUUID().toString()
    @Test fun recoveryDeletesOnlyUnassignedJournalOwnedProfilesAndKeepsCommittedProfiles(){
        val context=ApplicationProvider.getApplicationContext<Context>();val file=File(context.noBackupFilesDir,"test-setup-journal")
        val journal=ImportAllocationJournal(file);journal.clear()
        val committed=name();val failed=name();val unrelated=name();journal.record(committed);journal.record(failed)
        val deleted=mutableListOf<String>()
        assertEquals(1,journal.reconcile(setOf(committed),setOf(failed),setOf(committed,failed,unrelated)){deleted.add(it)})
        assertTrue(deleted.isEmpty());assertEquals(listOf(failed),journal.pending())
        val restarted=ImportAllocationJournal(file)
        assertEquals(0,restarted.reconcile(setOf(committed),emptySet(),setOf(committed,failed,unrelated)){deleted.add(it)})
        assertEquals(listOf(failed),deleted);assertTrue(restarted.pending().isEmpty());assertFalse(file.exists())
    }
    @Test fun failedDeletionRetainsProvenanceAndInvalidIdentifiersCannotAuthorizeDeletion(){
        val context=ApplicationProvider.getApplicationContext<Context>();val file=File(context.noBackupFilesDir,"test-setup-journal-invalid")
        val journal=ImportAllocationJournal(file);journal.clear();val failed=name();journal.record(failed)
        assertEquals(1,journal.reconcile(emptySet(),emptySet(),setOf(failed)){error("provider busy")})
        assertEquals(listOf(failed),journal.pending())
        assertThrows(IllegalArgumentException::class.java){journal.record("Default")}
        file.writeText("[\"Default\"]")
        assertThrows(IllegalArgumentException::class.java){journal.reconcile(emptySet(),emptySet(),setOf("Default")){fail("Invalid provenance must not delete")}}
        journal.clear()
    }
}
