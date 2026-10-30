package com.akshayrana.video_music_app

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import android.util.Size
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors

/**
 * Reads MP4/MP3 entries from Android's MediaStore (spec 4.1) and metadata for
 * user-picked documents. All work runs off the main thread; results are plain
 * maps so Dart owns identity and persistence. Never reads whole files.
 */
class MediaStoreScanner(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "com.akshayrana.video_music_app/media_store"
        private const val UNKNOWN = "<unknown>"
        private const val TAG = "MediaStoreScanner"
    }

    private val executor = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())
    private val resolver: ContentResolver get() = context.contentResolver

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "sdkInt") {
            result.success(Build.VERSION.SDK_INT)
            return
        }
        val work: () -> Any? = when (call.method) {
            "query" -> {
                val kind = call.argument<String>("kind")
                val offset = call.argument<Int>("offset") ?: 0
                val limit = call.argument<Int>("limit") ?: 500
                if (kind != "video" && kind != "audio") {
                    result.error("bad_args", "kind must be video or audio", null)
                    return
                }
                { query(kind, offset, limit) }
            }
            "describe" -> {
                val uri = call.argument<String>("uri")
                if (uri == null) {
                    result.error("bad_args", "uri is required", null)
                    return
                }
                { describe(Uri.parse(uri)) }
            }
            "thumbnail" -> {
                val uri = call.argument<String>("uri")
                val size = call.argument<Int>("size") ?: 256
                if (uri == null) {
                    result.error("bad_args", "uri is required", null)
                    return
                }
                { thumbnail(Uri.parse(uri), size) }
            }
            else -> {
                result.notImplemented()
                return
            }
        }
        executor.execute {
            try {
                val value = work()
                mainHandler.post { result.success(value) }
            } catch (e: SecurityException) {
                mainHandler.post { result.error("permission_denied", e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("media_store_failed", e.message, null) }
            }
        }
    }

    private fun query(kind: String, offset: Int, limit: Int): List<Map<String, Any?>> {
        val isVideo = kind == "video"
        val collection = if (isVideo) {
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        }
        val projection = mutableListOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.TITLE,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.DATE_ADDED,
            MediaStore.MediaColumns.DATE_MODIFIED,
            MediaStore.MediaColumns.DURATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            projection += MediaStore.MediaColumns.RELATIVE_PATH
        }
        if (isVideo) {
            projection += listOf(MediaStore.MediaColumns.WIDTH, MediaStore.MediaColumns.HEIGHT)
        } else {
            projection += listOf(MediaStore.Audio.Media.ARTIST, MediaStore.Audio.Media.ALBUM)
        }
        val selection = "${MediaStore.MediaColumns.MIME_TYPE} = ?"
        val args = arrayOf(if (isVideo) "video/mp4" else "audio/mpeg")
        val sort = "${MediaStore.MediaColumns.DATE_ADDED} DESC, ${MediaStore.MediaColumns._ID} DESC"

        val cursor: Cursor? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val queryArgs = Bundle().apply {
                putString(ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
                putStringArray(ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, args)
                putString(ContentResolver.QUERY_ARG_SQL_SORT_ORDER, sort)
                putInt(ContentResolver.QUERY_ARG_LIMIT, limit)
                putInt(ContentResolver.QUERY_ARG_OFFSET, offset)
            }
            resolver.query(collection, projection.toTypedArray(), queryArgs, null)
        } else {
            resolver.query(
                collection, projection.toTypedArray(), selection, args,
                "$sort LIMIT $limit OFFSET $offset",
            )
        }
        // A null cursor means MediaStore did not answer (e.g. the provider is
        // restarting), not that there are no files. Failing here stops a
        // rescan from marking the whole library unavailable.
        if (cursor == null) {
            Log.w(TAG, "MediaStore returned no cursor for $kind (offset $offset)")
            throw IllegalStateException("MediaStore unavailable")
        }
        val rows = mutableListOf<Map<String, Any?>>()
        cursor.use { c ->
            while (c.moveToNext()) {
                val id = c.getLong(c.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
                val folder = c.stringOrNull(MediaStore.MediaColumns.RELATIVE_PATH)
                // Without an album tag MediaStore reports the folder name as the
                // album (found on device); that is not real metadata.
                val folderName = folder?.trimEnd('/')?.substringAfterLast('/')
                val album = c.stringOrNull(MediaStore.Audio.Media.ALBUM)
                    ?.takeIf { it != UNKNOWN && it != folderName }
                rows += mapOf(
                    "storeId" to id,
                    "uri" to ContentUris.withAppendedId(collection, id).toString(),
                    "displayName" to c.stringOrNull(MediaStore.MediaColumns.DISPLAY_NAME),
                    "title" to c.stringOrNull(MediaStore.MediaColumns.TITLE),
                    "mimeType" to c.stringOrNull(MediaStore.MediaColumns.MIME_TYPE),
                    "sizeBytes" to c.longOrNull(MediaStore.MediaColumns.SIZE),
                    "dateAddedSec" to c.longOrNull(MediaStore.MediaColumns.DATE_ADDED),
                    "dateModifiedSec" to c.longOrNull(MediaStore.MediaColumns.DATE_MODIFIED),
                    "durationMs" to c.longOrNull(MediaStore.MediaColumns.DURATION),
                    "folder" to folder,
                    "width" to c.longOrNull(MediaStore.MediaColumns.WIDTH),
                    "height" to c.longOrNull(MediaStore.MediaColumns.HEIGHT),
                    // MediaStore reports "<unknown>" when tags are missing; never invent values.
                    "artist" to c.stringOrNull(MediaStore.Audio.Media.ARTIST)?.takeIf { it != UNKNOWN },
                    "album" to album,
                )
            }
        }
        return rows
    }

    /** Metadata for a user-picked document URI (display name, size, duration). */
    private fun describe(uri: Uri): Map<String, Any?> {
        var displayName: String? = null
        var size: Long? = null
        resolver.query(uri, null, null, null, null)?.use { c ->
            if (c.moveToFirst()) {
                displayName = c.stringOrNull(OpenableColumns.DISPLAY_NAME)
                size = c.longOrNull(OpenableColumns.SIZE)
            }
        }
        val retriever = MediaMetadataRetriever()
        var durationMs: Long? = null
        var width: Long? = null
        var height: Long? = null
        var artist: String? = null
        var album: String? = null
        var title: String? = null
        try {
            retriever.setDataSource(context, uri)
            durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull()
            width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toLongOrNull()
            height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toLongOrNull()
            artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
            album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
            title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
        } catch (e: RuntimeException) {
            // Unreadable/corrupt media: keep basic file info; playback reports the error.
        } finally {
            retriever.release()
        }
        return mapOf(
            "uri" to uri.toString(),
            "displayName" to displayName,
            "title" to title,
            "mimeType" to resolver.getType(uri),
            "sizeBytes" to size,
            "durationMs" to durationMs,
            "width" to width,
            "height" to height,
            "artist" to artist,
            "album" to album,
        )
    }

    /** Writes a small JPEG thumbnail to the cache and returns its path, or null. */
    private fun thumbnail(uri: Uri, size: Int): String? {
        val dir = File(context.cacheDir, "thumbnails").apply { mkdirs() }
        val out = File(dir, "${uri.toString().hashCode().toUInt()}_$size.jpg")
        if (out.exists()) return out.absolutePath
        val isAudio = uri.toString().contains("/audio/") ||
            resolver.getType(uri)?.startsWith("audio/") == true
        val bitmap: Bitmap? = try {
            // MP3 cover art: the embedded picture (ID3 APIC), when present.
            (if (isAudio) embeddedArt(uri, size) else null) ?: if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                resolver.loadThumbnail(uri, Size(size, size), null)
            } else {
                val retriever = MediaMetadataRetriever()
                try {
                    retriever.setDataSource(context, uri)
                    retriever.frameAtTime ?: retriever.embeddedPicture?.let {
                        android.graphics.BitmapFactory.decodeByteArray(it, 0, it.size)
                    }
                } finally {
                    retriever.release()
                }
            }
        } catch (e: Exception) {
            null
        }
        bitmap ?: return null
        FileOutputStream(out).use { bitmap.compress(Bitmap.CompressFormat.JPEG, 85, it) }
        bitmap.recycle()
        return out.absolutePath
    }

    private fun embeddedArt(uri: Uri, size: Int): Bitmap? {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            val bytes = retriever.embeddedPicture ?: return null
            val bounds = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
            android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            var sample = 1
            while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) sample *= 2
            android.graphics.BitmapFactory.decodeByteArray(
                bytes, 0, bytes.size,
                android.graphics.BitmapFactory.Options().apply { inSampleSize = sample },
            )
        } catch (e: RuntimeException) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun Cursor.stringOrNull(column: String): String? {
        val i = getColumnIndex(column)
        return if (i < 0 || isNull(i)) null else getString(i)
    }

    private fun Cursor.longOrNull(column: String): Long? {
        val i = getColumnIndex(column)
        return if (i < 0 || isNull(i)) null else getLong(i)
    }
}
