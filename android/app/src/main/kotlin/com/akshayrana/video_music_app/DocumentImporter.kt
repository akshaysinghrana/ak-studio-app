package com.akshayrana.video_music_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * System document picker for MP4/MP3 import (spec 4.1). Takes a persistable
 * read grant so imported items keep working after restarts, without copying
 * the file (ADR 0002).
 */
class DocumentImporter(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.akshayrana.video_music_app/documents"
        const val REQUEST_CODE = 0x5550
        private val MIME_TYPES = arrayOf("video/mp4", "audio/mpeg")
    }

    private var pending: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickMedia" -> pick(result)
            "release" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("bad_args", "uri is required", null)
                    return
                }
                try {
                    activity.contentResolver.releasePersistableUriPermission(
                        Uri.parse(uri), Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                } catch (e: SecurityException) {
                    // Grant already gone; nothing to release.
                }
                result.success(null)
            }
            "hasAccess" -> {
                val uri = call.argument<String>("uri")
                result.success(
                    activity.contentResolver.persistedUriPermissions.any {
                        it.uri.toString() == uri && it.isReadPermission
                    },
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A picker is already open", null)
            return
        }
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_MIME_TYPES, MIME_TYPES)
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        activity.startActivityForResult(intent, REQUEST_CODE)
    }

    /** Returns true when the result belonged to this importer. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        pending = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<String>())
            return true
        }
        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) uris += clip.getItemAt(i).uri
        } ?: data.data?.let { uris += it }
        val granted = uris.mapNotNull { uri ->
            try {
                activity.contentResolver.takePersistableUriPermission(
                    uri, Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
                uri.toString()
            } catch (e: SecurityException) {
                // Provider does not offer persistable grants: still usable this session.
                uri.toString()
            }
        }
        result.success(granted)
        return true
    }
}
