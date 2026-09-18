package tr.limak.teknofest_kiosk

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val appUpdateChannel = "tr.limak.teknofest_kiosk_yatay/app_update"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyKioskWindowFlags()
        hideSystemUi()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appUpdateChannel)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "canInstallPackages" -> {
                            result.success(AppUpdateHelper.canInstallPackages(this))
                        }
                        "openInstallPermissionSettings" -> {
                            AppUpdateHelper.openInstallPermissionSettings(this)
                            result.success(null)
                        }
                        "startDownload" -> {
                            val url = call.argument<String>("url")
                            if (url.isNullOrBlank()) {
                                result.error("invalid_args", "APK adresi bos", null)
                            } else {
                                val version = call.argument<String>("version") ?: "latest"
                                result.success(AppUpdateHelper.startDownload(this, url, version))
                            }
                        }
                        "downloadProgress" -> {
                            val downloadId = call.downloadId()
                            if (downloadId == null) {
                                result.error("invalid_args", "downloadId gerekli", null)
                            } else {
                                result.success(AppUpdateHelper.downloadProgress(this, downloadId))
                            }
                        }
                        "install" -> {
                            val downloadId = call.downloadId()
                            if (downloadId == null) {
                                result.error("invalid_args", "downloadId gerekli", null)
                            } else {
                                result.success(AppUpdateHelper.install(this, downloadId))
                            }
                        }
                        "cancelDownload" -> {
                            call.downloadId()?.let { AppUpdateHelper.cancelDownload(this, it) }
                            result.success(null)
                        }
                        "getInstalledVersion" -> {
                            result.success(AppUpdateHelper.getInstalledVersion(this))
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("app_update_failed", e.message, null)
                }
            }
    }

    override fun onResume() {
        super.onResume()
        applyKioskWindowFlags()
        hideSystemUi()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemUi()
        }
    }

    private fun MethodCall.downloadId(): Long? = when (val raw = argument<Any>("downloadId")) {
        is Number -> raw.toLong()
        is String -> raw.toLongOrNull()
        else -> null
    }

    private fun applyKioskWindowFlags() {
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
    }

    private fun hideSystemUi() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(
                    WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars(),
                )
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                )
        }
    }
}
