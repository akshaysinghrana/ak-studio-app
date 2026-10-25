package com.akshayrana.video_music_app

import android.app.PictureInPictureParams
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.media.AudioManager
import android.os.Build
import android.util.Rational
import android.view.WindowManager
import kotlin.math.roundToInt
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity shares its cached FlutterEngine with the audio_service
// background service, so playback state survives the activity going away.
class MainActivity : AudioServiceActivity() {
    companion object {
        private const val PIP_CHANNEL = "com.akshayrana.video_music_app/pip"
        private const val SCREEN_CHANNEL = "com.akshayrana.video_music_app/screen"

        // Android rejects PiP aspect ratios outside 1:2.39 .. 2.39:1.
        private const val MAX_PIP_RATIO = 2.39f
    }

    private var pipChannel: MethodChannel? = null
    private var documentImporter: DocumentImporter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, FrameCapture.CHANNEL)
            .setMethodCallHandler(FrameCapture(applicationContext))
        MethodChannel(messenger, MediaStoreScanner.CHANNEL)
            .setMethodCallHandler(MediaStoreScanner(applicationContext))
        documentImporter = DocumentImporter(this).also {
            MethodChannel(messenger, DocumentImporter.CHANNEL).setMethodCallHandler(it)
        }
        MethodChannel(messenger, SCREEN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Keeps the display on while video plays; cleared otherwise.
                "keepOn" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                // App-window brightness only (0..1); null restores the system
                // value. No WRITE_SETTINGS permission is needed (spec 5.4).
                "setBrightness" -> {
                    val value = (call.arguments as? Number)?.toFloat()
                    window.attributes = window.attributes.apply {
                        screenBrightness = value?.coerceIn(0.01f, 1f)
                            ?: WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    }
                    result.success(null)
                }
                // Media (music stream) volume as a 0..1 fraction (spec 5.4).
                "getVolume" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    result.success(am.getStreamVolume(AudioManager.STREAM_MUSIC).toDouble() / max)
                }
                "setVolume" -> {
                    val am = getSystemService(AUDIO_SERVICE) as AudioManager
                    val max = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                    val fraction = (call.arguments as? Number)?.toDouble() ?: 0.0
                    am.setStreamVolume(
                        AudioManager.STREAM_MUSIC,
                        (fraction.coerceIn(0.0, 1.0) * max).roundToInt(),
                        0,
                    )
                    result.success(null)
                }
                "getBrightness" -> {
                    val current = window.attributes.screenBrightness
                    result.success(if (current < 0) null else current.toDouble())
                }
                else -> result.notImplemented()
            }
        }
        pipChannel = MethodChannel(messenger, PIP_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(isPipSupported())
                    "enter" -> result.success(
                        enterPip(
                            call.argument<Int>("width") ?: 16,
                            call.argument<Int>("height") ?: 9,
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun isPipSupported(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    private fun enterPip(width: Int, height: Int): Boolean {
        if (!isPipSupported() || width <= 0 || height <= 0) return false
        val ratio = (width.toFloat() / height).coerceIn(1 / MAX_PIP_RATIO, MAX_PIP_RATIO)
        val params = PictureInPictureParams.Builder()
            .setAspectRatio(Rational((ratio * 1000).toInt(), 1000))
            .build()
        return try {
            enterPictureInPictureMode(params)
        } catch (e: IllegalStateException) {
            false
        }
    }

    @Deprecated("Activity result API is unavailable on FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (documentImporter?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipChanged", isInPictureInPictureMode)
    }
}
