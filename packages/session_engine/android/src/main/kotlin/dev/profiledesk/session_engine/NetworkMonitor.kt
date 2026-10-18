package dev.profiledesk.session_engine

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper

/** OS path observation only. A validated path does not prove service availability. */
internal class NetworkMonitor(context:Context,private val changed:(NetworkObservation)->Unit) {
    private val connectivity=context.applicationContext.getSystemService(ConnectivityManager::class.java)
    private val main=Handler(Looper.getMainLooper())
    var observation=NetworkObservation.UNKNOWN
        private set
    private var registered=false
    private var currentNetwork:Network?=null
    private val callback=object:ConnectivityManager.NetworkCallback(){
        override fun onAvailable(network:Network){
            currentNetwork=network
            // Wait for the immediately following capabilities callback. Querying
            // ConnectivityManager here can race its own state propagation.
            update(NetworkObservation.UNKNOWN)
        }
        override fun onCapabilitiesChanged(network:Network,capabilities:NetworkCapabilities){
            if(network==currentNetwork)update(classify(capabilities))
        }
        override fun onLost(network:Network){
            if(network==currentNetwork){currentNetwork=null;update(NetworkObservation.OFFLINE)}
        }
        override fun onUnavailable(){currentNetwork=null;update(NetworkObservation.OFFLINE)}
    }
    fun start(){
        if(registered)return
        try {
            connectivity.registerDefaultNetworkCallback(callback,main)
            registered=true
            refresh()
        }catch(_:RuntimeException){update(NetworkObservation.UNKNOWN)}
    }
    private fun refresh(){
        val value=try {
            val active=connectivity.activeNetwork
            currentNetwork=active
            val capabilities=active?.let{connectivity.getNetworkCapabilities(it)}
            when {
                active==null->NetworkObservation.OFFLINE
                else->classify(capabilities)
            }
        }catch(_:RuntimeException){NetworkObservation.UNKNOWN}
        update(value)
    }
    private fun classify(capabilities:NetworkCapabilities?)=
        if(capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)==true&&
            capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED))NetworkObservation.REACHABLE
        else NetworkObservation.UNKNOWN
    private fun update(value:NetworkObservation){
        if(value==observation)return
        observation=value
        changed(value)
    }
}
