package com.markodevcic.word_twist

import android.content.Context
import android.os.Bundle
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

const val APP_ID = "com.markodevcic.wordtwist"
const val DB_NAME = "foods.db"

class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        MethodChannel(flutterView, APP_ID).setMethodCallHandler { call, result ->
            when {                
                call.method == "copyDb" -> {
                    val dbData = (call.arguments as Map<String, Any>) ["dbData"] as ByteArray
                    openDatabase(dbData)
                    result.success(true)
                }
                else -> result.success(false)
            }
        }
    }

    private fun openDatabase(dbData: ByteArray) {
        val dbFile = getDatabasePath(DB_NAME)
        if (!dbFile.exists()) {
            try {
                val checkDB = openOrCreateDatabase(DB_NAME, Context.MODE_PRIVATE, null)
                checkDB.close()
                copyDatabase(dbFile, dbData)
            } catch (e: IOException) {
                throw RuntimeException("Error creating source database", e)
            }

        }
    }

    private fun copyDatabase(dbFile: File, dbData: ByteArray) {
        val inputStream = ByteArrayInputStream(dbData)
        val outputStream = FileOutputStream(dbFile)

        val buffer = ByteArray(1024)
        while (inputStream.read(buffer) > 0) {
            outputStream.write(buffer)
        }

        outputStream.flush()
        outputStream.close()
        inputStream.close()
    }
}
