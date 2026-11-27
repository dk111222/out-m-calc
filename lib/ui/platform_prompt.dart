import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../l10n/copy.dart';

bool _ios(BuildContext context) {
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
}

/// A short message. iOS uses a Cupertino surface. Android uses a SnackBar.
void showPlatformMessage(BuildContext context, String message) {
  if (_ios(context)) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: 24,
          right: 24,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
          child: IgnorePointer(
            child: CupertinoPopupSurface(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.3),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 2600), () {
        if (entry.mounted) entry.remove();
      }),
    );
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Camera, photo library, or cancel. The sheet follows the phone platform.
Future<ImageSourceChoice?> askAvatarSource(BuildContext context) {
  final t = Copy.of(context);
  if (_ios(context)) {
    return showCupertinoModalPopup<ImageSourceChoice>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(t.editAvatar),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.pop(context, ImageSourceChoice.camera),
              child: Text(t.takePhoto),
            ),
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.pop(context, ImageSourceChoice.gallery),
              child: Text(t.choosePhoto),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text(t.cancel),
          ),
        );
      },
    );
  }
  return showModalBottomSheet<ImageSourceChoice>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t.takePhoto),
              onTap: () => Navigator.pop(context, ImageSourceChoice.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.choosePhoto),
              onTap: () => Navigator.pop(context, ImageSourceChoice.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(t.cancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}

/// The cropped circle, with save and cancel.
Future<bool> confirmAvatarPreview(BuildContext context, ImageProvider image) {
  final t = Copy.of(context);
  final portrait = CircleAvatar(radius: 72, backgroundImage: image);
  if (_ios(context)) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(t.previewAvatar),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: portrait,
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.save),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(t.previewAvatar),
        content: portrait,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.save),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}

/// Sign-out confirmation. iOS uses a Cupertino alert. Android uses Material.
Future<bool> confirmSignOut(BuildContext context) {
  final t = Copy.of(context);
  if (_ios(context)) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text(t.signOut),
          content: Text(t.signOutBody),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t.cancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, true),
              child: Text(t.signOut),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(t.signOut),
        content: Text(t.signOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.signOut),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}

enum ImageSourceChoice { camera, gallery }
