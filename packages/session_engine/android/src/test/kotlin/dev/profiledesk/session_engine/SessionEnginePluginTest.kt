package dev.profiledesk.session_engine

import org.junit.Assert.*
import org.junit.Test

class SessionEnginePluginTest {
    @Test fun corruptPersistedIdentitiesCannotAddressDefaultOrOtherProfiles(){
        val first="3b3739ab-958f-47b8-b49f-201f4f397a8a"
        val other="27ce8861-21c5-4080-abba-e83a8f6014e4"
        assertTrue(NativeRegistry.validIdentity(first,"profiledesk_$first"))
        assertFalse(NativeRegistry.validIdentity(first,"Default"))
        assertFalse(NativeRegistry.validIdentity(first,"profiledesk_$other"))
        assertFalse(NativeRegistry.validIdentity("bad-id","profiledesk_bad-id"))
        assertFalse(NativeRegistry.validIdentity(first.uppercase(),"profiledesk_${first.uppercase()}"))
    }
    @Test fun exactOriginRejectsLookalikesCredentialsAndTransportChanges(){
        assertTrue(NavigationPolicy.trusted("https://web.whatsapp.com/"))
        assertTrue(NavigationPolicy.trusted("https://WEB.WHATSAPP.COM:443/path"))
        listOf("https://web.whatsapp.com.evil.test/","https://web.whatsapp.com@evil.test/","https://user@web.whatsapp.com/","http://web.whatsapp.com/","https://web.whatsapp.com:444/","javascript:alert(1)","file:///private/test","https://evil.test/?host=web.whatsapp.com").forEach{assertFalse(it,NavigationPolicy.trusted(it))}
    }
    @Test fun labelsNormalizeWithoutChangingThePresentedName(){
        assertEquals("work",NativeRegistry.normalize(" Work "))
        assertEquals("Work",NativeRegistry.checkedAlias(" Work "))
        listOf("", "  ", "a".repeat(41), "line\nfeed").forEach { value ->
            assertThrows(IllegalArgumentException::class.java){NativeRegistry.checkedAlias(value)}
        }
    }
}
