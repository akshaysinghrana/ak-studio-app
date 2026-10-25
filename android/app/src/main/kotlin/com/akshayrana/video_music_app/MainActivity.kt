package com.akshayrana.video_music_app

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity shares its cached FlutterEngine with the audio_service
// background service, so playback state survives the activity going away.
class MainActivity : AudioServiceActivity() {
    companion object {
        private const val PIP_CHANNEL = "com.akshayrana.video_music_app/pip"

        // Android rejects PiP aspect ratios outside 1:2.39 .. 2.39:1.
        private const val MAX_PIP_RATIO = 2.39f
    }

    private var pipChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, FrameCapture.CHANNEL)
            .setMethodCallHandler(FrameCapture(applicationContext))
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

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipChanged", isInPictureInPictureMode)
    }
}
