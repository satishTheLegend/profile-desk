package dev.profiledesk.session_engine

import android.util.AtomicFile
import org.json.JSONArray
import java.io.File

/** Installation-excluded provenance for provider allocations outside SQLite's transaction. */
internal class ImportAllocationJournal(private val file:File) {
    private val atomic=AtomicFile(file)
    fun pending():List<String> {
        if(!file.exists()&&!File(file.path+".bak").exists())return emptyList()
        val values=atomic.openRead().use{JSONArray(AccountSetupArchive.read(it))}
        require(values.length()<=NativeRegistry.CAPACITY)
        val names=(0 until values.length()).map{index->
            val name=values.get(index);require(name is String)
            require(name.startsWith(NativeRegistry.PREFIX))
            require(NativeRegistry.validIdentity(name.removePrefix(NativeRegistry.PREFIX),name));name
        }
        require(names.toSet().size==names.size)
        return names
    }
    fun record(platformId:String){
        val existing=pending();require(platformId !in existing);require(existing.size<NativeRegistry.CAPACITY)
        require(NativeRegistry.validIdentity(platformId.removePrefix(NativeRegistry.PREFIX),platformId))
        save(existing+platformId)
    }
    private fun save(names:List<String>){
        if(names.isEmpty()){atomic.delete();return}
        file.parentFile?.mkdirs()
        val output=atomic.startWrite()
        try{output.write(JSONArray(names).toString().toByteArray(Charsets.UTF_8));atomic.finishWrite(output)}
        catch(error:Exception){atomic.failWrite(output);throw error}
    }
    fun clear(){atomic.delete()}
    fun reconcile(known:Set<String>,loaded:Set<String>,existing:Set<String>,delete:(String)->Unit):Int {
        val remaining=mutableListOf<String>()
        for(name in pending()){
            when {
                name in known->Unit // SQLite committed; never delete a published profile.
                name in loaded->remaining.add(name) // Provider requires a clean process first.
                name !in existing->Unit
                else->try{delete(name)}catch(_:Exception){remaining.add(name)}
            }
        }
        save(remaining)
        return remaining.size
    }
}
