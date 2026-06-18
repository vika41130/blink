// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get authTitle => 'Auth';

  @override
  String get aboutContent => 'We don\'t store chat history. Messages will be removed after one minute.';

  @override
  String get userNameGuide => 'Username must be 3 to 40 characters long, containing only digits, letters, or underscores.';

  @override
  String get pinGuide => 'Pin must be four digits.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get userNameNotExisting => 'Username does not exist.';

  @override
  String get pinNotCorrect => 'Pin is incorrect.';

  @override
  String get signInSuccess => 'Signed in successfully. Going in...';

  @override
  String get createUserSuccess => 'New user created successfully. Going in...';

  @override
  String get signUpFailed => 'Sign up failed.';

  @override
  String get homeTitle => 'Vapor';

  @override
  String get userNameAlreadyExisted => 'Username already exists.';

  @override
  String get cannotChatWithYourself => 'You cannot chat with yourself.';

  @override
  String get userNotFound => 'User not found.';

  @override
  String get failedToReadQRCode => 'Failed to read QR code.';

  @override
  String get noQRCodeDetected => 'No QR code detected.';

  @override
  String get saving => 'Saving...';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get failedToSaveQRCode => 'Failed to save QR code.';

  @override
  String get qrCodeSaved => 'QR code saved to gallery!';

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
  String get cameraPermissionDenied => 'Camera permission is required.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get chatSettings => 'Chat settings';

  @override
  String get search => 'Search';

  @override
  String get savedContact => 'Saved contact';

  @override
  String get saveContact => 'Save contact';

  @override
  String get swipeRightToRemove => 'Swipe right to delete';

  @override
  String get tripleTapToBlock => 'Triple-tap title to lock screen';

  @override
  String get blockChat => 'Block chat';

  @override
  String get unblockChat => 'Unblock chat';

  @override
  String get contactsPincodeDuration => 'Pin duration';

  @override
  String get defaultDurationInfo => 'Default: 6h';

  @override
  String get durationUpdated => 'Saved';

  @override
  String get done => 'Done';
}
