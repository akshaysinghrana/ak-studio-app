package com.akshayrana.video_music_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Foreground service (type dataSync) that runs while link downloads are in
 * progress. Without it Android freezes a backgrounded app within seconds
 * (cached-app freezer / Doze), which stalls the Dart HTTP sockets and the
 * yt-dlp child process until the server drops the connection and the
 * download fails. The service holds a partial wake lock and a Wi-Fi lock and
 * shows a progress notification; the transfers themselves still run in Dart
 * and in the extractor bridge.
 */
class DownloadService : Service() {

    companion object {
        const val CHANNEL = "com.akshayrana.video_music_app/download_service"
        private const val NOTIFICATION_CHANNEL = "downloads"
        private const val NOTIFICATION_ID = 4107
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_TEXT = "text"
        private const val EXTRA_PROGRESS = "progress"

        /** Starts the service or updates its notification. */
        fun update(context: Context, title: String, text: String, progress: Int) {
            val intent = Intent(context, DownloadService::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
                .putExtra(EXTRA_PROGRESS, progress)
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, DownloadService::class.java))
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Downloading"
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: ""
        val progress = intent?.getIntExtra(EXTRA_PROGRESS, -1) ?: -1
        val notification = build(title, text, progress)
        // startForeground must be called promptly after every
        // startForegroundService, so it is called on each update.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        acquireLocks()
        // Not sticky: if the process dies, the in-memory jobs are gone too.
        return START_NOT_STICKY
    }

    /** Android 15+: dataSync services are time-limited; stop cleanly. */
    override fun onTimeout(startId: Int, fgsType: Int) {
        stopSelf()
    }

    override fun onDestroy() {
        releaseLocks()
        super.onDestroy()
    }

    private fun build(title: String, text: String, progress: Int): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(NOTIFICATION_CHANNEL) == null
        ) {
            manager.createNotificationChannel(
                NotificationChannel(
                    NOTIFICATION_CHANNEL,
                    "Downloads",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply { description = "Progress of downloads from links" },
            )
        }
        val launch = packageManager.getLaunchIntentForPackage(packageName)
        val content = launch?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setOngoing(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setContentIntent(content)
            .setProgress(100, progress.coerceIn(0, 100), progress < 0)
            .build()
    }

    @Suppress("DEPRECATION")
    private fun acquireLocks() {
        if (wakeLock == null) {
            wakeLock = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ASMedia:downloads")
                .apply {
                    setReferenceCounted(false)
                    acquire()
                }
        }
        if (wifiLock == null) {
            val wifi = applicationContext.getSystemService(WifiManager::class.java)
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                WifiManager.WIFI_MODE_FULL_HIGH_PERF
            } else {
                WifiManager.WIFI_MODE_FULL
            }
            wifiLock = wifi?.createWifiLock(mode, "ASMedia:downloads")?.apply {
                setReferenceCounted(false)
                acquire()
            }
        }
    }

    private fun releaseLocks() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        wifiLock?.let { if (it.isHeld) it.release() }
        wifiLock = null
    }
}

/** MethodChannel front for [DownloadService]. */
class DownloadServiceChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, DownloadService.CHANNEL)

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "update" -> {
                try {
                    DownloadService.update(
                        context,
                        call.argument<String>("title") ?: "Downloading",
                        call.argument<String>("text") ?: "",
                        call.argument<Int>("progress") ?: -1,
                    )
                    result.success(true)
                } catch (t: Throwable) {
                    // e.g. ForegroundServiceStartNotAllowedException when the
                    // app is already in the background on Android 12+.
                    result.success(false)
                }
            }
            "stop" -> {
                DownloadService.stop(context)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
