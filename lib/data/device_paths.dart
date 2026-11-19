import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Android path_provider 2.3 asks JNI for `Landroid/content/Context;` and the
/// lookup throws before Hive can open. These paths come from the activity instead.
class DevicePaths extends PathProviderPlatform {
  static const _channel = MethodChannel('app.stepmath/storage');

  static void install() {
    if (Platform.isAndroid) {
      PathProviderPlatform.instance = DevicePaths();
    }
  }

  Future<String?> _get(String method) => _channel.invokeMethod<String>(method);

  @override
  Future<String?> getTemporaryPath() => _get('cache');

  @override
  Future<String?> getApplicationSupportPath() => _get('files');

  @override
  Future<String?> getApplicationDocumentsPath() => _get('documents');

  @override
  Future<String?> getApplicationCachePath() => _get('cache');

  @override
  Future<String?> getExternalStoragePath() => _get('external');

  @override
  Future<List<String>?> getExternalCachePaths() async {
    final path = await _get('externalCache');
    return path == null ? null : [path];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async {
    final path = await _get('external');
    return path == null ? null : [path];
  }
}
