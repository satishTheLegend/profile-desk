package dev.profiledesk.session_engine

/** Fixed commands and a structural enum. No user text, selector or URL crosses this boundary. */
internal object WorkspaceLayoutCommands {
    private const val guard="window===window.top&&location.protocol==='https:'&&location.hostname==='web.whatsapp.com'&&(!location.port||location.port==='443')&&window.__profileDeskLayout"
    fun mode(layout:WorkspaceLayout):String=command(if(layout==WorkspaceLayout.PHONE)"setMode('phone')" else "setMode('original')")
    val list=command("showList()")
    val dispose=command("dispose()")
    val presentation="""(function(){if($guard){const state=window.__profileDeskLayout.presentation?.()?.state;return state==='original'||state==='list'||state==='menu'||state==='detail'||state==='unavailable'?state:'unavailable';}return 'unavailable';})()"""
    // evaluateJavascript returns JSON. Accept only exact bounded string tokens;
    // no generic JSON decoding or arbitrary service text is retained.
    fun decodePresentation(value:String?):WorkspacePresentation=when(value){
        "\"original\""->WorkspacePresentation.ORIGINAL
        "\"list\""->WorkspacePresentation.LIST
        "\"menu\""->WorkspacePresentation.MENU
        "\"detail\""->WorkspacePresentation.DETAIL
        else->WorkspacePresentation.UNAVAILABLE
    }
    private fun command(operation:String)="(function(){if($guard){window.__profileDeskLayout.$operation;}return null;})()"
}
