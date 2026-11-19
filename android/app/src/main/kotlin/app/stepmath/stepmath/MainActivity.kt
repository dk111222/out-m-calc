package app.stepmath.stepmath

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.stepmath/storage")
            .setMethodCallHandler { call, result ->
                val path = when (call.method) {
                    "documents" -> getDir("flutter", Context.MODE_PRIVATE).absolutePath
                    "files" -> filesDir.absolutePath
                    "cache" -> cacheDir.absolutePath
                    "external" -> getExternalFilesDir(null)?.absolutePath
                    "externalCache" -> externalCacheDir?.absolutePath
                    else -> null
                }
                if (path == null && call.method != "external" && call.method != "externalCache") {
                    result.notImplemented()
                } else {
                    result.success(path)
                }
            }
    }
}
