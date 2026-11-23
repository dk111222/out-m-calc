import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/ui/avatars.dart';

void main() {
  LiveTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('render redesigned child avatars preview', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(720, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F4EE),
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFFF7F4EE),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final id in learnerAvatarIds)
                        SizedBox(
                          width: 110,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ChildAvatar(id: id, size: 96),
                              const SizedBox(height: 8),
                              Text(id, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('screenshots/child-avatars-redesign.png');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    File('/opt/cursor/artifacts/child-avatars-redesign.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes.buffer.asUint8List());
    expect(out.existsSync(), isTrue);
    expect(learnerAvatarIds.length, 8);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
