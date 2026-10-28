package com.akshayrana.video_music_app

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Moves media to the system trash (Android 11+) or deletes it permanently.
 * Android shows its own confirmation for files the app does not own; the
 * Dart side only updates the library when this reports success.
 */
class MediaDeleter(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.akshayrana.video_music_app/media_delete"
        const val REQUEST_CODE = 0x5560
    }

    private var pending: MethodChannel.Result? = null

    /** URIs still to delete on Android 10 after a per-file consent. */
    private var legacyQueue: ArrayDeque<Uri>? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isTrashSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
            "delete" -> {
                if (pending != null) {
                    result.error("busy", "A delete request is already open", null)
                    return
                }
                val uris = call.argument<List<String>>("uris")?.map(Uri::parse).orEmpty()
                val trash = call.argument<Boolean>("trash") ?: false
                if (uris.isEmpty()) {
                    result.success(true)
                    return
                }
                delete(uris, trash, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun delete(uris: List<Uri>, trash: Boolean, result: MethodChannel.Result) {
        val (media, documents) = uris.partition { it.authority == MediaStore.AUTHORITY }
        // Picked documents: no system trash exists, delete through their provider.
        for (doc in documents) {
            try {
                if (!DocumentsContract.deleteDocument(activity.contentResolver, doc)) {
                    result.error("delete_failed", "The file could not be deleted", null)
                    return
                }
            } catch (e: Exception) {
                result.error("delete_failed", e.message, null)
                return
            }
        }
        if (media.isEmpty()) {
            result.success(true)
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val request = if (trash) {
                MediaStore.createTrashRequest(activity.contentResolver, media, true)
            } else {
                MediaStore.createDeleteRequest(activity.contentResolver, media)
            }
            pending = result
            activity.startIntentSenderForResult(request.intentSender, REQUEST_CODE, null, 0, 0, 0)
            return
        }
        if (trash) {
            result.error("trash_unsupported", "Trash needs Android 11 or newer", null)
            return
        }
        pending = result
        legacyQueue = ArrayDeque(media)
        continueLegacyDelete()
    }

    /** Android 10 and older: delete one by one, asking per file when required. */
    private fun continueLegacyDelete() {
        val queue = legacyQueue ?: return
        while (queue.isNotEmpty()) {
            val uri = queue.first()
            try {
                activity.contentResolver.delete(uri, null, null)
                queue.removeFirst()
            } catch (e: SecurityException) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && e is RecoverableSecurityException) {
                    activity.startIntentSenderForResult(
                        e.userAction.actionIntent.intentSender, REQUEST_CODE, null, 0, 0, 0,
                    )
                    return
                }
                finish(false, e.message)
                return
            }
        }
        finish(true, null)
    }

    private fun finish(ok: Boolean, error: String?) {
        val result = pending ?: return
        pending = null
        legacyQueue = null
        if (ok) result.success(true) else if (error == null) result.success(false)
        else result.error("delete_failed", error, null)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        if (resultCode != Activity.RESULT_OK) {
            finish(false, null) // user declined: nothing deleted
            return true
        }
        if (legacyQueue != null) continueLegacyDelete() else finish(true, null)
        return true
    }
}
