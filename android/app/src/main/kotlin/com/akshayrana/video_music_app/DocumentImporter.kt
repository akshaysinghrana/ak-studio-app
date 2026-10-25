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
        const val SUBTITLE_REQUEST_CODE = 0x5551

        // Subtitle files are small; refuse anything larger.
        private const val MAX_TEXT_BYTES = 2 * 1024 * 1024
        private val MIME_TYPES = arrayOf("video/mp4", "audio/mpeg")
    }

    private var pending: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickMedia" -> pick(result)
            "pickSubtitle" -> pickSubtitle(result)
            "readText" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("bad_args", "uri is required", null)
                    return
                }
                readText(Uri.parse(uri), result)
            }
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

    /** SRT/VTT picker; returns a single URI string or null. No persistable grant. */
    private fun pickSubtitle(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A picker is already open", null)
            return
        }
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            // Subtitle MIME types vary by provider; Dart validates the content.
            type = "*/*"
            putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("application/x-subrip", "text/vtt", "text/plain", "application/octet-stream"),
            )
        }
        activity.startActivityForResult(intent, SUBTITLE_REQUEST_CODE)
    }

    private fun readText(uri: Uri, result: MethodChannel.Result) {
        Thread {
            try {
                val bytes = activity.contentResolver.openInputStream(uri)?.use { input ->
                    val buffer = java.io.ByteArrayOutputStream()
                    val chunk = ByteArray(16 * 1024)
                    var total = 0
                    while (true) {
                        val n = input.read(chunk)
                        if (n < 0) break
                        total += n
                        if (total > MAX_TEXT_BYTES) throw IllegalStateException("File is too large")
                        buffer.write(chunk, 0, n)
                    }
                    buffer.toByteArray()
                } ?: throw IllegalStateException("Cannot open file")
                val text = String(bytes, Charsets.UTF_8)
                activity.runOnUiThread { result.success(text) }
            } catch (e: Exception) {
                activity.runOnUiThread { result.error("read_failed", e.message, null) }
            }
        }.start()
    }

    /** Returns true when the result belonged to this importer. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == SUBTITLE_REQUEST_CODE) {
            val result = pending ?: return true
            pending = null
            result.success(if (resultCode == Activity.RESULT_OK) data?.data?.toString() else null)
            return true
        }
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
