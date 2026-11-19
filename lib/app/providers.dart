import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/store.dart';
import 'session.dart';

final storeProvider = Provider<AppStore>(
  (ref) => throw StateError('Store is missing.'),
);

final appProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw StateError('App is missing.'),
);

final practiceProvider = ChangeNotifierProvider<PracticeController>((ref) {
  return PracticeController(ref.read(appProvider));
});

final speedProvider = ChangeNotifierProvider<SpeedController>((ref) {
  return SpeedController(ref.read(appProvider));
});
