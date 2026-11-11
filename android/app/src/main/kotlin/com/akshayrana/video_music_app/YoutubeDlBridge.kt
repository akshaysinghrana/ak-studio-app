package com.akshayrana.video_music_app

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import kotlin.concurrent.thread

/**
 * On-device extractor bridge (yt-dlp through youtubedl-android). Lets the app
 * resolve and download from sites the plain HTTP resolver cannot reach
 * (YouTube, Facebook, Instagram, ...) with no external server.
 *
 * Native work (init, info, download) runs off the UI thread; results and
 * progress are posted back to the main thread, which is where a MethodChannel
 * must be used.
 */
class YoutubeDlBridge(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.akshayrana.video_music_app/youtube_dl"
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val main = Handler(Looper.getMainLooper())
    private val lastPercent = ConcurrentHashMap<String, Int>()

    /** Process ids stopped by "pause" (their partial files are kept). */
    private val pausing = ConcurrentHashMap.newKeySet<String>()

    @Volatile
    private var initialized = false

    /** The bundled extractor is a snapshot; refresh it at first use so site
     * extractors keep pace with upstream changes. A failed update is harmless:
     * continue with the bundled version and let the actual request decide. */
    @Volatile
    private var updateChecked = false

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> prepare(result)
            "info" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("args", "Missing url", null)
                } else {
                    thread { runInfo(url, result) }
                }
            }
            "download" -> {
                val url = call.argument<String>("url")
                val destDir = call.argument<String>("destDir")
                val processId = call.argument<String>("processId")
                if (url.isNullOrBlank() || destDir.isNullOrBlank() || processId.isNullOrBlank()) {
                    result.error("args", "Missing download arguments", null)
                } else {
                    val format = call.argument<String>("format") ?: "bv*+ba/b"
                    val audioOnly = call.argument<Boolean>("audioOnly") ?: false
                    val jobId = call.argument<String>("jobId") ?: processId
                    val resume = call.argument<Boolean>("resume") ?: false
                    thread {
                        runDownload(url, format, audioOnly, destDir, jobId, processId, resume, result)
                    }
                }
            }
            "cancel" -> {
                val processId = call.argument<String>("processId")
                if (processId != null) YoutubeDL.getInstance().destroyProcessById(processId)
                result.success(null)
            }
            "pause" -> {
                // Stops the process but keeps its .part files so a later
                // download of the same job continues where it stopped.
                val processId = call.argument<String>("processId")
                if (processId != null) {
                    pausing.add(processId)
                    if (!YoutubeDL.getInstance().destroyProcessById(processId)) {
                        pausing.remove(processId)
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** Initializes the native extractor; reports false when it cannot start. */
    private fun prepare(result: MethodChannel.Result) {
        if (initialized) {
            result.success(true)
            return
        }
        thread {
            val ok = try {
                ensureInitialized()
                true
            } catch (t: Throwable) {
                false
            }
            main.post { result.success(ok) }
        }
    }

    private fun ensureInitialized() {
        if (initialized) return
        synchronized(this) {
            if (initialized) return
            YoutubeDL.getInstance().init(context)
            FFmpeg.getInstance().init(context)
            initialized = true
        }
    }

    private fun updateExtractorIfNeeded() {
        if (updateChecked) return
        synchronized(this) {
            if (updateChecked) return
            try {
                YoutubeDL.getInstance().updateYoutubeDL(context)
            } catch (_: Throwable) {
                // Downloads must still try the bundled extractor offline or
                // when GitHub is unavailable/rate-limited.
            } finally {
                updateChecked = true
            }
        }
    }

    private fun runInfo(url: String, result: MethodChannel.Result) {
        try {
            ensureInitialized()
            updateExtractorIfNeeded()
            val request = YoutubeDLRequest(url)
                .addOption("--dump-json")
                .addOption("--no-playlist")
                .addOption("--no-warnings")
            val response = YoutubeDL.getInstance().execute(request, null, null)
            val json = response.out
                .lineSequence()
                .firstOrNull { it.trimStart().startsWith("{") }
                ?.trim()
            if (json.isNullOrEmpty()) {
                main.post { result.error("extract", "That link could not be read.", null) }
            } else {
                main.post { result.success(json) }
            }
        } catch (t: Throwable) {
            val message = describe(t)
            main.post { result.error("extract", message, null) }
        }
    }

    private fun runDownload(
        url: String,
        format: String,
        audioOnly: Boolean,
        destDir: String,
        jobId: String,
        processId: String,
        resume: Boolean,
        result: MethodChannel.Result,
    ) {
        // Each job gets its own folder so the produced file is unambiguous
        // even when the shared downloads directory already contains other
        // media. A resumed job keeps the folder so yt-dlp continues its
        // .part files instead of starting over.
        val dir = File(destDir, jobId)
        try {
            ensureInitialized()
            updateExtractorIfNeeded()
            if (!resume) dir.deleteRecursively()
            if (!dir.exists()) dir.mkdirs()
            val request = YoutubeDLRequest(url)
                .addOption("-f", format)
                .addOption("-o", File(dir, "%(title)s.%(ext)s").absolutePath)
                .addOption("--no-playlist")
                .addOption("--no-mtime")
                .addOption("--no-warnings")
                .addOption("--newline")
                .addOption("--continue")
                // Ride out flaky mobile connections instead of failing.
                .addOption("--socket-timeout", "30")
                .addOption("--retries", "15")
                .addOption("--fragment-retries", "15")
                .addOption("--retry-sleep", "exp=1:30")
            if (audioOnly) {
                request.addOption("-x")
                    .addOption("--audio-format", "m4a")
                    .addOption("--audio-quality", "0")
            } else {
                request.addOption("--merge-output-format", "mp4")
            }
            YoutubeDL.getInstance().execute(request, processId) { progress, _, _ ->
                val percent = progress.toDouble()
                val whole = percent.toInt()
                if (lastPercent[processId] != whole) {
                    lastPercent[processId] = whole
                    val fraction = (percent / 100.0).coerceIn(0.0, 1.0)
                    main.post {
                        channel.invokeMethod(
                            "progress",
                            mapOf("processId" to processId, "progress" to fraction),
                        )
                    }
                }
            }
            lastPercent.remove(processId)
            val file = producedFile(dir)
            if (file == null) {
                main.post { result.error("download", "The download produced no file.", null) }
            } else {
                main.post { result.success(file.absolutePath) }
            }
        } catch (t: Throwable) {
            lastPercent.remove(processId)
            val paused = pausing.remove(processId)
            val code = when {
                paused -> "paused"
                t is YoutubeDL.CanceledException -> "cancelled"
                else -> "download"
            }
            // Only a cancel discards partial data; a pause or a failure keeps
            // it so the job can resume. The app removes the folder when the
            // job is cancelled or dismissed.
            if (code == "cancelled") dir.deleteRecursively()
            val message = if (paused) "Paused." else describe(t)
            main.post { result.error(code, message, null) }
        }
    }

    /** The largest finished media file in [dir], ignoring partial downloads. */
    private fun producedFile(dir: File): File? =
        dir.listFiles()
            ?.filter {
                it.isFile && !it.name.endsWith(".part") && !it.name.endsWith(".ytdl")
            }
            ?.maxByOrNull { it.length() }

    private fun describe(t: Throwable): String {
        if (t is YoutubeDL.CanceledException) return "Download cancelled."
        val raw = t.message?.trim().orEmpty()
        if (raw.isEmpty()) return t.javaClass.simpleName.ifEmpty { "The extractor failed." }
        val line = raw.lineSequence().lastOrNull { it.isNotBlank() }?.trim() ?: raw
        return if (line.length > 300) line.take(300) else line
    }
}
