import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/ui/avatars.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders all learner avatars', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final id in learnerAvatarIds)
                  ChildAvatar(id: id, size: 96),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(learnerAvatarIds, hasLength(20));
    for (final id in learnerAvatarIds) {
      expect(
        find.byWidgetPredicate((widget) {
          return widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == 'assets/avatars/$id.jpg';
        }),
        findsOneWidget,
      );
    }
  });
}
