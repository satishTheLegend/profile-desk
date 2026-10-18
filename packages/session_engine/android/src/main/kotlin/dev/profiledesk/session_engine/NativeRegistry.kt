package dev.profiledesk.session_engine

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Locale
import java.util.UUID
import javax.crypto.KeyGenerator
import javax.crypto.Mac

/** The only durable authority for allocation, lifecycle, preferences and deletion. */
internal class NativeRegistry(private val context: Context) :
    SQLiteOpenHelper(context, "profiledesk_registry.db", null, 1) {
    companion object {
        const val PREFIX = "profiledesk_"
        const val CAPACITY = 10
        // Wiped containers still consume disk until a clean process start. Bound that backlog.
        const val MAX_PENDING_CONTAINERS = 10
        fun validIdentity(profileId:String,platformId:String):Boolean =
            runCatching{UUID.fromString(profileId).toString()==profileId&&platformId==PREFIX+profileId}.getOrDefault(false)
        fun normalize(alias: String): String = alias.trim().lowercase(Locale.ROOT)
        fun checkedAlias(alias: String): String {
            val trimmed = alias.trim()
            require(trimmed.isNotEmpty()) { "Alias is required." }
            require(trimmed.codePointCount(0, trimmed.length) <= 40) { "Use at most 40 characters." }
            require(trimmed.none { Character.isISOControl(it) }) { "Control characters are not allowed." }
            return trimmed
        }
    }
    data class Row(val id: String, val platformId: String, val alias: String,
        val color: Long, val position: Long, val created: Long, val opened: Long?,
        val state: String, val observation: String)
    data class Cleanup(val profileId: String, val platformId: String, val operation: String,
        val stage: String, val attempts: Long, val error: String?)

    override fun onConfigure(db: SQLiteDatabase) { db.setForeignKeyConstraintsEnabled(true) }
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("CREATE TABLE profiles(id TEXT PRIMARY KEY, platform_id TEXT NOT NULL UNIQUE, alias TEXT NOT NULL, normalized_alias TEXT NOT NULL, color INTEGER NOT NULL, position INTEGER NOT NULL, created INTEGER NOT NULL, opened INTEGER, state TEXT NOT NULL, observation TEXT NOT NULL DEFAULT 'unknown')")
        db.execSQL("CREATE UNIQUE INDEX unique_active_alias ON profiles(normalized_alias) WHERE state NOT IN ('removing','cleanupPending')")
        db.execSQL("CREATE TABLE cleanup(profile_id TEXT PRIMARY KEY REFERENCES profiles(id), operation TEXT NOT NULL UNIQUE, stage TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0, error TEXT, updated INTEGER NOT NULL)")
        db.execSQL("CREATE TABLE preferences(key TEXT PRIMARY KEY,value TEXT NOT NULL)")
        db.execSQL("CREATE TABLE permissions(profile_id TEXT NOT NULL REFERENCES profiles(id),origin TEXT NOT NULL,capability TEXT NOT NULL,decision TEXT NOT NULL,updated INTEGER NOT NULL,PRIMARY KEY(profile_id,origin,capability))")
        db.execSQL("CREATE TABLE transfers(id TEXT PRIMARY KEY,profile_id TEXT NOT NULL REFERENCES profiles(id),view_id TEXT NOT NULL,operation TEXT NOT NULL,state TEXT NOT NULL,created INTEGER NOT NULL)")
        db.execSQL("CREATE TABLE observations(profile_id TEXT NOT NULL REFERENCES profiles(id),observation TEXT NOT NULL,evidence TEXT NOT NULL,observed INTEGER NOT NULL)")
        db.execSQL("CREATE TABLE migrations(version INTEGER PRIMARY KEY,applied INTEGER NOT NULL)")
        db.execSQL("INSERT INTO migrations VALUES(1,?)", arrayOf(System.currentTimeMillis()))
    }
    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Never destructive-reset browser identities during a migration.
        check(oldVersion == newVersion) { "Unsupported registry migration." }
    }
    private inline fun <T> transaction(action: (SQLiteDatabase) -> T): T {
        val db = writableDatabase
        db.beginTransaction()
        try { val result = action(db); db.setTransactionSuccessful(); return result }
        finally { db.endTransaction() }
    }
    fun rows(): List<Row> = readableDatabase.rawQuery("SELECT * FROM profiles ORDER BY position,created", null).use { c -> buildList { while(c.moveToNext()) add(row(c)) } }
    fun get(id: String): Row? = readableDatabase.rawQuery("SELECT * FROM profiles WHERE id=?", arrayOf(id)).use { if(it.moveToFirst()) row(it) else null }
    private fun row(c: Cursor) = Row(c.text("id"), c.text("platform_id"), c.text("alias"), c.long("color"), c.long("position"), c.long("created"), c.getColumnIndexOrThrow("opened").let { if(c.isNull(it)) null else c.getLong(it) }, c.text("state"), c.text("observation"))
    fun reserve(alias: String, color: Long): Row = transaction { db ->
        val label = checkedAlias(alias)
        val count = db.rawQuery("SELECT COUNT(*) FROM profiles WHERE state NOT IN ('cleanupPending')", null).use { it.moveToFirst(); it.getInt(0) }
        check(count < CAPACITY) { "capacity: Ten account slots are already reserved." }
        val pending = db.rawQuery("SELECT COUNT(*) FROM cleanup", null).use { it.moveToFirst(); it.getInt(0) }
        check(pending < MAX_PENDING_CONTAINERS) { "cleanupRequired: Restart to finish pending container cleanup before adding another account." }
        val duplicate = db.rawQuery("SELECT 1 FROM profiles WHERE normalized_alias=? AND state NOT IN ('removing','cleanupPending')", arrayOf(normalize(label))).use { it.moveToFirst() }
        require(!duplicate) { "duplicateAlias: Choose a different account name." }
        val id = UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        val position = db.rawQuery("SELECT COALESCE(MAX(position),-1)+1 FROM profiles",null).use {it.moveToFirst();it.getLong(0)}
        val row = Row(id, PREFIX + id, label, color, position, now, null, "allocating", "unknown")
        db.insertOrThrow("profiles", null, ContentValues().apply {
            put("id",id);put("platform_id",row.platformId);put("alias",label);put("normalized_alias",normalize(label));put("color",color);put("position",position);put("created",now);put("state","allocating")
        })
        row
    }
    /** All metadata is committed together; provider artifacts from a crash stay unassigned. */
    fun importSetup(archive:AccountSetupArchive,applyAppearance:Boolean,provision:(Row)->Unit):List<Row> = transaction { db ->
        require(archive.accounts.isNotEmpty()) { "invalidArchive: No accounts to import." }
        val labels=archive.accounts.map{checkedAlias(it.alias)}
        require(labels.map{normalize(it)}.toSet().size==labels.size) { "duplicateAlias" }
        require(archive.accounts.all{it.color in 0..0xffffffffL}) { "invalidArchive" }
        require(archive.theme in listOf("system","light","dark")) { "invalidArchive" }
        val count=rows().count{it.state!="cleanupPending"}
        check(count+labels.size<=CAPACITY) { "capacity: Not enough account slots." }
        check(cleanup().size<MAX_PENDING_CONTAINERS) { "cleanupRequired: Finish pending cleanup first." }
        check(pref("orphanCount","0")=="0") { "cleanupRequired: Unassigned browser stores need recovery." }
        val existing=rows().filter{it.state !in listOf("removing","cleanupPending")}.map{normalize(it.alias)}.toSet()
        require(labels.none{normalize(it) in existing}) { "duplicateAlias" }
        // Reserve every identity before invoking the provider, then publish the batch only on success.
        val batch=archive.accounts.map{reserve(it.alias,it.color)}
        batch.forEach{provision(it)}
        batch.forEach{db.update("profiles",ContentValues().apply{put("state","available")},"id=?",arrayOf(it.id))}
        if(applyAppearance)setPref("theme",archive.theme)
        batch.map{it.copy(state="available")}
    }
    fun state(id: String, value: String) { writableDatabase.update("profiles", ContentValues().apply { put("state",value) },"id=?",arrayOf(id)) }
    fun opened(id: String) { writableDatabase.update("profiles", ContentValues().apply {put("opened",System.currentTimeMillis())},"id=?",arrayOf(id)) }
    fun rename(id: String, alias: String, color: Long) = transaction { db ->
        val label = checkedAlias(alias)
        require(get(id)?.state !in listOf(null,"removing","cleanupPending")) { "profileUnavailable" }
        require(!db.rawQuery("SELECT 1 FROM profiles WHERE normalized_alias=? AND id<>? AND state NOT IN ('removing','cleanupPending')", arrayOf(normalize(label),id)).use{it.moveToFirst()}) { "duplicateAlias" }
        db.update("profiles",ContentValues().apply{put("alias",label);put("normalized_alias",normalize(label));put("color",color)},"id=?",arrayOf(id))
        Unit
    }
    fun reorder(ids: List<String>) = transaction { db ->
        val eligible=rows().filter{it.state !in listOf("removing","cleanupPending")}.map{it.id}
        require(ids.size==eligible.size && ids.toSet()==eligible.toSet()) { "Invalid reorder list." }
        ids.forEachIndexed { index,id -> db.update("profiles",ContentValues().apply{put("position",index)},"id=?",arrayOf(id)) }
    }
    fun observe(id: String, observation: String) = transaction { db ->
        require(get(id)?.state == "available") { "profileUnavailable" }
        require(observation in listOf("unknown","userConfirmed","relinkRequested"))
        db.update("profiles",ContentValues().apply{put("observation",observation)},"id=?",arrayOf(id))
        db.insertOrThrow("observations",null,ContentValues().apply{put("profile_id",id);put("observation",observation);put("evidence","operator");put("observed",System.currentTimeMillis())})
        Unit
    }
    fun tombstone(id: String, requestedOperation: String = UUID.randomUUID().toString()): Cleanup = transaction { db ->
        cleanup().firstOrNull{it.profileId==id} ?: run {
            val row = requireNotNull(get(id)) {"profileUnavailable"}
            db.update("profiles",ContentValues().apply{put("state","removing")},"id=?",arrayOf(id))
            val operation=requestedOperation
            db.insertOrThrow("cleanup",null,ContentValues().apply{put("profile_id",id);put("operation",operation);put("stage","requested");put("updated",System.currentTimeMillis())})
            Cleanup(id,row.platformId,operation,"requested",0,null)
        }
    }
    fun cleanup(): List<Cleanup> = readableDatabase.rawQuery("SELECT c.*,p.platform_id FROM cleanup c JOIN profiles p ON p.id=c.profile_id",null).use { c -> buildList{while(c.moveToNext())add(Cleanup(c.text("profile_id"),c.text("platform_id"),c.text("operation"),c.text("stage"),c.long("attempts"),c.getColumnIndexOrThrow("error").let{if(c.isNull(it))null else c.getString(it)}))} }
    fun cleanupAuthorized(task:Cleanup):Boolean {
        val row=get(task.profileId)?:return false
        return row.state in listOf("removing","cleanupPending") &&
            row.platformId==task.platformId && validIdentity(row.id,row.platformId) &&
            cleanup().any{it.profileId==task.profileId&&it.operation==task.operation&&it.platformId==task.platformId}
    }
    fun advance(id: String, stage: String, error: String? = null) = transaction { db ->
        db.execSQL("UPDATE cleanup SET stage=?,error=?,attempts=attempts+?,updated=? WHERE profile_id=?",arrayOf<Any?>(stage,error,if(error==null)0 else 1,System.currentTimeMillis(),id))
        if(stage=="containerDeletionPending") db.update("profiles",ContentValues().apply{put("state","cleanupPending")},"id=?",arrayOf(id))
    }
    fun cleanAppRecords(id: String) = transaction { db ->
        db.delete("permissions","profile_id=?",arrayOf(id));db.delete("transfers","profile_id=?",arrayOf(id));db.delete("observations","profile_id=?",arrayOf(id))
    }
    fun complete(id: String) = transaction { db ->
        cleanAppRecords(id);db.delete("cleanup","profile_id=?",arrayOf(id));db.delete("profiles","id=?",arrayOf(id))
    }
    fun pref(key: String, default: String): String = readableDatabase.rawQuery("SELECT value FROM preferences WHERE key=?",arrayOf(key)).use{if(it.moveToFirst())it.getString(0)else default}
    fun setPref(key: String, value: String) { writableDatabase.insertWithOnConflict("preferences",null,ContentValues().apply{put("key",key);put("value",value)},SQLiteDatabase.CONFLICT_REPLACE) }
    fun recordTransfer(id: String, profileId: String, viewId: String, operation: String) { writableDatabase.insertOrThrow("transfers",null,ContentValues().apply{put("id",id);put("profile_id",profileId);put("view_id",viewId);put("operation",operation);put("state","picker");put("created",System.currentTimeMillis())}) }
    fun finishTransfer(id: String) {writableDatabase.delete("transfers","id=?",arrayOf(id))}
    fun cancelInterruptedTransfers(){writableDatabase.delete("transfers",null,null)}
    fun resetPermissions(id:String) { writableDatabase.delete("permissions","profile_id=?",arrayOf(id)) }
    fun recordDeniedPermission(id: String, origin: String, capability: String) {writableDatabase.insertWithOnConflict("permissions",null,ContentValues().apply{put("profile_id",id);put("origin",origin);put("capability",capability);put("decision","deniedUnsupported");put("updated",System.currentTimeMillis())},SQLiteDatabase.CONFLICT_REPLACE)}

    /** Nonexportable key + excluded nonce bind the registry to this installation. */
    fun verifyInstallBinding(): Boolean {
        val nonceFile=File(context.noBackupFilesDir,"profiledesk-install-nonce")
        val saved=pref("installBinding","")
        return try {
            val store=KeyStore.getInstance("AndroidKeyStore").apply{load(null)}
            val alias="profiledesk.registry.binding"
            if(saved.isEmpty() && rows().isEmpty()) {
                if(!store.containsAlias(alias)) KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256,"AndroidKeyStore").apply{init(KeyGenParameterSpec.Builder(alias,KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY).setDigests(KeyProperties.DIGEST_SHA256).build());generateKey()}
                val nonce=ByteArray(32).also{SecureRandom().nextBytes(it)}
                nonceFile.outputStream().use{it.write(nonce);it.fd.sync()}
                setPref("installBinding",sign(store,alias,nonce))
                true
            } else {
                saved.isNotEmpty() && nonceFile.exists() && store.containsAlias(alias) && MessageDigest.isEqual(saved.toByteArray(),sign(store,alias,nonceFile.readBytes()).toByteArray())
            }
        } catch(_: Exception) { false }
    }
    private fun sign(store: KeyStore,alias:String,nonce:ByteArray):String = Mac.getInstance("HmacSHA256").apply{init(store.getKey(alias,null))}.doFinal(nonce).joinToString(""){"%02x".format(it)}
    private fun Cursor.text(name:String)=getString(getColumnIndexOrThrow(name))
    private fun Cursor.long(name:String)=getLong(getColumnIndexOrThrow(name))
}
