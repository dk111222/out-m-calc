import 'package:flutter/material.dart';

import '../domain/core.dart';

class Copy {
  const Copy(this.language);

  final String language;

  bool get zh => language != 'en';

  String pick(String chinese, String english) => zh ? chinese : english;

  static Copy of(BuildContext context) {
    return Localizations.of<Copy>(context, Copy) ?? const Copy('zh');
  }

  String grade(String grade) => gradeLabel(grade, language: language);

  String operation(String operation) =>
      operationLabel(operation, language: language);

  String factTitle(String title) {
    if (!zh) return title;
    switch (title) {
      case 'Adding within 10':
        return '10以内加法';
      case 'Subtracting within 10':
        return '10以内减法';
      case 'Mixed within 10':
        return '10以内混合';
      case 'Adding within 20':
        return '20以内加法';
      case 'Subtracting within 20':
        return '20以内减法';
      case 'Mixed within 20':
        return '20以内混合';
      case 'Adding within 100':
        return '100以内加法';
      case 'Subtracting within 100':
        return '100以内减法';
      case 'Mixed within 100':
        return '100以内混合';
      case 'Multiplication facts':
        return '乘法口诀';
      case 'Division facts':
        return '除法口诀';
      case 'Mixed facts':
        return '混合口诀';
      case 'Two-digit multiplication':
        return '两位数乘法';
      case 'Division':
        return '除法';
      case '10%, 5%, and 1%':
        return '10%、5% 和 1%';
      case 'Decimal tenths':
        return '一位小数';
      case 'Fraction tenths':
        return '分数加减';
      case 'Mixed review':
        return '混合复习';
      default:
        return title;
    }
  }

