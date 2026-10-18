package dev.profiledesk.session_engine

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowNetwork

@RunWith(RobolectricTestRunner::class)
@Config(sdk=[29])
class NetworkMonitorTest {
    @Test fun startupWithoutPathIsOfflineAndRegistrationIsIdempotent(){
        val context=ApplicationProvider.getApplicationContext<Context>()
        val shadow=shadowOf(context.getSystemService(ConnectivityManager::class.java))
        shadow.clearAllNetworks();shadow.setActiveNetworkInfo(null)
        val monitor=NetworkMonitor(context){}
        monitor.start();monitor.start()
        assertEquals(NetworkObservation.OFFLINE,monitor.observation)
        assertEquals(1,shadow.networkCallbacks.size)
    }
    @Test fun captivePathStaysUnknownAndLateLossCannotEraseNewDefault(){
        val context=ApplicationProvider.getApplicationContext<Context>()
        val shadow=shadowOf(context.getSystemService(ConnectivityManager::class.java))
        val events=mutableListOf<NetworkObservation>()
        val monitor=NetworkMonitor(context){events.add(it)}
        monitor.start()
        val callback=shadow.networkCallbacks.single()
        val first=ShadowNetwork.newInstance(100)
        val second=ShadowNetwork.newInstance(101)
        val captive=NetworkCapabilities().also{shadowOf(it).addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);shadowOf(it).addCapability(NetworkCapabilities.NET_CAPABILITY_CAPTIVE_PORTAL)}
        val validated=NetworkCapabilities().also{shadowOf(it).addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);shadowOf(it).addCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)}
        callback.onAvailable(first);callback.onCapabilitiesChanged(first,captive)
        assertEquals(NetworkObservation.UNKNOWN,monitor.observation)
        callback.onCapabilitiesChanged(first,validated)
        assertEquals(NetworkObservation.REACHABLE,monitor.observation)
        callback.onAvailable(second);callback.onCapabilitiesChanged(second,validated)
        callback.onLost(first)
        assertEquals(NetworkObservation.REACHABLE,monitor.observation)
        callback.onCapabilitiesChanged(first,captive)
        assertEquals(NetworkObservation.REACHABLE,monitor.observation)
        callback.onLost(second)
        assertEquals(NetworkObservation.OFFLINE,monitor.observation)
        assertTrue(events.contains(NetworkObservation.REACHABLE))
    }
}
