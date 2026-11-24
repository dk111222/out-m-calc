package app.stepmath.stepmath;

import android.content.Context;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Keep the launch color behind Flutter so the handoff is not a white flash.
        getWindow().setBackgroundDrawableResource(R.drawable.launch_background);
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "app.stepmath/storage")
                .setMethodCallHandler(this::onStorageCall);
    }

    private void onStorageCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final String path;
        switch (call.method) {
            case "documents":
                path = getDir("flutter", Context.MODE_PRIVATE).getAbsolutePath();
                break;
            case "files":
                path = getFilesDir().getAbsolutePath();
                break;
            case "cache":
                path = getCacheDir().getAbsolutePath();
                break;
            case "external":
                path = directoryPath(getExternalFilesDir(null));
                break;
            case "externalCache":
                path = directoryPath(getExternalCacheDir());
                break;
            default:
                path = null;
                break;
        }
        if (path == null && !"external".equals(call.method) && !"externalCache".equals(call.method)) {
            result.notImplemented();
        } else {
            result.success(path);
        }
    }

    private static String directoryPath(java.io.File directory) {
        return directory == null ? null : directory.getAbsolutePath();
    }
}
