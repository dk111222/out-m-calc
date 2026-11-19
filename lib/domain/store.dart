import 'core.dart';

abstract class AppStore {
  Future<void> init({String? path});
  Future<DeviceSettings> readSettings();
  Future<void> saveSettings(DeviceSettings settings);
  Future<void> wipe();
  Future<List<Learner>> readLearners();
  Future<void> saveLearner(Learner learner);
  Future<void> deleteLearner(String id);
  Future<void> putAttempt(Attempt attempt);
  Future<List<Attempt>> attempts(String learnerId);
  Future<void> putWrong(WrongItem item);
  Future<void> saveWrong(WrongItem item);
  Future<List<WrongItem>> wrongs(String learnerId);
  Future<void> saveMastery(Mastery mastery);
  Future<Mastery?> mastery(String learnerId, String trickId);
  Future<List<Mastery>> masteries(String learnerId);
  Future<void> saveSpeed(SpeedRound round);
  Future<List<SpeedRound>> speeds(String learnerId);
  Future<void> saveAssignment(Assignment assignment);
  Future<Assignment?> openAssignment(String learnerId, String localDate);
  Future<void> saveSnapshot(SessionSnapshot snapshot);
  Future<SessionSnapshot?> snapshot(String learnerId);
  Future<void> clearSnapshot(String learnerId);
  Future<void> saveCertificate(Certificate certificate);
  Future<List<Certificate>> certificates(String learnerId);
  void setSession({required bool childMode, String? learnerId});
}
