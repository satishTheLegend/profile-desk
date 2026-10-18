package dev.profiledesk.session_engine

/**
 * Pigeon dispatches suspend calls after receiving a message. Unregistering its
 * handlers does not cancel an already queued call from the old Flutter engine.
 * Reject that call before touching the process-owned runtime. Work that already
 * persisted a cleanup journal may still finish independently of this attachment.
 */
internal class AttachedSessionHostApi(
    private val engine:SessionHostApi,
    private val isCurrent:()->Boolean,
):SessionHostApi {
    val isAttached:Boolean get()=isCurrent()
    private suspend fun <T> attached(action:suspend ()->T):T {
        if(!isCurrent())throw FlutterError("staleAttachment","This Flutter session has ended.")
        return action()
    }
    override suspend fun initialize()=attached{engine.initialize()}
    override suspend fun queryCapabilities()=attached{engine.queryCapabilities()}
    override suspend fun listProfiles()=attached{engine.listProfiles()}
    override suspend fun allocateProfile(alias:String,color:Long)=attached{engine.allocateProfile(alias,color)}
    override suspend fun renameProfile(profileId:String,alias:String,color:Long)=attached{engine.renameProfile(profileId,alias,color)}
    override suspend fun reorderProfiles(profileIds:List<String>)=attached{engine.reorderProfiles(profileIds)}
    override suspend fun setObservation(profileId:String,observation:AuthObservation)=attached{engine.setObservation(profileId,observation)}
    override suspend fun openProfile(profileId:String,operationId:String,selectionGeneration:Long)=attached{engine.openProfile(profileId,operationId,selectionGeneration)}
    override suspend fun disposeView(view:ViewHandle)=attached{engine.disposeView(view)}
    override suspend fun reloadProfileView(view:ViewHandle)=attached{engine.reloadProfileView(view)}
    override suspend fun setWorkspaceLayout(view:ViewHandle,layout:WorkspaceLayout)=attached{engine.setWorkspaceLayout(view,layout)}
    override suspend fun showWorkspaceList(view:ViewHandle)=attached{engine.showWorkspaceList(view)}
    override suspend fun getWorkspacePresentation(view:ViewHandle)=attached{engine.getWorkspacePresentation(view)}
    override suspend fun pickAccountSetupArchive()=attached{engine.pickAccountSetupArchive()}
    override suspend fun exportAccountSetupArchive()=attached{engine.exportAccountSetupArchive()}
    override suspend fun importAccountSetupArchive(archive:String,applyAppearance:Boolean)=attached{engine.importAccountSetupArchive(archive,applyAppearance)}
    override suspend fun requestLocalRemoval(profileId:String,cleanupOperationId:String)=attached{engine.requestLocalRemoval(profileId,cleanupOperationId)}
    override suspend fun retryPendingCleanup()=attached{engine.retryPendingCleanup()}
    override suspend fun setPrivacyCover(visible:Boolean,owner:ViewHandle?)=attached{engine.setPrivacyCover(visible,owner)}
    override suspend fun cancelTransfer()=attached{engine.cancelTransfer()}
    override suspend fun authenticate()=attached{engine.authenticate()}
    override suspend fun lockApp()=attached{engine.lockApp()}
    override suspend fun setPreferences(preferences:AppPreferences)=attached{engine.setPreferences(preferences)}
    override suspend fun resetProfilePermissions(profileId:String)=attached{engine.resetProfilePermissions(profileId)}
    override suspend fun openHelp(topic:HelpTopic)=attached{engine.openHelp(topic)}
    override suspend fun exportDiagnostics()=attached{engine.exportDiagnostics()}
}