  String get couldNotSave => pick('没能保存。再试一次。', 'Could not save. Try again.');
  String get parentNeedsThis => pick('需要家长打开这一页。', 'A parent needs to open this.');
  String get chooseGrade => pick('请选择年级。', 'Choose a grade.');
  String get anotherLearner => pick(
    '这台设备开放更多孩子档案后，才能再添加。',
    'Another learner can be added when profiles are included on this device.',
  );
  String get opening => pick('正在这台设备上打开练习。', 'Opening practice on this device.');
  String get tryAgain => pick('再试一次', 'Try again');
  String get whoUses => pick('谁在用这台设备？', 'Who is using this device?');
  String get whoUsesBody => pick(
    '家长或老师先建立孩子档案。也可以不填名字，先试用。',
    'A parent or teacher sets up learners. A guest can practice without a name.',
  );
  String get parentOrTeacher => pick('家长或老师', 'Parent or teacher');
  String get tryAsGuest => pick('先试用', 'Try as a guest');
  String get guest => pick('访客', 'Guest');
  String get learnerStem => pick('学员', 'Learner');
  String get addLearner => pick('添加孩子', 'Add a learner');
  String get back => pick('返回', 'Back');
  String get name => pick('名字', 'Name');
  String get guestNameHint => pick('留空则显示“访客”。', 'Leave this blank to use Guest.');
  String get learnerNameHint =>
      pick('留空则使用“学员”加编号。', 'Leave this blank to use Learner and a number.');
  String get gradeWord => pick('年级', 'Grade');
  String get save => pick('保存', 'Save');
  String get learners => pick('孩子', 'Learners');
  String get settings => pick('设置', 'Settings');
  String get scanPaper => pick('拍照识题', 'Scan a paper');
  String get addLearnerToStart => pick('先添加一个孩子。', 'Add a learner to start.');
  String get nothingAssigned => pick('今天还没有布置', 'Nothing assigned today');
  String get learnATrick => pick('学一个技巧', 'Learn a trick');
  String get speedDrill => pick('速算训练', 'Speed drill');
  String guestPrefix(String rest) => pick('访客 · $rest', 'Guest · $rest');
  String dayStreak(int count) => pick('$count 天连续', '$count day streak');
  String get assign => pick('布置', 'Assign');
  String get report => pick('报告', 'Report');
  String get trickLibrary => pick('技巧库', 'Trick library');
  String get addLearnerFirst => pick('请先添加孩子。', 'Add a learner first.');
  String get todayPractice => pick('今天的练习', 'Today\'s practice');
  String get guestProfile => pick(
    '这是这台设备上的访客档案。进度会留在这里，直到家长删除。',
    'Guest profile on this device. Progress stays here until a parent deletes it.',
  );
  String get skipKept => pick('本周用过一次保留连续天数。', 'This week\'s skip kept the streak.');
  String get streakReset => pick('连续天数已重新开始。', 'The streak started over.');
  String get continueLabel => pick('继续', 'Continue');
  String get mathTricks => pick('速算技巧', 'Math Tricks');
  String get facts => pick('口算', 'Facts');
  String get wrongProblems => pick('错题', 'Wrong problems');
  String get dailyPractice => pick('每日一练', 'Daily practice');
  String get tenProblems =>
      pick('按当前年级随机出十道题。', 'Ten random problems for this grade.');
  String get worksheet => pick('练习页', 'Worksheet');
  String get thisGrade => pick('这个年级', 'This grade');
  String get laterGrades => pick('更高年级', 'Later grades');
  String get saveToday => pick('保存今天', 'Save today');
  String get all => pick('全部', 'All');
  String get saved => pick('已收藏', 'Saved');
  String get noTricksYet => pick('这个年级还没有技巧。', 'No tricks for this grade yet');
  String get laterGradeTrick => pick('这个技巧留给更高年级。', 'This trick is for a later grade.');
  String get notReady => pick('这个技巧还不能练习。', 'This trick is not ready to practice yet.');
  String get missingTrick => pick('这台设备上没有这个技巧。', 'This trick is not on this device.');
  String get useThisWhen => pick('适合', 'Use this when');
  String get notFor => pick('不适合', 'Not for');
  String get steps => pick('步骤', 'Steps');
  String get startPractice => pick('开始练习', 'Start practice');
  String get backToToday => pick('返回首页', 'Back to home');
  String get submit => pick('提交', 'Submit');
  String get yourAnswer => pick('你的答案', 'Your answer');
  String get delete => pick('删除', 'Delete');
  String get undo => pick('回退', 'Undo');
  String get notQuite => pick('还不对', 'Not quite');
  String get correct => pick('正确', 'Correct');
  String get wrong => pick('错误', 'Wrong');
  String get previousProblem => pick('上一题', 'Previous');
  String get nextProblem => pick('下一题', 'Next');
  String get working => pick('请稍候', 'Working');
  String get mastered => pick('已掌握', 'Mastered');
  String get timeLeft => pick('剩余时间', 'Time left');
  String get elapsed => pick('总用时', 'Total time');
  String get problemsLeft => pick('剩余题数', 'Problems left');
  String get clockStopped =>
      pick('计时已暂停。同一道题还在。', 'The clock is stopped. The same problem is waiting.');
  String nCorrect(int count) => pick('$count 题正确', '$count correct');
  String get newBest => pick('新的个人最好', 'New personal best');
  String best(int count) => pick('个人最好：$count', 'Personal best: $count');
  String get operationWord => pick('运算', 'Operation');
  String get endRoundBy => pick('这一轮怎么结束', 'End the round by');
  String get appearance => pick('外观', 'Appearance');
  String get system => pick('跟随系统', 'System');
  String get light => pick('浅色', 'Light');
  String get dark => pick('深色', 'Dark');
  String get textSize => pick('字号', 'Text size');
  String get small => pick('小', 'Small');
  String get medium => pick('中', 'Medium');
  String get large => pick('大', 'Large');
  String get languageWord => pick('语言', 'Language');
  String get soundEffects => pick('音效', 'Sound effects');
  String get readProblem => pick('读出题目', 'Read the problem');
  String get readProblemBody => pick(
    '用系统语音读出题目，跟这台设备的语言走。按键保持安静。',
    'The problem is spoken in the device language. Keys stay quiet.',
  );
  String get practiceSettings => pick('练习设置', 'Practice settings');
  String get privacyPolicy => pick('隐私政策', 'Privacy policy');
  String get deleteAll => pick('删除这台设备上的全部数据', 'Delete all data on this device');
  String get parentCode => pick('家长密码', 'Parent code');
  String get takePhoto => pick('拍照', 'Take a photo');
  String get choosePhoto => pick('从相册选择', 'Choose a photo');
  String get practiceFive => pick('再练 5 题', 'Practice 5 more');
  String get home => pick('首页', 'Home');
  String get practice => pick('练习', 'Practice');
  String get me => pick('我的', 'Me');
  String get cancel => pick('取消', 'Cancel');
  String masteredTitle(String title) =>
      pick('已掌握 $title', 'Mastered $title');
  String speedBestTitle(int count) =>
      pick('速算个人最好：$count 题正确', 'Speed Drill personal best: $count correct');
}

class CopyDelegate extends LocalizationsDelegate<Copy> {
  const CopyDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'zh' || locale.languageCode == 'en';

  @override
  Future<Copy> load(Locale locale) async => Copy(locale.languageCode);

  @override
  bool shouldReload(CopyDelegate old) => false;
}
