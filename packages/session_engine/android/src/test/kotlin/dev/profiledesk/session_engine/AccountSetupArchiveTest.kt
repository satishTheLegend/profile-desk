package dev.profiledesk.session_engine

import java.io.ByteArrayInputStream
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class AccountSetupArchiveTest {
    private val valid="""{"format":"profile-desk-account-setup","version":1,"requiresRelinking":true,"accounts":[{"alias":"Work","color":4280371038}],"appearance":{"theme":"system"}}"""
    private fun rejects(value:String){assertThrows(Exception::class.java){AccountSetupArchive.parse(value)}}
    @Test fun emptyOneAndTenRoundTripWithoutIdentityOrAuthentication(){
        for(count in listOf(0,1,10)){
            val source=AccountSetupArchive((0 until count).map{AccountSetupArchive.Entry("Account $it",0xffffffffL)},"dark")
            val encoded=source.encode();assertEquals(source,AccountSetupArchive.parse(encoded))
            assertFalse(encoded.contains("profileId"));assertFalse(encoded.contains("userConfirmed"));assertFalse(encoded.contains("platformId"))
        }
    }
    @Test fun parserRejectsExcludedFieldsMissingKeysDuplicateKeysAndTrailingData(){
        rejects(valid.replace("\"color\":4280371038","\"color\":4280371038,\"cookies\":[]"))
        rejects(valid.replace("\"version\":1,",""))
        rejects(valid.replace("\"version\":1","\"version\":1,\"version\":1"))
        rejects(valid+"{}");rejects(valid.replace("\"theme\":\"system\"","\"theme\":\"system\",\"lockEnabled\":false"))
        rejects(valid.replace("\"format\"","format"));rejects(valid.replace('"','\''))
    }
    @Test fun parserRequiresExactTypesVersionColorsThemeAndRelinking(){
        for(version in listOf("2","1.0","true","\"1\""))rejects(valid.replace("\"version\":1","\"version\":$version"))
        for(color in listOf("-1","4294967296","1.5","1e2","null","\"4\""))rejects(valid.replace("4280371038",color))
        rejects(valid.replace("\"system\"","\"sepia\""));rejects(valid.replace(":true",":false"))
    }
    @Test fun unicodeNamesAreTrimmedBoundedAndUnique(){
        assertEquals("Work",AccountSetupArchive.parse(valid.replace("Work","  Work  ")).accounts.single().alias)
        assertEquals(40,AccountSetupArchive.parse(valid.replace("Work","😀".repeat(40))).accounts.single().alias.codePointCount(0,80))
        rejects(valid.replace("Work","😀".repeat(41)));rejects(valid.replace("Work",""));rejects(valid.replace("Work","A\\nB"))
        rejects(valid.replace("[{\"alias\":\"Work\",\"color\":4280371038}]","[{\"alias\":\"Work\",\"color\":0},{\"alias\":\" work \",\"color\":0}]"))
        rejects(valid.replace("Work","\uD800"))
    }
    @Test fun boundedUtf8RejectsMalformedAndOversizedInput(){
        assertThrows(Exception::class.java){AccountSetupArchive.read(ByteArrayInputStream(byteArrayOf(0xc3.toByte(),0x28)))}
        assertThrows(Exception::class.java){AccountSetupArchive.read(ByteArrayInputStream(ByteArray(AccountSetupArchive.MAX_BYTES+1)))}
        assertThrows(Exception::class.java){AccountSetupArchive.utf8("😀".repeat(20000))}
        rejects(" ".repeat(AccountSetupArchive.MAX_BYTES)+valid)
    }
    @Test fun hostileNestingIsRejectedByStreamingSchemaWithoutRecursiveParsing(){
        val nested="[".repeat(20000)+"0"+"]".repeat(20000)
        rejects(valid.replace("4280371038",nested))
        rejects(valid.replace("\"accounts\":[", "\"accounts\":["+nested+","))
    }
    @Test fun tooManyAccountsAreRejected(){
        assertThrows(Exception::class.java){AccountSetupArchive((0..10).map{AccountSetupArchive.Entry("A$it",0)},"system").encode()}
    }
}
