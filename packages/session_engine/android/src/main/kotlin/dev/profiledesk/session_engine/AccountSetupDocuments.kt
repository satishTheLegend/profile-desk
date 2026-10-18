package dev.profiledesk.session_engine

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.Closeable
import java.util.concurrent.atomic.AtomicReference

/** App-owned document requests. Never shares website upload callbacks or grants. */
internal class AccountSetupDocuments(private val context:Context,private val scope:CoroutineScope) {
    private data class Result(val text:String?=null,val exported:Boolean=false)
    private data class Request(val code:Int,val bytes:ByteArray?,val current:()->Boolean,
        val completion:CompletableDeferred<Result>,val signal:CancellationSignal=CancellationSignal(),
        val stream:AtomicReference<Closeable?> = AtomicReference(),var received:Boolean=false)
    private var pending:Request?=null
    private var nextCode=1000
    val isActive:Boolean get()=pending!=null

    suspend fun pick(activity:Activity,current:()->Boolean):String?=request(activity,null,current).text
    suspend fun export(activity:Activity,archive:String,current:()->Boolean):Boolean=
        request(activity,AccountSetupArchive.utf8(archive),current).exported
    private suspend fun request(activity:Activity,bytes:ByteArray?,current:()->Boolean):Result {
        if(pending!=null)throw FlutterError("busy","Finish the current document request.")
        if(nextCode>=4200)throw FlutterError("archiveUnavailable","Restart the app before another document request.")
        val request=Request(nextCode++,bytes,current,CompletableDeferred())
        val intent=Intent(if(bytes==null)Intent.ACTION_OPEN_DOCUMENT else Intent.ACTION_CREATE_DOCUMENT).apply{
            addCategory(Intent.CATEGORY_OPENABLE);type="application/json"
            addFlags(if(bytes==null)Intent.FLAG_GRANT_READ_URI_PERMISSION else Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            if(bytes!=null)putExtra(Intent.EXTRA_TITLE,"Profile-Desk-account-setup.json")
        }
        pending=request
        try{activity.startActivityForResult(intent,request.code)}
        catch(_:Exception){pending=null;throw FlutterError("archiveUnavailable","The system document picker is unavailable.")}
        return try{request.completion.await()}finally{if(pending===request)cancel()}
    }
    fun cancel(){
        val request=pending?:return;pending=null
        request.signal.cancel();runCatching{request.stream.getAndSet(null)?.close()}
        request.completion.complete(Result())
    }
    fun onActivityResult(code:Int,resultCode:Int,data:Intent?):Boolean {
        val request=pending?:return false
        if(request.code!=code)return false
        if(request.received)return true
        request.received=true
        val uri=data?.data
        if(resultCode!=Activity.RESULT_OK||uri?.scheme!="content"||!request.current()){
            cancel();return true
        }
        scope.launch {
            try{
                val result=withContext(Dispatchers.IO){
                    request.signal.throwIfCanceled()
                    val descriptor=context.contentResolver.openFileDescriptor(uri,if(request.bytes==null)"r" else "wt",request.signal)
                        ?:throw IllegalStateException("Document unavailable")
                    val stream:Closeable=if(request.bytes==null)ParcelFileDescriptor.AutoCloseInputStream(descriptor)
                        else ParcelFileDescriptor.AutoCloseOutputStream(descriptor)
                    request.stream.set(stream)
                    try{
                        request.signal.throwIfCanceled()
                        if(request.bytes==null){
                            val text=AccountSetupArchive.read(stream as java.io.InputStream)
                            AccountSetupArchive.parse(text)
                            Result(text=text)
                        }else{
                            (stream as java.io.OutputStream).write(request.bytes);stream.flush()
                            Result(exported=true)
                        }
                    }finally{request.stream.getAndSet(null)?.close()}
                }
                if(pending===request){pending=null;if(request.current())request.completion.complete(result)else request.completion.complete(Result())}
            }catch(error:Exception){
                val code=when{error.message?.startsWith("archiveTooLarge:")==true->"archiveTooLarge";request.bytes!=null||error is java.io.IOException->"archiveUnavailable";else->"invalidArchive"}
                if(pending===request){pending=null;request.completion.completeExceptionally(FlutterError(code,"The account setup document could not be read or saved."))}
            }
        }
        return true
    }
}
