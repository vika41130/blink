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
  /// **'Auth'**
  String get authTitle;

  /// No description provided for @autoDeleteGuide.
  ///
  /// In en, this message translates to:
  /// **'Chat messages auto-delete after 1 minute or a set duration.'**
  String get autoDeleteGuide;

  /// No description provided for @userNameGuide.
  ///
  /// In en, this message translates to:
  /// **'Username: 3–40 chars, letters/digits/underscores.'**
  String get userNameGuide;

  /// No description provided for @pinGuide.
  ///
  /// In en, this message translates to:
  /// **'Pin: 4 digits.'**
  String get pinGuide;

  /// No description provided for @toggleGuide.
  ///
  /// In en, this message translates to:
  /// **'Toggle: sign in / sign up.'**
  String get toggleGuide;

  /// No description provided for @easyAccountGuide.
  ///
  /// In en, this message translates to:
  /// **'Easily create an account.'**
  String get easyAccountGuide;

  /// No description provided for @userNameNotExisting.
  ///
  /// In en, this message translates to:
  /// **'Username does not exist'**
  String get userNameNotExisting;

  /// No description provided for @pinNotCorrect.
  ///
  /// In en, this message translates to:
  /// **'Pin is incorrect'**
  String get pinNotCorrect;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Vapor'**
  String get homeTitle;

  /// No description provided for @userNameAlreadyExisted.
  ///
  /// In en, this message translates to:
  /// **'Username already exists'**
  String get userNameAlreadyExisted;

  /// No description provided for @cannotChatWithYourself.
  ///
  /// In en, this message translates to:
  /// **'You cannot chat with yourself'**
  String get cannotChatWithYourself;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @failedToReadQRCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to read QR code'**
  String get failedToReadQRCode;

  /// No description provided for @noQRCodeDetected.
  ///
  /// In en, this message translates to:
  /// **'No QR code detected'**
  String get noQRCodeDetected;

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get saveToGallery;

  /// No description provided for @saveToGalleryButton.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGalleryButton;

  /// No description provided for @failedToSaveQRCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSaveQRCode;

  /// No description provided for @contactSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved contact'**
  String get contactSavedSuccessfully;

  /// No description provided for @failedToSaveContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to save contact'**
  String get failedToSaveContact;

  /// No description provided for @contactAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact already added'**
  String get contactAlreadyAdded;

  /// No description provided for @contactNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Contact not added'**
  String get contactNotAdded;

  /// No description provided for @contactRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Removed contact'**
  String get contactRemovedSuccessfully;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @chatSettings.
  ///
  /// In en, this message translates to:
  /// **'Chat settings'**
  String get chatSettings;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @removeContact.
  ///
  /// In en, this message translates to:
  /// **'Remove contact'**
  String get removeContact;

  /// No description provided for @saveContact.
  ///
  /// In en, this message translates to:
  /// **'Save contact'**
  String get saveContact;

  /// No description provided for @swipeRightToRemove.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to delete'**
  String get swipeRightToRemove;

  /// No description provided for @tripleTapToBlock.
  ///
  /// In en, this message translates to:
  /// **'Triple-tap title to lock screen'**
  String get tripleTapToBlock;

  /// No description provided for @touchTextMessage.
  ///
  /// In en, this message translates to:
  /// **'Touch text message to show menu'**
  String get touchTextMessage;

  /// No description provided for @touchImageFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Touch image to view full screen'**
  String get touchImageFullScreen;

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

  /// No description provided for @chatBlocked.
  ///
  /// In en, this message translates to:
  /// **'Chat blocked'**
  String get chatBlocked;

  /// No description provided for @chatUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Chat unblocked'**
  String get chatUnblocked;

  /// No description provided for @lockContacts.
  ///
  /// In en, this message translates to:
  /// **'Lock contacts'**
  String get lockContacts;

  /// No description provided for @unlockContact.
  ///
  /// In en, this message translates to:
  /// **'Unlock contact'**
  String get unlockContact;

  /// No description provided for @lockContact.
  ///
  /// In en, this message translates to:
  /// **'Lock contact'**
  String get lockContact;

  /// No description provided for @durationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved duration'**
  String get durationUpdated;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @networkErrorSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Network error, signing out'**
  String get networkErrorSigningOut;

  /// No description provided for @chatIsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Chat is blocked'**
  String get chatIsBlocked;

  /// No description provided for @nicknameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nickname updated'**
  String get nicknameUpdated;

  /// No description provided for @failedToUpdateNickname.
  ///
  /// In en, this message translates to:
  /// **'Failed to update nickname'**
  String get failedToUpdateNickname;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter pin'**
  String get enterPin;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @chatMessageDuration.
  ///
  /// In en, this message translates to:
  /// **'Chat message duration'**
  String get chatMessageDuration;

  /// No description provided for @defaultOneMinute.
  ///
  /// In en, this message translates to:
  /// **'Default: 1 minute'**
  String get defaultOneMinute;

  /// No description provided for @networkErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Network error, check your connection'**
  String get networkErrorConnection;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get goodNight;
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
