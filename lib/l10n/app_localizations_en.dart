// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authTitle => 'Go in';

  @override
  String get userNameGuide => 'Username has the length from 3 to 40, digit or alphabet or underscore, starts with a letter.';

  @override
  String get passcodeGuide => 'Passcode has four digits.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get userNameNotExisting => 'Username is not existing.';

  @override
  String get passcodeNotCorrect => 'Passcode is not correct.';

  @override
  String get signInSuccess => 'Sign in successfully. Going into...';

  @override
  String get createUserSuccess => 'Creating new user successfully. Going into...';

  @override
  String get signUpFailed => 'Sign up failed.';

  @override
  String get homeTitle => 'Blink';

  @override
  String get userNameAlreadyExisted => 'Username is already exsisted.';
}
