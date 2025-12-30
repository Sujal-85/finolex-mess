package com.finolex.mess

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.finolex.canteen/upi"
    private val UPI_REQUEST_CODE = 2024
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "initiateTransaction") {
                val url = call.argument<String>("url")
                if (url != null) {
                    pendingResult = result
                    launchUpiIntent(url)
                } else {
                    result.error("INVALID_URL", "URL cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun launchUpiIntent(url: String) {
        try {
            val uri = Uri.parse(url)
            val intent = Intent(Intent.ACTION_VIEW)
            intent.data = uri
            val chooser = Intent.createChooser(intent, "Pay with")
            if (intent.resolveActivity(packageManager) != null) {
                startActivityForResult(chooser, UPI_REQUEST_CODE)
            } else {
                pendingResult?.error("NO_UPI_APP", "No UPI app found", null)
                pendingResult = null
            }
        } catch (e: Exception) {
            pendingResult?.error("LAUNCH_FAILED", e.message, null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == UPI_REQUEST_CODE) {
            if (pendingResult == null) return

            if (data != null) {
                // Common UPI response is in "response" extra
                val response = data.getStringExtra("response") ?: "null"
                pendingResult?.success(response)
            } else {
                // Some apps like GPay might return data as null on back press or cancel,
                // or sometimes success but with null data (rare).
                // Usually returns "txnId=...&Status=..." string.
                pendingResult?.success("null") 
            }
            pendingResult = null
        }
    }
}
