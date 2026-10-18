package dev.profiledesk.session_engine

import java.net.URI
import java.util.Locale

internal object NavigationPolicy {
    const val WORKSPACE = "https://web.whatsapp.com/"
    fun trusted(raw: String?): Boolean = try {
        val uri=URI(raw ?: "")
        uri.scheme?.lowercase(Locale.ROOT)=="https" &&
            uri.host?.lowercase(Locale.ROOT)=="web.whatsapp.com" &&
            (uri.port==-1 || uri.port==443) && uri.rawUserInfo==null
    } catch(_:Exception) {false}
    fun external(raw:String):Boolean = try {
        val uri=URI(raw)
        uri.scheme?.lowercase(Locale.ROOT) in listOf("http","https") &&
            !uri.host.isNullOrEmpty() && uri.rawUserInfo==null
    } catch(_:Exception) {false}
}
