package com.akshayrana.video_music_app

import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * Extracts the decoded video frame closest to a position, at source resolution,
 * directly from the media file. This never captures Flutter UI or player controls
 * (MEDIA_PLAYER_SPEC 5.3).
 */
class FrameCapture(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.akshayrana.video_music_app/frame_capture"
    }

    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "captureFrame") {
            result.notImplemented()
            return
        }
        val source = call.argument<String>("source")
        val positionMs = call.argument<Number>("positionMs")?.toLong()
        if (source == null || positionMs == null || positionMs < 0) {
            result.error("bad_args", "source and a non-negative positionMs are required", null)
            return
        }
        executor.execute {
            try {
                val path = capture(source, positionMs)
                mainHandler.post { result.success(path) }
            } catch (e: Exception) {
                mainHandler.post { result.error("capture_failed", e.message, null) }
            }
        }
    }

    private fun capture(source: String, positionMs: Long): String {
        val retriever = MediaMetadataRetriever()
        try {
            if (source.startsWith("content://")) {
                retriever.setDataSource(context, Uri.parse(source))
            } else {
                retriever.setDataSource(source.removePrefix("file://"))
            }
            val bitmap = retriever.getFrameAtTime(
                positionMs * 1000,
                MediaMetadataRetriever.OPTION_CLOSEST,
            ) ?: throw IllegalStateException("No decodable frame at ${positionMs}ms")
            val dir = File(context.cacheDir, "frame_captures").apply { mkdirs() }
            // Timestamp + position keeps names unique; nothing is overwritten.
            val out = File(dir, "frame_${System.currentTimeMillis()}_${positionMs}.png")
            FileOutputStream(out).use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
            bitmap.recycle()
            return out.absolutePath
        } finally {
            retriever.release()
        }
    }
}
