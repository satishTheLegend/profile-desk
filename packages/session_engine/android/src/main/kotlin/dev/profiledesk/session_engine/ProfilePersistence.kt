package dev.profiledesk.session_engine

import androidx.webkit.Profile
import androidx.webkit.WebViewFeature

/** Persists only an already resolved named profile; never reads or exports cookies. */
internal object ProfilePersistence {
    fun flushCookies(profile:Profile){
        if(!WebViewFeature.isFeatureSupported(WebViewFeature.MULTI_PROFILE))return
        // Public flush is synchronous so lifecycle completion is a durability boundary.
        // It may perform I/O; no timer or guessed persistence delay is substituted.
        profile.cookieManager.flush()
    }
}
