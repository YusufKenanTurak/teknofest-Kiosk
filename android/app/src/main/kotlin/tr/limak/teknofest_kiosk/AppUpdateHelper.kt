package tr.limak.teknofest_kiosk

import android.app.Activity
import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileInputStream

/**
 * Referans: VardiyaTakip AppUpdateHelper.
 * APK güncellemesini DownloadManager ile indirir ve paket yükleyiciyi açar.
 */
object AppUpdateHelper {

    private const val APK_MIME_TYPE = "application/vnd.android.package-archive"
    private const val FILE_PROVIDER_SUFFIX = ".appupdate.fileprovider"

    private val downloadTargets = mutableMapOf<Long, String>()

    fun canInstallPackages(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    fun openInstallPermissionSettings(activity: Activity) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${activity.packageName}"),
            )
        } else {
            Intent(Settings.ACTION_SECURITY_SETTINGS)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        activity.startActivity(intent)
    }

    fun startDownload(context: Context, url: String, version: String): Long {
        val fileName = apkFileName(version)
        val existing = downloadFile(context, fileName)
        if (existing != null && isLikelyApk(existing)) {
            val reuseId = reusedDownloadId(fileName)
            downloadTargets[reuseId] = fileName
            return reuseId
        }
        existing?.delete()

        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(context.applicationInfo.loadLabel(context.packageManager))
            .setDescription("Guncelleme indiriliyor ($version)")
            .setMimeType(APK_MIME_TYPE)
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(true)
            .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, fileName)

        val downloadId = downloadManager(context).enqueue(request)
        downloadTargets[downloadId] = fileName
        return downloadId
    }

    fun downloadProgress(context: Context, downloadId: Long): Map<String, Any?> {
        reusedProgress(context, downloadId)?.let { return it }

        val query = DownloadManager.Query().setFilterById(downloadId)
        downloadManager(context).query(query).use { cursor ->
            if (cursor == null || !cursor.moveToFirst()) {
                return mapOf("status" to "failed", "error" to "Indirme kaydi bulunamadi")
            }

            val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val downloaded = cursor.getLong(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR),
            )
            val total = cursor.getLong(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES),
            )

            val error = if (status == DownloadManager.STATUS_FAILED) {
                val reason = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))
                downloadReasonMessage(reason)
            } else {
                null
            }

            return mapOf(
                "status" to statusName(status),
                "downloadedBytes" to downloaded,
                "totalBytes" to if (total > 0) total else 0L,
                "error" to error,
            )
        }
    }

    fun install(context: Context, downloadId: Long): Boolean {
        val file = downloadedApk(context, downloadId) ?: return false
        if (!isLikelyApk(file)) {
            file.delete()
            return false
        }

        val uri = FileProvider.getUriForFile(
            context,
            context.packageName + FILE_PROVIDER_SUFFIX,
            file,
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        return try {
            if (context is Activity) {
                context.startActivity(intent)
            } else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
            }
            true
        } catch (_: Exception) {
            false
        }
    }

    fun cancelDownload(context: Context, downloadId: Long) {
        if (downloadId >= 0L) {
            downloadManager(context).remove(downloadId)
        }
        downloadTargets.remove(downloadId)
    }

    fun getInstalledVersion(context: Context): Map<String, Any?> {
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.PackageInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(context.packageName, 0)
        }

        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }

        return mapOf(
            "version" to (info.versionName ?: ""),
            "build" to versionCode.toInt(),
        )
    }

    private fun downloadedApk(context: Context, downloadId: Long): File? {
        val expectedName = downloadTargets[downloadId]
        if (expectedName != null) {
            val expected = downloadFile(context, expectedName)
            if (expected != null && expected.exists() && expected.length() > 0L) {
                return expected
            }
        }

        val query = DownloadManager.Query().setFilterById(downloadId)
        downloadManager(context).query(query).use { cursor ->
            if (cursor == null || !cursor.moveToFirst()) return null

            val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            if (status != DownloadManager.STATUS_SUCCESSFUL) return null

            val localUri = cursor.getString(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI),
            ) ?: return null

            return uriToFile(localUri)
        }
    }

    private fun uriToFile(localUri: String): File? {
        val uri = Uri.parse(localUri)
        if ("file" == uri.scheme) {
            val path = uri.path ?: return null
            val file = File(path)
            return if (file.exists()) file else null
        }
        return null
    }

    private fun isLikelyApk(file: File): Boolean {
        if (!file.exists() || file.length() < 4L) return false
        return try {
            FileInputStream(file).use { input ->
                val header = ByteArray(4)
                if (input.read(header) != 4) return false
                header[0] == 'P'.code.toByte() && header[1] == 'K'.code.toByte()
            }
        } catch (_: Exception) {
            false
        }
    }

    private fun downloadFile(context: Context, fileName: String): File? {
        val dir = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: return null
        return File(dir, fileName)
    }

    private fun apkFileName(version: String): String {
        val safeVersion = version.replace(Regex("[^A-Za-z0-9._-]"), "_")
        return "update-$safeVersion.apk"
    }

    private fun reusedDownloadId(fileName: String): Long =
        -1L - (fileName.hashCode().toLong() and 0x7fffffff)

    private fun reusedProgress(context: Context, downloadId: Long): Map<String, Any?>? {
        if (downloadId >= 0L) return null
        val fileName = downloadTargets[downloadId] ?: return null
        val file = downloadFile(context, fileName)
        if (file != null && isLikelyApk(file)) {
            val size = file.length()
            return mapOf(
                "status" to "successful",
                "downloadedBytes" to size,
                "totalBytes" to size,
                "error" to null,
            )
        }
        return mapOf("status" to "failed", "error" to "Kayitli paket gecersiz")
    }

    private fun downloadReasonMessage(reason: Int): String = when (reason) {
        DownloadManager.ERROR_CANNOT_RESUME -> "Indirme devam ettirilemedi"
        DownloadManager.ERROR_DEVICE_NOT_FOUND -> "Depolama bulunamadi"
        DownloadManager.ERROR_FILE_ALREADY_EXISTS -> "Dosya zaten var"
        DownloadManager.ERROR_FILE_ERROR -> "Dosya yazilamadi"
        DownloadManager.ERROR_HTTP_DATA_ERROR -> "Ag verisi bozuk (sunucu HTML donmus olabilir)"
        DownloadManager.ERROR_INSUFFICIENT_SPACE -> "Yetersiz depolama alani"
        DownloadManager.ERROR_TOO_MANY_REDIRECTS -> "Cok fazla yonlendirme"
        DownloadManager.ERROR_UNHANDLED_HTTP_CODE -> "Sunucu hatasi (HTTP)"
        DownloadManager.ERROR_UNKNOWN -> "Bilinmeyen indirme hatasi"
        else -> "Indirme basarisiz (kod: $reason)"
    }

    private fun statusName(status: Int): String = when (status) {
        DownloadManager.STATUS_PENDING -> "pending"
        DownloadManager.STATUS_RUNNING -> "running"
        DownloadManager.STATUS_PAUSED -> "paused"
        DownloadManager.STATUS_SUCCESSFUL -> "successful"
        DownloadManager.STATUS_FAILED -> "failed"
        else -> "idle"
    }

    private fun downloadManager(context: Context): DownloadManager =
        context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
}
