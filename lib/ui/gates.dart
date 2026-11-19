import 'package:flutter/material.dart';

import '../app/session.dart';
import 'kit.dart';

Future<bool> requireParentCode(
  BuildContext context,
  AppController app, {
  required String title,
  required String body,
  required Future<bool> Function(String pin, String? again) action,
  bool? create,
}) async {
  while (true) {
    if (!context.mounted) return false;
    final until = app.settings.pinLockedUntil;
    final wait = until != null && DateTime.now().isBefore(until)
        ? until.difference(DateTime.now()).inSeconds + 1
        : 0;
    final entry = await showPinDialog(
      context,
      title: title,
      body: body,
      create: create ?? app.settings.parentPinHash == null,
      waitSeconds: wait,
    );
    if (entry == null || !context.mounted) return false;
    final ok = await action(entry.pin, entry.again);
    if (ok) return true;
  }
}
