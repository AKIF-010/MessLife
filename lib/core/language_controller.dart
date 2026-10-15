import 'package:flutter/material.dart';
import 'app_strings.dart';

class LanguageController extends ChangeNotifier {
  String _code = 'en';

  String get code => _code;
  bool get isBangla => _code == 'bn';

  void setLanguage(String code) {
    if (code == _code) return;
    _code = code;
    notifyListeners();
  }
}

/// Place above MaterialApp so every route can read the language.
class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'LanguageScope not found above this context');
    return scope!.notifier!;
  }
}

extension TranslateX on BuildContext {
  /// Usage: context.tr('signIn')
  String tr(String key) => AppStrings.of(LanguageScope.of(this).code, key);
}