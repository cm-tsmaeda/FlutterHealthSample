package com.sample.health_sample

import android.content.Intent
import android.os.Bundle
import android.util.Log
//import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "com.example.health_sample"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "main activity onCreate")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "openPrivacyPolicy" -> {
                    Log.d(TAG, "openPrivacyPolicy method called")
                    try {
                        val intent = Intent(this, PrivacyPolicyActivity::class.java)
                        startActivity(intent)
                        result.success("open success")
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to open PrivacyPolicy: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
