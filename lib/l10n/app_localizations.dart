import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Go in'**
  String get authTitle;

  /// No description provided for @aboutContent.
  ///
  /// In en, this message translates to:
  /// **'We don\'t store chat history. Messages will be removed after one minute.'**
  String get aboutContent;

  /// No description provided for @userNameGuide.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3 to 40 characters long, containing only digits, letters, or underscores.'**
  String get userNameGuide;

  /// No description provided for @passcodeGuide.
  ///
  /// In en, this message translates to:
  /// **'Passcode must be four digits.'**
  String get passcodeGuide;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @userNameNotExisting.
  ///
  /// In en, this message translates to:
  /// **'Username does not exist.'**
  String get userNameNotExisting;

  /// No description provided for @passcodeNotCorrect.
  ///
  /// In en, this message translates to:
  /// **'Passcode is incorrect.'**
  String get passcodeNotCorrect;

  /// No description provided for @signInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully. Going in...'**
  String get signInSuccess;

  /// No description provided for @createUserSuccess.
  ///
  /// In en, this message translates to:
  /// **'New user created successfully. Going in...'**
  String get createUserSuccess;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed.'**
  String get signUpFailed;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Vapor'**
  String get homeTitle;

  /// No description provided for @userNameAlreadyExisted.
  ///
  /// In en, this message translates to:
  /// **'Username already exists.'**
  String get userNameAlreadyExisted;

  /// No description provided for @searchContact.
  ///
  /// In en, this message translates to:
  /// **'Search contact'**
  String get searchContact;

  /// No description provided for @searchUsername.
  ///
  /// In en, this message translates to:
  /// **'Search username'**
  String get searchUsername;

  /// No description provided for @cannotChatWithYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot chat with yourself.'**
  String get cannotChatWithYourself;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get userNotFound;

  /// No description provided for @failedToReadQRCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to read QR code.'**
  String get failedToReadQRCode;

  /// No description provided for @noQRCodeDetected.
  ///
  /// In en, this message translates to:
  /// **'No QR code detected.'**
  String get noQRCodeDetected;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGallery;

  /// No description provided for @failedToSaveQRCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to save QR code.'**
  String get failedToSaveQRCode;

  /// No description provided for @qrCodeSaved.
  ///
  /// In en, this message translates to:
  /// **'QR code saved to gallery!'**
  String get qrCodeSaved;

  /// No description provided for @noUserFound.
  ///
  /// In en, this message translates to:
  /// **'No user found.'**
  String get noUserFound;

  /// No description provided for @contactSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact saved successfully.'**
  String get contactSavedSuccessfully;

  /// No description provided for @failedToSaveContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to save contact.'**
  String get failedToSaveContact;

  /// No description provided for @contactAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact already added.'**
  String get contactAlreadyAdded;

  /// No description provided for @contactNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact not added.'**
  String get contactNotAdded;

  /// No description provided for @contactRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contact removed successfully.'**
  String get contactRemovedSuccessfully;

  /// No description provided for @failedToRemoveContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove contact.'**
  String get failedToRemoveContact;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required.'**
  String get cameraPermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @chatSettings.
  ///
  /// In en, this message translates to:
  /// **'Chat settings'**
  String get chatSettings;

  /// No description provided for @savedContact.
  ///
  /// In en, this message translates to:
  /// **'Saved contact'**
  String get savedContact;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContact;

  /// No description provided for @swipeRightToRemove.
  ///
  /// In en, this message translates to:
  /// **'Swipe right the message to remove.'**
  String get swipeRightToRemove;

  /// No description provided for @tripleTapToBlock.
  ///
  /// In en, this message translates to:
  /// **'Triple-tap the title to temporarily block the chat screen.'**
  String get tripleTapToBlock;

  /// No description provided for @blockChat.
  ///
  /// In en, this message translates to:
  /// **'Block chat'**
  String get blockChat;

  /// No description provided for @unblockChat.
  ///
  /// In en, this message translates to:
  /// **'Unblock chat'**
  String get unblockChat;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
