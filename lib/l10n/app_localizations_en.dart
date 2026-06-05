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

  @override
  String get searchContact => 'Search contact';

  @override
  String get searchUsername => 'Search username';

  @override
  String get cannotChatWithYourself => 'Cannot chat with yourself.';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get failedToReadQRCode => 'Failed to read QR code.';

  @override
  String get noQRCodeDetected => 'No QR code detected.';

  @override
  String get saving => 'Saving...';

  @override
  String get saveToGallery => 'Save to Gallery';

  @override
  String get failedToSaveQRCode => 'Failed to save QR Code.';

  @override
  String get qrCodeSaved => 'QR Code saved to Gallery!';

  @override
  String get noUserFound => 'No user found.';

  @override
  String get contactSavedSuccessfully => 'Contact saved successfully.';

  @override
  String get failedToSaveContact => 'Failed to save contact.';

  @override
  String get contactAlreadyAdded => 'Contact already added.';

  @override
  String get contactNotAdded => 'Contact not added.';

  @override
  String get contactRemovedSuccessfully => 'Contact removed successfully.';

  @override
  String get failedToRemoveContact => 'Failed to remove contact.';

  @override
  String get contactTitle => 'Contacts';

  @override
  String get cameraPermissionDenied => 'Camera permission is required.';

  @override
  String get openSettings => 'Open settings';
}
