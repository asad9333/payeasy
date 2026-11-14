package com.example.payeasy

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "payeasy/sms"
    private val smsRequestCode = 4401
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasPermission" -> result.success(hasSmsPermission())

                    "requestPermission" -> {
                        if (hasSmsPermission()) {
                            result.success(true)
                        } else if (pendingResult != null) {
                            result.success(false)
                        } else {
                            pendingResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.SEND_SMS),
                                smsRequestCode
                            )
                        }
                    }

                    "send" -> {
                        val phone = call.argument<String>("phone")
                        val message = call.argument<String>("message")
                        if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                            result.success(false)
                        } else {
                            result.success(sendSms(phone, message))
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    @Suppress("DEPRECATION")
    private fun sendSms(phone: String, message: String): Boolean {
        try {
            val sms: SmsManager? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    getSystemService(SmsManager::class.java)
                } else {
                    SmsManager.getDefault()
                }
            if (sms == null) return false
            val parts = sms.divideMessage(message)
            sms.sendMultipartTextMessage(phone, null, parts, null, null)
            return true
        } catch (e: Exception) {
            return false
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == smsRequestCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }
}
