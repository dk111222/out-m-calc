import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepmath/app/theme.dart';
import 'package:stepmath/domain/core.dart';
import 'package:stepmath/ui/avatars.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders all learner avatars', (tester) async {
    await tester.binding.setSurfaceSize(const Size(720, 960));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
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

    expect(learnerAvatarIds, hasLength(12));
    expect(find.byType(ChildAvatar), findsNWidgets(12));
    expect(find.byType(Image), findsNWidgets(12));
  });
}
