package com.Zenvix.Zenvix

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.Zenvix.Zenvix/incoming_file"
    }

    private var pendingUri: String? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialFile" -> {
                        result.success(pendingUri)
                        pendingUri = null
                    }
                    "copyContentUri" -> {
                        val uriString = call.arguments as? String
                        if (uriString == null) {
                            result.error("INVALID_ARG", "URI is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val localPath = copyContentUriToCache(uriString)
                            result.success(localPath)
                        } catch (e: Exception) {
                            result.error("COPY_FAILED", e.message, null)
                        }
                    }
                    // Returns a content:// URI via FileProvider for a local file path,
                    // so external apps can open it without FileUriExposedException.
                    "getContentUri" -> {
                        val filePath = call.arguments as? String
                        if (filePath == null) {
                            result.error("INVALID_ARG", "filePath is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val file = File(filePath)
                            val uri = androidx.core.content.FileProvider.getUriForFile(
                                this@MainActivity,
                                "${packageName}.fileprovider",
                                file,
                            )
                            result.success(uri.toString())
                        } catch (e: Exception) {
                            result.error("URI_FAILED", e.message, null)
                        }
                    }
                    // Launches a VIEW intent with FLAG_GRANT_READ_URI_PERMISSION
                    // so external apps can read our FileProvider content:// URI.
                    "openFile" -> {
                        val args = call.arguments as? Map<*, *>
                        val uriString = args?.get("uri") as? String
                        val mimeType = args?.get("mimeType") as? String ?: "application/octet-stream"
                        if (uriString == null) {
                            result.error("INVALID_ARG", "uri is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val uri = Uri.parse(uriString)
                            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, mimeType)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            }
                            val chooser = Intent.createChooser(viewIntent, "Open with").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                // Exclude Zenvix itself from the chooser on Android 10+
                                // to prevent the intent loop.
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    putExtra(
                                        Intent.EXTRA_EXCLUDE_COMPONENTS,
                                        arrayOf(componentName),
                                    )
                                }
                            }
                            startActivity(chooser)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        pendingUri?.let { uri ->
            channel?.invokeMethod("onFileReceived", uri)
            pendingUri = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        if (action != Intent.ACTION_VIEW && action != Intent.ACTION_SEND) return

        val uri: Uri = when (action) {
            Intent.ACTION_VIEW -> intent.data ?: return
            Intent.ACTION_SEND -> {
                val stream: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM)
                }
                stream ?: return
            }
            else -> return
        }

        if (uri.scheme == "content") {
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (_: SecurityException) {
                // Non-persistable — access is still valid for this session.
            }
        }

        val uriString = uri.toString()
        val ch = channel
        if (ch == null) {
            pendingUri = uriString
        } else {
            ch.invokeMethod("onFileReceived", uriString)
        }
    }

    private fun copyContentUriToCache(uriString: String): String {
        val uri = Uri.parse(uriString)

        // Query the real display name (includes extension) from ContentResolver.
        val displayName: String = contentResolver
            .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                } else null
            }
            ?: uri.lastPathSegment?.substringAfterLast('/')
            ?: "incoming_${System.currentTimeMillis()}"

        val incomingDir = File(cacheDir, "zenvix_incoming").apply { mkdirs() }
        val destFile = File(incomingDir, displayName)

        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(destFile).use { output ->
                input.copyTo(output)
            }
        } ?: throw IllegalStateException("Cannot open input stream for $uriString")

        return destFile.absolutePath
    }
}
