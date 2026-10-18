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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @allProfileSlotsAreInUse.
  ///
  /// In en, this message translates to:
  /// **'All 10 profile slots are in use. Remove a local profile before adding another.'**
  String get allProfileSlotsAreInUse;

  /// No description provided for @chooseADifferentNameThatAccount.
  ///
  /// In en, this message translates to:
  /// **'Choose a different name. That account label is already in use.'**
  String get chooseADifferentNameThatAccount;

  /// No description provided for @useANameBetweenAndCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use a name between 1 and 40 characters.'**
  String get useANameBetweenAndCharacters;

  /// No description provided for @thisBrowserProviderDoesNotSupport.
  ///
  /// In en, this message translates to:
  /// **'This browser provider does not support isolated profiles and cleanup. Check compatibility details.'**
  String get thisBrowserProviderDoesNotSupport;

  /// No description provided for @unlockProfileDeskBeforeOpeningAn.
  ///
  /// In en, this message translates to:
  /// **'Unlock Profile Desk before opening an account.'**
  String get unlockProfileDeskBeforeOpeningAn;

  /// No description provided for @finishOrCancelTheOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Finish or cancel the open file picker before switching accounts.'**
  String get finishOrCancelTheOpenFile;

  /// No description provided for @thisProfileSStorageIsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This profile’s storage is unavailable. Review the account and relink when ready.'**
  String get thisProfileSStorageIsUnavailable;

  /// No description provided for @localAccessIsBlockedCleanupIs.
  ///
  /// In en, this message translates to:
  /// **'Local access is blocked. Cleanup is still pending; retry it in account management.'**
  String get localAccessIsBlockedCleanupIs;

  /// No description provided for @setUpDeviceAuthenticationInSystem.
  ///
  /// In en, this message translates to:
  /// **'Set up device authentication in system settings, then try again.'**
  String get setUpDeviceAuthenticationInSystem;

  /// No description provided for @theOperationDidNotFinishIn.
  ///
  /// In en, this message translates to:
  /// **'The operation did not finish in time. Its result is uncertain; refresh account management before trying again.'**
  String get theOperationDidNotFinishIn;

  /// No description provided for @thisActionCouldNotFinishYour.
  ///
  /// In en, this message translates to:
  /// **'This action could not finish. Your other profiles are preserved. Try again or check compatibility details.'**
  String get thisActionCouldNotFinishYour;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @beforeYouSwitch.
  ///
  /// In en, this message translates to:
  /// **'Before you switch'**
  String get beforeYouSwitch;

  /// No description provided for @switchingClosesTheCurrentWebPage.
  ///
  /// In en, this message translates to:
  /// **'Switching closes the current web page. Unsent drafts, scroll position and ongoing page activity may be lost. Finish any message or file action first.'**
  String get switchingClosesTheCurrentWebPage;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccount;

  /// No description provided for @aFileActionIsOpen.
  ///
  /// In en, this message translates to:
  /// **'A file action is open'**
  String get aFileActionIsOpen;

  /// No description provided for @cancelTheCurrentFileActionBefore.
  ///
  /// In en, this message translates to:
  /// **'Cancel the current file action before switching. The file will not be delivered to the next account.'**
  String get cancelTheCurrentFileActionBefore;

  /// No description provided for @cancelFileAndSwitch.
  ///
  /// In en, this message translates to:
  /// **'Cancel file and switch'**
  String get cancelFileAndSwitch;

  /// No description provided for @privacyAppearance.
  ///
  /// In en, this message translates to:
  /// **'Privacy & appearance'**
  String get privacyAppearance;

  /// No description provided for @localAccessYourControl.
  ///
  /// In en, this message translates to:
  /// **'Local access.\nYour control.'**
  String get localAccessYourControl;

  /// No description provided for @anyoneWhoCanUnlockThisApp.
  ///
  /// In en, this message translates to:
  /// **'Anyone who can unlock this app can access every saved profile. Device authentication protects access to the app; it does not create separate identities for each account.'**
  String get anyoneWhoCanUnlockThisApp;

  /// No description provided for @requireDeviceAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Require device authentication'**
  String get requireDeviceAuthentication;

  /// No description provided for @lockWhenTheAppLeavesThe.
  ///
  /// In en, this message translates to:
  /// **'Lock when the app leaves the foreground.'**
  String get lockWhenTheAppLeavesThe;

  /// No description provided for @setUpSupportedAuthenticationInDevice.
  ///
  /// In en, this message translates to:
  /// **'Set up supported authentication in device settings first.'**
  String get setUpSupportedAuthenticationInDevice;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @deviceSetting.
  ///
  /// In en, this message translates to:
  /// **'Device setting'**
  String get deviceSetting;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @whatStaysOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'What stays on this device'**
  String get whatStaysOnThisDevice;

  /// No description provided for @profileNamesPreferencesAndBrowserSessions.
  ///
  /// In en, this message translates to:
  /// **'Profile names, preferences and browser sessions are stored locally. You can explicitly export account names and appearance as a setup file. There is no app-owned messaging server or chat backup. The embedded website communicates with its service providers.'**
  String get profileNamesPreferencesAndBrowserSessions;

  /// No description provided for @backgroundProtection.
  ///
  /// In en, this message translates to:
  /// **'Background protection'**
  String get backgroundProtection;

  /// No description provided for @aNativePrivacyCoverHidesAccount.
  ///
  /// In en, this message translates to:
  /// **'A native privacy cover hides account content when the app leaves the foreground. This is not a promise that screenshots or recordings can always be prevented.'**
  String get aNativePrivacyCoverHidesAccount;

  /// No description provided for @permissionsAndFiles.
  ///
  /// In en, this message translates to:
  /// **'Permissions and files'**
  String get permissionsAndFiles;

  /// No description provided for @fileAccessIsRequestedWhenYou.
  ///
  /// In en, this message translates to:
  /// **'File access is requested when you choose a file. Camera and microphone actions stay unavailable until their actual flows are validated. Files you explicitly save or share elsewhere are not removed when a profile is deleted.'**
  String get fileAccessIsRequestedWhenYou;

  /// No description provided for @reviewAndShareSafeDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Review and share safe diagnostics'**
  String get reviewAndShareSafeDiagnostics;

  /// No description provided for @diagnosticsContainTechnicalVersionsCapabilityFlags.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics contain technical versions, capability flags and error categories. They exclude account names, messages, phone numbers, QR values and attachment paths.'**
  String get diagnosticsContainTechnicalVersionsCapabilityFlags;

  /// No description provided for @yourAccountsAreLocked.
  ///
  /// In en, this message translates to:
  /// **'Your accounts are locked'**
  String get yourAccountsAreLocked;

  /// No description provided for @useDeviceAuthenticationToReturnTo.
  ///
  /// In en, this message translates to:
  /// **'Use device authentication to return to your workspace.'**
  String get useDeviceAuthenticationToReturnTo;

  /// No description provided for @authenticationDidNotCompleteYourAccounts.
  ///
  /// In en, this message translates to:
  /// **'Authentication did not complete. Your accounts remain covered.'**
  String get authenticationDidNotCompleteYourAccounts;

  /// No description provided for @authenticationIsUnavailableCheckDeviceSettings.
  ///
  /// In en, this message translates to:
  /// **'Authentication is unavailable. Check device settings and try again.'**
  String get authenticationIsUnavailableCheckDeviceSettings;

  /// No description provided for @authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating…'**
  String get authenticating;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @profileDesk.
  ///
  /// In en, this message translates to:
  /// **'Profile Desk'**
  String get profileDesk;

  /// No description provided for @selectAccountValue.
  ///
  /// In en, this message translates to:
  /// **'Select account. {value1}'**
  String selectAccountValue(String value1);

  /// No description provided for @yourAccounts.
  ///
  /// In en, this message translates to:
  /// **'Your accounts'**
  String get yourAccounts;

  /// No description provided for @lockApp.
  ///
  /// In en, this message translates to:
  /// **'Lock app'**
  String get lockApp;

  /// No description provided for @appMenu.
  ///
  /// In en, this message translates to:
  /// **'App menu'**
  String get appMenu;

  /// No description provided for @reloadThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Reload this account?'**
  String get reloadThisAccount;

  /// No description provided for @reloadingClosesTheCurrentPageAnd.
  ///
  /// In en, this message translates to:
  /// **'Reloading closes the current page and can lose unsent drafts. If a previous send is uncertain, check its status on the official page before sending again.'**
  String get reloadingClosesTheCurrentPageAnd;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage accounts'**
  String get manageAccounts;

  /// No description provided for @reloadSelectedPage.
  ///
  /// In en, this message translates to:
  /// **'Reload selected page'**
  String get reloadSelectedPage;

  /// No description provided for @helpCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Help & compatibility'**
  String get helpCompatibility;

  /// No description provided for @couldnTStartTheSessionEngine.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start the session engine'**
  String get couldnTStartTheSessionEngine;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @thisBrowserNeedsAnUpdate.
  ///
  /// In en, this message translates to:
  /// **'This browser needs an update'**
  String get thisBrowserNeedsAnUpdate;

  /// No description provided for @isolatedProfilesAndScopedCleanupAre.
  ///
  /// In en, this message translates to:
  /// **'Isolated profiles and scoped cleanup are required on this device. Existing profiles remain protected.'**
  String get isolatedProfilesAndScopedCleanupAre;

  /// No description provided for @compatibilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Compatibility details'**
  String get compatibilityDetails;

  /// No description provided for @thisAccountNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'This account needs attention'**
  String get thisAccountNeedsAttention;

  /// No description provided for @anEarlierOperationIsStillBeing.
  ///
  /// In en, this message translates to:
  /// **'An earlier operation is still being reconciled. Keep this account covered until it finishes, or restart the app.'**
  String get anEarlierOperationIsStillBeing;

  /// No description provided for @thePageCouldNotFinishOpening.
  ///
  /// In en, this message translates to:
  /// **'The page could not finish opening. Check the connection, then retry. Other saved accounts are preserved.'**
  String get thePageCouldNotFinishOpening;

  /// No description provided for @retryThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Retry this account'**
  String get retryThisAccount;

  /// No description provided for @openingValue.
  ///
  /// In en, this message translates to:
  /// **'Opening {value1}'**
  String openingValue(String value1);

  /// No description provided for @preparingThisAccountSSeparateBrowser.
  ///
  /// In en, this message translates to:
  /// **'Preparing this account’s separate browser session.'**
  String get preparingThisAccountSSeparateBrowser;

  /// No description provided for @linkWithYourPrimaryPhoneThen.
  ///
  /// In en, this message translates to:
  /// **'Link with your primary phone, then check the account shown.'**
  String get linkWithYourPrimaryPhoneThen;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @yourAccountsKeptSeparate.
  ///
  /// In en, this message translates to:
  /// **'Your accounts,\nkept separate.'**
  String get yourAccountsKeptSeparate;

  /// No description provided for @aQuietWorkspaceForUpTo.
  ///
  /// In en, this message translates to:
  /// **'A quiet workspace for up to ten separately linked accounts. Choose one at a time from the selector above.'**
  String get aQuietWorkspaceForUpTo;

  /// No description provided for @separateSessions.
  ///
  /// In en, this message translates to:
  /// **'Separate sessions'**
  String get separateSessions;

  /// No description provided for @eachProfileHasItsOwnPersistent.
  ///
  /// In en, this message translates to:
  /// **'Each profile has its own persistent browser storage on this device.'**
  String get eachProfileHasItsOwnPersistent;

  /// No description provided for @linkWithYourPrimaryPhone.
  ///
  /// In en, this message translates to:
  /// **'Link with your primary phone'**
  String get linkWithYourPrimaryPhone;

  /// No description provided for @accountOwnersApproveLinkingInThe.
  ///
  /// In en, this message translates to:
  /// **'Account owners approve linking in the official WhatsApp app. A separate device is normally needed to scan the QR.'**
  String get accountOwnersApproveLinkingInThe;

  /// No description provided for @oneAccountOpenAtATime.
  ///
  /// In en, this message translates to:
  /// **'One account open at a time'**
  String get oneAccountOpenAtATime;

  /// No description provided for @inactiveAccountsAreNotMonitoredSwitching.
  ///
  /// In en, this message translates to:
  /// **'Inactive accounts are not monitored. Switching may lose drafts or other temporary page activity.'**
  String get inactiveAccountsAreNotMonitoredSwitching;

  /// No description provided for @setUpYourWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Set up your workspace'**
  String get setUpYourWorkspace;

  /// No description provided for @independentCompanionPrototypeEmbeddedServiceCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Independent companion prototype. Embedded service compatibility and distribution permission are being validated. Use only accounts you are authorized to access.'**
  String get independentCompanionPrototypeEmbeddedServiceCompatibility;

  /// No description provided for @aPlaceForEveryAccount.
  ///
  /// In en, this message translates to:
  /// **'A place for every account'**
  String get aPlaceForEveryAccount;

  /// No description provided for @chooseYourWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Choose your workspace'**
  String get chooseYourWorkspace;

  /// No description provided for @startWithOneAccountGiveIt.
  ///
  /// In en, this message translates to:
  /// **'Start with one account. Give it a name, then link it using the official page. You can add up to ten separate profiles.'**
  String get startWithOneAccountGiveIt;

  /// No description provided for @yourSavedProfilesAreReadyTo.
  ///
  /// In en, this message translates to:
  /// **'Your saved profiles are ready to select. Each opens in its own browser context.'**
  String get yourSavedProfilesAreReadyTo;

  /// No description provided for @linkYourFirstAccount.
  ///
  /// In en, this message translates to:
  /// **'Link your first account'**
  String get linkYourFirstAccount;

  /// No description provided for @selectAccount.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get selectAccount;

  /// No description provided for @settingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up'**
  String get settingUp;

  /// No description provided for @removalPending.
  ///
  /// In en, this message translates to:
  /// **'Removal pending'**
  String get removalPending;

  /// No description provided for @storageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Storage unavailable'**
  String get storageUnavailable;

  /// No description provided for @needsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get needsReview;

  /// No description provided for @userConfirmed.
  ///
  /// In en, this message translates to:
  /// **'User confirmed'**
  String get userConfirmed;

  /// No description provided for @relinkRequested.
  ///
  /// In en, this message translates to:
  /// **'Relink requested'**
  String get relinkRequested;

  /// No description provided for @savedLinkingMayBeNeeded.
  ///
  /// In en, this message translates to:
  /// **'Saved · linking may be needed'**
  String get savedLinkingMayBeNeeded;

  /// No description provided for @addAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Add an account'**
  String get addAnAccount;

  /// No description provided for @editAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit account label'**
  String get editAccountLabel;

  /// No description provided for @giveThisProfileANameYou.
  ///
  /// In en, this message translates to:
  /// **'Give this profile a name you will recognize. You’ll link the account on the official website next.'**
  String get giveThisProfileANameYou;

  /// No description provided for @changingThisLabelKeepsTheSame.
  ///
  /// In en, this message translates to:
  /// **'Changing this label keeps the same browser profile and session.'**
  String get changingThisLabelKeepsTheSame;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @forExampleWorkOrPersonal.
  ///
  /// In en, this message translates to:
  /// **'For example, Work or Personal'**
  String get forExampleWorkOrPersonal;

  /// No description provided for @enterAnAccountName.
  ///
  /// In en, this message translates to:
  /// **'Enter an account name.'**
  String get enterAnAccountName;

  /// No description provided for @useCharactersOrFewer.
  ///
  /// In en, this message translates to:
  /// **'Use 40 characters or fewer.'**
  String get useCharactersOrFewer;

  /// No description provided for @thatNameIsAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'That name is already in use.'**
  String get thatNameIsAlreadyInUse;

  /// No description provided for @profileColor.
  ///
  /// In en, this message translates to:
  /// **'Profile color'**
  String get profileColor;

  /// No description provided for @colorValue.
  ///
  /// In en, this message translates to:
  /// **'Color {value1}'**
  String colorValue(String value1);

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @createAndLinkAccount.
  ///
  /// In en, this message translates to:
  /// **'Create and link account'**
  String get createAndLinkAccount;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save label'**
  String get saveLabel;

  /// No description provided for @valueOfAccounts.
  ///
  /// In en, this message translates to:
  /// **'{value1} of 10 accounts'**
  String valueOfAccounts(String value1);

  /// No description provided for @labelsHelpYouFindYourAccounts.
  ///
  /// In en, this message translates to:
  /// **'Labels help you find your accounts. Each profile keeps a separate browser session on this device.'**
  String get labelsHelpYouFindYourAccounts;

  /// No description provided for @noSavedAccountsYet.
  ///
  /// In en, this message translates to:
  /// **'No saved accounts yet.'**
  String get noSavedAccountsYet;

  /// No description provided for @retryPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Retry pending cleanup'**
  String get retryPendingCleanup;

  /// No description provided for @removeAllLocalProfiles.
  ///
  /// In en, this message translates to:
  /// **'Remove all local profiles?'**
  String get removeAllLocalProfiles;

  /// No description provided for @thisBlocksAccessAndRemovesSaved.
  ///
  /// In en, this message translates to:
  /// **'This blocks access and removes saved sessions from this installation. It does not remotely unlink devices or remove exported files.'**
  String get thisBlocksAccessAndRemovesSaved;

  /// No description provided for @removeAll.
  ///
  /// In en, this message translates to:
  /// **'Remove all'**
  String get removeAll;

  /// No description provided for @removeAllLocalProfiles116.
  ///
  /// In en, this message translates to:
  /// **'Remove all local profiles'**
  String get removeAllLocalProfiles116;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **' · Selected'**
  String get selected;

  /// No description provided for @editValue.
  ///
  /// In en, this message translates to:
  /// **'Edit {value1}'**
  String editValue(String value1);

  /// No description provided for @moveValueUp.
  ///
  /// In en, this message translates to:
  /// **'Move {value1} up'**
  String moveValueUp(String value1);

  /// No description provided for @moveValueDown.
  ///
  /// In en, this message translates to:
  /// **'Move {value1} down'**
  String moveValueDown(String value1);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @accountRemoved.
  ///
  /// In en, this message translates to:
  /// **'Account removed'**
  String get accountRemoved;

  /// No description provided for @thisLocalProfileHasBeenRemoved.
  ///
  /// In en, this message translates to:
  /// **'This local profile has been removed.'**
  String get thisLocalProfileHasBeenRemoved;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetails;

  /// No description provided for @localCleanupIsBeingTrackedAccess.
  ///
  /// In en, this message translates to:
  /// **'Local cleanup is being tracked. Access stays blocked until the required steps finish.'**
  String get localCleanupIsBeingTrackedAccess;

  /// No description provided for @replaceUnavailableProfile.
  ///
  /// In en, this message translates to:
  /// **'Replace unavailable profile'**
  String get replaceUnavailableProfile;

  /// No description provided for @createAFreshStoreAfterCleanup.
  ///
  /// In en, this message translates to:
  /// **'Create a fresh store after cleanup. An Android installation restored from backup requires a full app-storage reset in system settings.'**
  String get createAFreshStoreAfterCleanup;

  /// No description provided for @replaceValue.
  ///
  /// In en, this message translates to:
  /// **'Replace “{value1}”?'**
  String replaceValue(String value1);

  /// No description provided for @theUnavailableLocalStoreWillBe.
  ///
  /// In en, this message translates to:
  /// **'The unavailable local store will be removed before a fresh profile is created. Then approve a new link in the primary app. On Android, an untrusted restored installation requires resetting all app storage in system settings first.'**
  String get theUnavailableLocalStoreWillBe;

  /// No description provided for @replaceAndKeepLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace and keep label'**
  String get replaceAndKeepLabel;

  /// No description provided for @pauseAccountSetup.
  ///
  /// In en, this message translates to:
  /// **'Pause account setup'**
  String get pauseAccountSetup;

  /// No description provided for @keepTheReservedProfileForLater.
  ///
  /// In en, this message translates to:
  /// **'Keep the reserved profile for later or remove this local setup.'**
  String get keepTheReservedProfileForLater;

  /// No description provided for @renameOrChangeColor.
  ///
  /// In en, this message translates to:
  /// **'Rename or change color'**
  String get renameOrChangeColor;

  /// No description provided for @confirmTheLinkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Confirm the linked account'**
  String get confirmTheLinkedAccount;

  /// No description provided for @onlyAfterCheckingTheAccountShown.
  ///
  /// In en, this message translates to:
  /// **'Only after checking the account shown on the official page.'**
  String get onlyAfterCheckingTheAccountShown;

  /// No description provided for @haveYouCheckedTheAccount.
  ///
  /// In en, this message translates to:
  /// **'Have you checked the account?'**
  String get haveYouCheckedTheAccount;

  /// No description provided for @confirmThatTheOfficialWebsiteShows.
  ///
  /// In en, this message translates to:
  /// **'Confirm that the official website shows the account you intend to label “{value1}”. This records your confirmation; the app does not inspect its identity.'**
  String confirmThatTheOfficialWebsiteShows(String value1);

  /// No description provided for @iCheckedTheAccount.
  ///
  /// In en, this message translates to:
  /// **'I checked the account'**
  String get iCheckedTheAccount;

  /// No description provided for @openToRelink.
  ///
  /// In en, this message translates to:
  /// **'Open to relink'**
  String get openToRelink;

  /// No description provided for @usesTheExistingProfileWithoutClearing.
  ///
  /// In en, this message translates to:
  /// **'Uses the existing profile without clearing other accounts.'**
  String get usesTheExistingProfileWithoutClearing;

  /// No description provided for @resetLocalPermissions.
  ///
  /// In en, this message translates to:
  /// **'Reset local permissions'**
  String get resetLocalPermissions;

  /// No description provided for @removingThisProfileAffectsLocalAccess.
  ///
  /// In en, this message translates to:
  /// **'Removing this profile affects local access only. To revoke this device, use Linked devices in the primary WhatsApp app. Files saved elsewhere remain there.'**
  String get removingThisProfileAffectsLocalAccess;

  /// No description provided for @removeValue.
  ///
  /// In en, this message translates to:
  /// **'Remove “{value1}”?'**
  String removeValue(String value1);

  /// No description provided for @theLocalSessionWillBeBlocked.
  ///
  /// In en, this message translates to:
  /// **'The local session will be blocked and removed. Other accounts are preserved. Remote unlinking is a separate action in the primary app.'**
  String get theLocalSessionWillBeBlocked;

  /// No description provided for @removeLocalProfile.
  ///
  /// In en, this message translates to:
  /// **'Remove local profile'**
  String get removeLocalProfile;

  /// No description provided for @pauseThisSetup.
  ///
  /// In en, this message translates to:
  /// **'Pause this setup?'**
  String get pauseThisSetup;

  /// No description provided for @keepForLaterReservesThisAccount.
  ///
  /// In en, this message translates to:
  /// **'Keep for later reserves this account slot and its browser data. Remove local setup blocks access and frees the slot only after cleanup succeeds. It does not remotely unlink a device.'**
  String get keepForLaterReservesThisAccount;

  /// No description provided for @keepForLater.
  ///
  /// In en, this message translates to:
  /// **'Keep for later'**
  String get keepForLater;

  /// No description provided for @removeLocalSetup.
  ///
  /// In en, this message translates to:
  /// **'Remove local setup'**
  String get removeLocalSetup;

  /// No description provided for @linkWithTheOfficialApp.
  ///
  /// In en, this message translates to:
  /// **'Link with the official app'**
  String get linkWithTheOfficialApp;

  /// No description provided for @addAndNameAProfileHere.
  ///
  /// In en, this message translates to:
  /// **'1. Add and name a profile here.\n2. On the primary phone, open WhatsApp → Linked devices → Link a device.\n3. Scan the QR displayed inside this profile.\n4. Check the account shown on the official page, then confirm its label in account details.'**
  String get addAndNameAProfileHere;

  /// No description provided for @usingTheSamePhone.
  ///
  /// In en, this message translates to:
  /// **'Using the same phone'**
  String get usingTheSamePhone;

  /// No description provided for @youCannotScanAQROn.
  ///
  /// In en, this message translates to:
  /// **'You cannot scan a QR on the same screen with that phone’s camera. Use a separate primary device. Phone-number linking is not yet a supported promise in this embedded client. A QR opened in another browser links that browser, not this profile.'**
  String get youCannotScanAQROn;

  /// No description provided for @savedDoesNotMeanConnected.
  ///
  /// In en, this message translates to:
  /// **'Saved does not mean connected'**
  String get savedDoesNotMeanConnected;

  /// No description provided for @onlyTheSelectedAccountHasA.
  ///
  /// In en, this message translates to:
  /// **'Only the selected account has a live web view. Inactive profiles are not monitored and do not provide reliable notifications or unread counts. Switching may lose unsent drafts and temporary page activity. Ten slots are this app’s capacity; each account’s linked-device allowance still applies.'**
  String get onlyTheSelectedAccountHasA;

  /// No description provided for @whenSomethingStopsWorking.
  ///
  /// In en, this message translates to:
  /// **'When something stops working'**
  String get whenSomethingStopsWorking;

  /// No description provided for @checkYourConnectionAndReloadThe.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and reload the affected profile. If a send’s status is uncertain, inspect it on the official page before sending again. A service outage is not a reason to remove all profiles. If storage is lost or the primary phone revokes access, link that profile again.'**
  String get checkYourConnectionAndReloadThe;

  /// No description provided for @removeAccessRemotely.
  ///
  /// In en, this message translates to:
  /// **'Remove access remotely'**
  String get removeAccessRemotely;

  /// No description provided for @inThePrimaryWhatsAppAppOpen.
  ///
  /// In en, this message translates to:
  /// **'In the primary WhatsApp app, open Linked devices and log out the relevant device. Removing a local profile here does not prove remote unlinking, especially offline. Never send support a QR, pairing code, session export or private conversation.'**
  String get inThePrimaryWhatsAppAppOpen;

  /// No description provided for @officialLinkingHelp.
  ///
  /// In en, this message translates to:
  /// **'Official linking help'**
  String get officialLinkingHelp;

  /// No description provided for @officialLinkedDeviceHelp.
  ///
  /// In en, this message translates to:
  /// **'Official linked-device help'**
  String get officialLinkedDeviceHelp;

  /// No description provided for @officialConnectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Official connection help'**
  String get officialConnectionHelp;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @browserProvider.
  ///
  /// In en, this message translates to:
  /// **'Browser provider'**
  String get browserProvider;

  /// No description provided for @isolatedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Isolated profiles'**
  String get isolatedProfiles;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @scopedCleanup.
  ///
  /// In en, this message translates to:
  /// **'Scoped cleanup'**
  String get scopedCleanup;

  /// No description provided for @nativeDownloads.
  ///
  /// In en, this message translates to:
  /// **'Native downloads'**
  String get nativeDownloads;

  /// No description provided for @availablePathsRequireServiceValidation.
  ///
  /// In en, this message translates to:
  /// **'Available paths require service validation'**
  String get availablePathsRequireServiceValidation;

  /// No description provided for @notSupportedByThisEngine.
  ///
  /// In en, this message translates to:
  /// **'Not supported by this engine'**
  String get notSupportedByThisEngine;

  /// No description provided for @cameraMicrophoneAndCalls.
  ///
  /// In en, this message translates to:
  /// **'Camera, microphone and calls'**
  String get cameraMicrophoneAndCalls;

  /// No description provided for @notEnabled.
  ///
  /// In en, this message translates to:
  /// **'Not enabled'**
  String get notEnabled;

  /// No description provided for @profileDeskIsAnIndependentCompanion.
  ///
  /// In en, this message translates to:
  /// **'Profile Desk is an independent companion prototype. Actual embedded WhatsApp compatibility, ten linked accounts, retention and distribution permission remain separate validation gates.'**
  String get profileDeskIsAnIndependentCompanion;

  /// No description provided for @shareSafeDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Share safe diagnostics'**
  String get shareSafeDiagnostics;

  /// No description provided for @noAccountSelected.
  ///
  /// In en, this message translates to:
  /// **'No account selected'**
  String get noAccountSelected;

  /// No description provided for @restoreQuarantined.
  ///
  /// In en, this message translates to:
  /// **'This restored installation cannot safely reopen saved sessions. On Android, reset this app’s storage in system settings, then create fresh profiles and link again. Exported files are not removed by this reset.'**
  String get restoreQuarantined;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicenses;

  /// No description provided for @networkOffline.
  ///
  /// In en, this message translates to:
  /// **'No network connection. Your saved profiles are kept.'**
  String get networkOffline;

  /// No description provided for @fileActionInProgress.
  ///
  /// In en, this message translates to:
  /// **'File action in progress'**
  String get fileActionInProgress;

  /// No description provided for @fileProgress.
  ///
  /// In en, this message translates to:
  /// **'File transfer: {percent}%'**
  String fileProgress(String percent);

  /// No description provided for @cancelFileAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel file action'**
  String get cancelFileAction;

  /// No description provided for @networkPath.
  ///
  /// In en, this message translates to:
  /// **'Network path'**
  String get networkPath;

  /// No description provided for @networkUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not established'**
  String get networkUnknown;

  /// No description provided for @networkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get networkDisconnected;

  /// No description provided for @networkPathAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available. Service connectivity is checked by the page.'**
  String get networkPathAvailable;

  /// No description provided for @linkingStepCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Add and name a profile here.'**
  String get linkingStepCreateProfile;

  /// No description provided for @linkingStepOpenDevices.
  ///
  /// In en, this message translates to:
  /// **'On the primary phone, open WhatsApp → Linked devices → Link a device.'**
  String get linkingStepOpenDevices;

  /// No description provided for @linkingStepScanProfile.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR displayed inside this profile.'**
  String get linkingStepScanProfile;

  /// No description provided for @linkingStepConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Check the account shown on the official page, then confirm its label in account details.'**
  String get linkingStepConfirmLabel;

  /// No description provided for @workspaceChatsMenu.
  ///
  /// In en, this message translates to:
  /// **'Chats & menu'**
  String get workspaceChatsMenu;

  /// No description provided for @workspaceOriginalLayout.
  ///
  /// In en, this message translates to:
  /// **'Original layout'**
  String get workspaceOriginalLayout;

  /// No description provided for @workspacePhoneLayout.
  ///
  /// In en, this message translates to:
  /// **'Phone layout'**
  String get workspacePhoneLayout;

  /// No description provided for @accountSetupBackup.
  ///
  /// In en, this message translates to:
  /// **'Account setup backup'**
  String get accountSetupBackup;

  /// No description provided for @accountSetupHeading.
  ///
  /// In en, this message translates to:
  /// **'Take your account setup with you'**
  String get accountSetupHeading;

  /// No description provided for @accountSetupDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Back up account names, colors, order and appearance. Chats and signed-in sessions are not included. Each imported account must be linked again.'**
  String get accountSetupDisclosure;

  /// No description provided for @exportAccountSetup.
  ///
  /// In en, this message translates to:
  /// **'Export account setup'**
  String get exportAccountSetup;

  /// No description provided for @importAccountSetup.
  ///
  /// In en, this message translates to:
  /// **'Import account setup'**
  String get importAccountSetup;

  /// No description provided for @accountSetupExportNote.
  ///
  /// In en, this message translates to:
  /// **'Save account names, colors, order and appearance as a readable JSON file. It is not encrypted. Choose a location you trust.'**
  String get accountSetupExportNote;

  /// No description provided for @accountSetupImportNote.
  ///
  /// In en, this message translates to:
  /// **'Preview a Profile Desk setup file and add its accounts to this device. Existing accounts stay in place.'**
  String get accountSetupImportNote;

  /// No description provided for @accountSetupChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose setup file'**
  String get accountSetupChooseFile;

  /// No description provided for @accountSetupPreview.
  ///
  /// In en, this message translates to:
  /// **'Review accounts to import'**
  String get accountSetupPreview;

  /// No description provided for @accountSetupSlots.
  ///
  /// In en, this message translates to:
  /// **'{count} accounts to add · {free} slots available'**
  String accountSetupSlots(String count, String free);

  /// No description provided for @accountSetupName.
  ///
  /// In en, this message translates to:
  /// **'Account {number} name'**
  String accountSetupName(String number);

  /// No description provided for @accountSetupCapacity.
  ///
  /// In en, this message translates to:
  /// **'There is not enough room for this file. No accounts will be replaced. Free up slots in Manage accounts, then try again.'**
  String get accountSetupCapacity;

  /// No description provided for @accountSetupEmpty.
  ///
  /// In en, this message translates to:
  /// **'This setup file contains no accounts.'**
  String get accountSetupEmpty;

  /// No description provided for @accountSetupApplyAppearance.
  ///
  /// In en, this message translates to:
  /// **'Use appearance from this file'**
  String get accountSetupApplyAppearance;

  /// No description provided for @accountSetupKeepLock.
  ///
  /// In en, this message translates to:
  /// **'Your device lock and security preferences stay the same.'**
  String get accountSetupKeepLock;

  /// No description provided for @accountSetupImportAccounts.
  ///
  /// In en, this message translates to:
  /// **'Import accounts'**
  String get accountSetupImportAccounts;

  /// No description provided for @accountSetupImported.
  ///
  /// In en, this message translates to:
  /// **'Added {count} accounts. Open each account and link it with its primary phone.'**
  String accountSetupImported(String count);

  /// No description provided for @accountSetupExported.
  ///
  /// In en, this message translates to:
  /// **'Account setup file saved. Signed-in sessions were not exported.'**
  String get accountSetupExported;

  /// No description provided for @accountSetupInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'This is not a supported Profile Desk account setup file. Choose a version 1 setup file with up to ten accounts.'**
  String get accountSetupInvalidFile;

  /// No description provided for @accountSetupFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'This setup file is too large. Use a Profile Desk setup file smaller than 64 KiB.'**
  String get accountSetupFileTooLarge;

  /// No description provided for @accountSetupFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The setup file could not be opened or saved. Choose a different location and try again.'**
  String get accountSetupFileUnavailable;

  /// No description provided for @nativeMessagingChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get nativeMessagingChats;

  /// No description provided for @nativeMessagingSearch.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get nativeMessagingSearch;

  /// No description provided for @nativeMessagingRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh chats'**
  String get nativeMessagingRefresh;

  /// No description provided for @nativeMessagingOfficial.
  ///
  /// In en, this message translates to:
  /// **'Open official interface'**
  String get nativeMessagingOfficial;

  /// No description provided for @nativeMessagingBack.
  ///
  /// In en, this message translates to:
  /// **'Back to chats'**
  String get nativeMessagingBack;

  /// No description provided for @nativeMessagingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No chats to show'**
  String get nativeMessagingEmpty;

  /// No description provided for @nativeMessagingEmptyDetail.
  ///
  /// In en, this message translates to:
  /// **'Your available conversations will appear here.'**
  String get nativeMessagingEmptyDetail;

  /// No description provided for @nativeMessagingNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching chats'**
  String get nativeMessagingNoResults;

  /// No description provided for @nativeMessagingNoResultsDetail.
  ///
  /// In en, this message translates to:
  /// **'Try another name.'**
  String get nativeMessagingNoResultsDetail;

  /// No description provided for @nativeMessagingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading chats…'**
  String get nativeMessagingLoading;

  /// No description provided for @nativeMessagingLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Loading messages…'**
  String get nativeMessagingLoadingMessages;

  /// No description provided for @nativeMessagingLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Chats could not be loaded'**
  String get nativeMessagingLoadFailed;

  /// No description provided for @nativeMessagingMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Messages could not be loaded'**
  String get nativeMessagingMessageFailed;

  /// No description provided for @nativeMessagingTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get nativeMessagingTryAgain;

  /// No description provided for @nativeMessagingLink.
  ///
  /// In en, this message translates to:
  /// **'Link your account'**
  String get nativeMessagingLink;

  /// No description provided for @nativeMessagingLinkDetail.
  ///
  /// In en, this message translates to:
  /// **'Open the official interface to scan the QR code with your primary phone.'**
  String get nativeMessagingLinkDetail;

  /// No description provided for @nativeMessagingLocked.
  ///
  /// In en, this message translates to:
  /// **'Your conversation is protected'**
  String get nativeMessagingLocked;

  /// No description provided for @nativeMessagingLockedDetail.
  ///
  /// In en, this message translates to:
  /// **'Unlock your account to continue.'**
  String get nativeMessagingLockedDetail;

  /// No description provided for @nativeMessagingOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get nativeMessagingOffline;

  /// No description provided for @nativeMessagingOfflineDetail.
  ///
  /// In en, this message translates to:
  /// **'Reconnect, then refresh your chats.'**
  String get nativeMessagingOfflineDetail;

  /// No description provided for @nativeMessagingUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Native chats are unavailable'**
  String get nativeMessagingUnsupported;

  /// No description provided for @nativeMessagingUnsupportedDetail.
  ///
  /// In en, this message translates to:
  /// **'Continue in the official interface for this account.'**
  String get nativeMessagingUnsupportedDetail;

  /// No description provided for @nativeMessagingMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get nativeMessagingMessage;

  /// No description provided for @nativeMessagingSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get nativeMessagingSend;

  /// No description provided for @nativeMessagingSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get nativeMessagingSending;

  /// No description provided for @nativeMessagingAccepted.
  ///
  /// In en, this message translates to:
  /// **'Submitted to WhatsApp. Delivery is not yet confirmed.'**
  String get nativeMessagingAccepted;

  /// No description provided for @nativeMessagingRejected.
  ///
  /// In en, this message translates to:
  /// **'This message was not sent. Your draft is ready to edit or send again.'**
  String get nativeMessagingRejected;

  /// No description provided for @nativeMessagingUncertain.
  ///
  /// In en, this message translates to:
  /// **'Send status is unknown. Check the official conversation before composing again.'**
  String get nativeMessagingUncertain;

  /// No description provided for @nativeMessagingClearUncertain.
  ///
  /// In en, this message translates to:
  /// **'I checked · clear draft'**
  String get nativeMessagingClearUncertain;

  /// No description provided for @nativeMessagingReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This conversation is read-only here. Open the official interface for available actions.'**
  String get nativeMessagingReadOnly;

  /// No description provided for @nativeMessagingUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'View this content in the official interface'**
  String get nativeMessagingUnsupportedMessage;

  /// No description provided for @nativeMessagingHistory.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get nativeMessagingHistory;

  /// No description provided for @nativeMessagingHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Earlier messages could not be loaded.'**
  String get nativeMessagingHistoryFailed;

  /// No description provided for @nativeMessagingPartialHistory.
  ///
  /// In en, this message translates to:
  /// **'Only supported, available messages are shown. Open the official interface for complete conversation features.'**
  String get nativeMessagingPartialHistory;

  /// No description provided for @nativeMessagingNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No supported messages to show'**
  String get nativeMessagingNoMessages;

  /// No description provided for @nativeMessagingPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get nativeMessagingPending;

  /// No description provided for @nativeMessagingSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get nativeMessagingSent;

  /// No description provided for @nativeMessagingDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get nativeMessagingDelivered;

  /// No description provided for @nativeMessagingRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get nativeMessagingRead;

  /// No description provided for @nativeMessagingFailed.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get nativeMessagingFailed;

  /// No description provided for @nativeMessagingUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get nativeMessagingUnread;

  /// No description provided for @nativeMessagingDraftLimit.
  ///
  /// In en, this message translates to:
  /// **'Messages can contain up to 4,096 characters.'**
  String get nativeMessagingDraftLimit;

  /// No description provided for @workspacePresentationListShown.
  ///
  /// In en, this message translates to:
  /// **'Chat list opened.'**
  String get workspacePresentationListShown;

  /// No description provided for @workspacePresentationMenuBackHint.
  ///
  /// In en, this message translates to:
  /// **'Use Back inside the open WhatsApp panel to return to chats.'**
  String get workspacePresentationMenuBackHint;

  /// No description provided for @workspacePresentationDetailUnchanged.
  ///
  /// In en, this message translates to:
  /// **'This conversation is still open. Try Original layout to reach its controls.'**
  String get workspacePresentationDetailUnchanged;

  /// No description provided for @workspacePresentationOriginalSelected.
  ///
  /// In en, this message translates to:
  /// **'Original layout selected.'**
  String get workspacePresentationOriginalSelected;

  /// No description provided for @workspacePresentationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Phone layout is unavailable for this page. Use Original layout to continue.'**
  String get workspacePresentationUnavailable;

  /// No description provided for @workspacePresentationCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The page layout could not be checked. Try Original layout.'**
  String get workspacePresentationCheckFailed;

  /// No description provided for @workspacePresentationBackCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'The page could not be checked. Try Back again.'**
  String get workspacePresentationBackCheckFailed;

  /// No description provided for @workspacePresentationUseOriginal.
  ///
  /// In en, this message translates to:
  /// **'Use Original layout'**
  String get workspacePresentationUseOriginal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
