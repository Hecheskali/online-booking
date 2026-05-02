package com.example.online_booking

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    companion object {
        private const val RINGTONE_PICKER_REQUEST_CODE = 9042
    }

    private val appConfigChannel = "online_booking/app_config"
    private val alarmSoundChannel = "online_booking/alarm_sound"
    private var pendingAlarmSoundResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appConfigChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasGoogleMapsApiKey" -> result.success(hasGoogleMapsApiKey())
                    "getTimeZoneId" -> result.success(TimeZone.getDefault().id)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, alarmSoundChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickAlarmSound" -> {
                        val currentUri = call.argument<String>("currentUri")
                        launchAlarmSoundPicker(currentUri, result)
                    }
                    "getDefaultAlarmSound" -> result.success(buildAlarmSoundSelection(defaultAlarmUri()))
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasGoogleMapsApiKey(): Boolean {
        return try {
            val appInfo = packageManager.getApplicationInfo(
                packageName,
                PackageManager.GET_META_DATA
            )
            val apiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY")
            !apiKey.isNullOrBlank()
        } catch (_: Exception) {
            false
        }
    }

    private fun launchAlarmSoundPicker(currentUri: String?, result: MethodChannel.Result) {
        if (pendingAlarmSoundResult != null) {
            result.error(
                "picker_active",
                "An alarm sound picker is already open.",
                null
            )
            return
        }

        pendingAlarmSoundResult = result

        val existingUri = currentUri
            ?.takeIf { it.isNotBlank() }
            ?.let(Uri::parse)
            ?: defaultAlarmUri()

        val pickerIntent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM or
                    RingtoneManager.TYPE_NOTIFICATION or
                    RingtoneManager.TYPE_RINGTONE
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select alert sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI, defaultAlarmUri())
            putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, existingUri)
        }

        @Suppress("DEPRECATION")
        startActivityForResult(pickerIntent, RINGTONE_PICKER_REQUEST_CODE)
    }

    private fun handleAlarmSoundPickerResult(resultCode: Int, data: Intent?) {
        val pendingResult = pendingAlarmSoundResult ?: return
        pendingAlarmSoundResult = null

        if (resultCode != Activity.RESULT_OK) {
            pendingResult.success(null)
            return
        }

        val pickedUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra<Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }

        pendingResult.success(buildAlarmSoundSelection(pickedUri ?: defaultAlarmUri()))
    }

    private fun defaultAlarmUri(): Uri? {
        return RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
    }

    private fun buildAlarmSoundSelection(uri: Uri?): Map<String, String>? {
        if (uri == null) return null

        val title = try {
            RingtoneManager.getRingtone(applicationContext, uri)
                ?.getTitle(applicationContext)
                ?.takeIf { it.isNotBlank() }
        } catch (_: Exception) {
            null
        } ?: "Phone default alarm"

        return mapOf(
            "uri" to uri.toString(),
            "title" to title
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == RINGTONE_PICKER_REQUEST_CODE) {
            handleAlarmSoundPickerResult(resultCode, data)
        }
    }
}
