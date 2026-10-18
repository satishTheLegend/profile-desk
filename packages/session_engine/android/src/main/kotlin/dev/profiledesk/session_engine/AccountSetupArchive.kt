package dev.profiledesk.session_engine

import android.util.JsonReader
import android.util.JsonToken
import org.json.JSONArray
import org.json.JSONObject
import java.io.InputStream
import java.io.StringReader
import java.nio.ByteBuffer
import java.nio.CharBuffer
import java.nio.charset.CodingErrorAction

/** Allowlisted metadata only. This format never contains a browser store or login. */
internal data class AccountSetupArchive(val accounts:List<Entry>,val theme:String) {
    data class Entry(val alias:String,val color:Long)
    companion object {
        const val MAX_BYTES=64*1024
        const val FORMAT="profile-desk-account-setup"
        fun utf8(text:String):ByteArray {
            require(text.length<=MAX_BYTES){"archiveTooLarge: Archive is too large."}
            val buffer=Charsets.UTF_8.newEncoder().onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT).encode(CharBuffer.wrap(text))
            require(buffer.remaining()<=MAX_BYTES){"archiveTooLarge: Archive is too large."}
            return ByteArray(buffer.remaining()).also{buffer.get(it)}
        }
        fun read(input:InputStream):String {
            val output=java.io.ByteArrayOutputStream()
            val chunk=ByteArray(4096)
            while(true){val count=input.read(chunk,0,minOf(chunk.size,MAX_BYTES+1-output.size()));if(count<0)break;if(count==0)continue;output.write(chunk,0,count);require(output.size()<=MAX_BYTES){"archiveTooLarge: Archive is too large."}}
            val bytes=output.toByteArray()
            return Charsets.UTF_8.newDecoder().onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT).decode(ByteBuffer.wrap(bytes)).toString()
        }
        fun parse(text:String):AccountSetupArchive {
            utf8(text)
            val reader=JsonReader(StringReader(text)).apply{isLenient=false}
            return reader.use { r ->
                val fields=mutableSetOf<String>();var accounts:List<Entry>?=null;var theme:String?=null
                r.beginObject()
                while(r.hasNext()){
                    val key=r.nextName();require(fields.add(key)){"Duplicate archive field."}
                    when(key){
                        "format"->require(string(r)==FORMAT){"Unsupported archive format."}
                        "version"->require(number(r)==1L){"Unsupported archive version."}
                        "requiresRelinking"->{require(r.peek()==JsonToken.BOOLEAN);require(r.nextBoolean())}
                        "accounts"->{
                            val entries=mutableListOf<Entry>();r.beginArray()
                            while(r.hasNext()){
                                require(entries.size<NativeRegistry.CAPACITY){"Too many accounts."}
                                val keys=mutableSetOf<String>();var alias:String?=null;var color:Long?=null
                                r.beginObject()
                                while(r.hasNext()){
                                    val name=r.nextName();require(keys.add(name)){"Duplicate account field."}
                                    when(name){"alias"->alias=NativeRegistry.checkedAlias(string(r));"color"->color=number(r).also{require(it in 0..0xffffffffL)};else->error("Unknown account field.")}
                                }
                                r.endObject();require(keys==setOf("alias","color"))
                                entries.add(Entry(requireNotNull(alias),requireNotNull(color)))
                            }
                            r.endArray();require(entries.map{NativeRegistry.normalize(it.alias)}.toSet().size==entries.size){"Duplicate account names."};accounts=entries
                        }
                        "appearance"->{r.beginObject();require(r.hasNext()&&r.nextName()=="theme");theme=string(r);require(!r.hasNext());r.endObject();require(theme in listOf("system","light","dark"))}
                        else->error("Unknown archive field.")
                    }
                }
                r.endObject();require(fields==setOf("format","version","requiresRelinking","accounts","appearance"));require(r.peek()==JsonToken.END_DOCUMENT)
                AccountSetupArchive(requireNotNull(accounts),requireNotNull(theme))
            }
        }
        private fun string(reader:JsonReader):String{require(reader.peek()==JsonToken.STRING);return reader.nextString()}
        private fun number(reader:JsonReader):Long{
            require(reader.peek()==JsonToken.NUMBER)
            val token=reader.nextString();require(token.matches(Regex("0|[1-9][0-9]*")))
            return requireNotNull(token.toLongOrNull())
        }
    }
    fun encode():String {
        val array=JSONArray();accounts.forEach{array.put(JSONObject().put("alias",it.alias).put("color",it.color))}
        val text=JSONObject().put("format",FORMAT).put("version",1).put("requiresRelinking",true)
            .put("accounts",array).put("appearance",JSONObject().put("theme",theme)).toString()
        parse(text)
        return text
    }
}
