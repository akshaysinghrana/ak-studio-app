package com.akshayrana.video_music_app

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity shares its cached FlutterEngine with the audio_service
// background service, so playback state survives the activity going away.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FrameCapture.CHANNEL)
            .setMethodCallHandler(FrameCapture(applicationContext))
    }
}
