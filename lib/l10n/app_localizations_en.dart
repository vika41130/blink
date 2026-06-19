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
  String get autoDeleteGuide => 'Chat messages auto-delete after 1 minute or a set duration.';

  @override
  String get userNameGuide => 'Username: 3–40 chars, letters/digits/underscores.';

  @override
  String get pinGuide => 'Pin: 4 digits.';

  @override
  String get toggleGuide => 'Toggle: sign in / sign up.';

  @override
  String get easyAccountGuide => 'Easily create an account.';

  @override
  String get userNameNotExisting => 'Username does not exist.';

  @override
  String get pinNotCorrect => 'Pin is incorrect.';

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
  String get saveToGallery => 'Saved to gallery.';

  @override
  String get saveToGalleryButton => 'Save to gallery';

  @override
  String get failedToSaveQRCode => 'Failed to save.';

  @override
  String get contactSavedSuccessfully => 'Saved';

  @override
  String get failedToSaveContact => 'Failed to save contact.';

  @override
  String get contactAlreadyAdded => 'Contact already added.';

  @override
  String get contactNotAdded => 'Contact not added.';

  @override
  String get contactRemovedSuccessfully => 'Removed';

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
  String get touchTextMessage => 'Touch text message to show menu';

  @override
  String get touchImageFullScreen => 'Touch image to view full screen';

  @override
  String get blockChat => 'Block chat';

  @override
  String get unblockChat => 'Unblock chat';

  @override
  String get contactsPincodeDuration => 'Contacts pin duration';

  @override
  String get defaultDurationInfo => 'Default: 6h';

  @override
  String get durationUpdated => 'Saved';

  @override
  String get done => 'Done';
}
