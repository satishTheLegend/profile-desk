// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get allProfileSlotsAreInUse =>
      'All 10 profile slots are in use. Remove a local profile before adding another.';

  @override
  String get chooseADifferentNameThatAccount =>
      'Choose a different name. That account label is already in use.';

  @override
  String get useANameBetweenAndCharacters =>
      'Use a name between 1 and 40 characters.';

  @override
  String get thisBrowserProviderDoesNotSupport =>
      'This browser provider does not support isolated profiles and cleanup. Check compatibility details.';

  @override
  String get unlockProfileDeskBeforeOpeningAn =>
      'Unlock Profile Desk before opening an account.';

  @override
  String get finishOrCancelTheOpenFile =>
      'Finish or cancel the open file picker before switching accounts.';

  @override
  String get thisProfileSStorageIsUnavailable =>
      'This profile’s storage is unavailable. Review the account and relink when ready.';

  @override
  String get localAccessIsBlockedCleanupIs =>
      'Local access is blocked. Cleanup is still pending; retry it in account management.';

  @override
  String get setUpDeviceAuthenticationInSystem =>
      'Set up device authentication in system settings, then try again.';

  @override
  String get theOperationDidNotFinishIn =>
      'The operation did not finish in time. Its result is uncertain; refresh account management before trying again.';

  @override
  String get thisActionCouldNotFinishYour =>
      'This action could not finish. Your other profiles are preserved. Try again or check compatibility details.';

  @override
  String get cancel => 'Cancel';

  @override
  String get beforeYouSwitch => 'Before you switch';

  @override
  String get switchingClosesTheCurrentWebPage =>
      'Switching closes the current web page. Unsent drafts, scroll position and ongoing page activity may be lost. Finish any message or file action first.';

  @override
  String get switchAccount => 'Switch account';

  @override
  String get aFileActionIsOpen => 'A file action is open';

  @override
  String get cancelTheCurrentFileActionBefore =>
      'Cancel the current file action before switching. The file will not be delivered to the next account.';

  @override
  String get cancelFileAndSwitch => 'Cancel file and switch';

  @override
  String get privacyAppearance => 'Privacy & appearance';

  @override
  String get localAccessYourControl => 'Local access.\nYour control.';

  @override
  String get anyoneWhoCanUnlockThisApp =>
      'Anyone who can unlock this app can access every saved profile. Device authentication protects access to the app; it does not create separate identities for each account.';

  @override
  String get requireDeviceAuthentication => 'Require device authentication';

  @override
  String get lockWhenTheAppLeavesThe =>
      'Lock when the app leaves the foreground.';

  @override
  String get setUpSupportedAuthenticationInDevice =>
      'Set up supported authentication in device settings first.';

  @override
  String get appearance => 'Appearance';

  @override
  String get deviceSetting => 'Device setting';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get whatStaysOnThisDevice => 'What stays on this device';

  @override
  String get profileNamesPreferencesAndBrowserSessions =>
      'Profile names, preferences and browser sessions are stored locally. You can explicitly export account names and appearance as a setup file. There is no app-owned messaging server or chat backup. The embedded website communicates with its service providers.';

  @override
  String get backgroundProtection => 'Background protection';

  @override
  String get aNativePrivacyCoverHidesAccount =>
      'A native privacy cover hides account content when the app leaves the foreground. This is not a promise that screenshots or recordings can always be prevented.';

  @override
  String get permissionsAndFiles => 'Permissions and files';

  @override
  String get fileAccessIsRequestedWhenYou =>
      'File access is requested when you choose a file. Camera and microphone actions stay unavailable until their actual flows are validated. Files you explicitly save or share elsewhere are not removed when a profile is deleted.';

  @override
  String get reviewAndShareSafeDiagnostics =>
      'Review and share safe diagnostics';

  @override
  String get diagnosticsContainTechnicalVersionsCapabilityFlags =>
      'Diagnostics contain technical versions, capability flags and error categories. They exclude account names, messages, phone numbers, QR values and attachment paths.';

  @override
  String get yourAccountsAreLocked => 'Your accounts are locked';

  @override
  String get useDeviceAuthenticationToReturnTo =>
      'Use device authentication to return to your workspace.';

  @override
  String get authenticationDidNotCompleteYourAccounts =>
      'Authentication did not complete. Your accounts remain covered.';

  @override
  String get authenticationIsUnavailableCheckDeviceSettings =>
      'Authentication is unavailable. Check device settings and try again.';

  @override
  String get authenticating => 'Authenticating…';

  @override
  String get unlock => 'Unlock';

  @override
  String get profileDesk => 'Profile Desk';

  @override
  String selectAccountValue(String value1) {
    return 'Select account. $value1';
  }

  @override
  String get yourAccounts => 'Your accounts';

  @override
  String get lockApp => 'Lock app';

  @override
  String get appMenu => 'App menu';

  @override
  String get reloadThisAccount => 'Reload this account?';

  @override
  String get reloadingClosesTheCurrentPageAnd =>
      'Reloading closes the current page and can lose unsent drafts. If a previous send is uncertain, check its status on the official page before sending again.';

  @override
  String get reload => 'Reload';

  @override
  String get manageAccounts => 'Manage accounts';

  @override
  String get reloadSelectedPage => 'Reload selected page';

  @override
  String get helpCompatibility => 'Help & compatibility';

  @override
  String get couldnTStartTheSessionEngine =>
      'Couldn’t start the session engine';

  @override
  String get tryAgain => 'Try again';

  @override
  String get thisBrowserNeedsAnUpdate => 'This browser needs an update';

  @override
  String get isolatedProfilesAndScopedCleanupAre =>
      'Isolated profiles and scoped cleanup are required on this device. Existing profiles remain protected.';

  @override
  String get compatibilityDetails => 'Compatibility details';

  @override
  String get thisAccountNeedsAttention => 'This account needs attention';

  @override
  String get anEarlierOperationIsStillBeing =>
      'An earlier operation is still being reconciled. Keep this account covered until it finishes, or restart the app.';

  @override
  String get thePageCouldNotFinishOpening =>
      'The page could not finish opening. Check the connection, then retry. Other saved accounts are preserved.';

  @override
  String get retryThisAccount => 'Retry this account';

  @override
  String openingValue(String value1) {
    return 'Opening $value1';
  }

  @override
  String get preparingThisAccountSSeparateBrowser =>
      'Preparing this account’s separate browser session.';

  @override
  String get linkWithYourPrimaryPhoneThen =>
      'Link with your primary phone, then check the account shown.';

  @override
  String get details => 'Details';

  @override
  String get addAccount => 'Add account';

  @override
  String get yourAccountsKeptSeparate => 'Your accounts,\nkept separate.';

  @override
  String get aQuietWorkspaceForUpTo =>
      'A quiet workspace for up to ten separately linked accounts. Choose one at a time from the selector above.';

  @override
  String get separateSessions => 'Separate sessions';

  @override
  String get eachProfileHasItsOwnPersistent =>
      'Each profile has its own persistent browser storage on this device.';

  @override
  String get linkWithYourPrimaryPhone => 'Link with your primary phone';

  @override
  String get accountOwnersApproveLinkingInThe =>
      'Account owners approve linking in the official WhatsApp app. A separate device is normally needed to scan the QR.';

  @override
  String get oneAccountOpenAtATime => 'One account open at a time';

  @override
  String get inactiveAccountsAreNotMonitoredSwitching =>
      'Inactive accounts are not monitored. Switching may lose drafts or other temporary page activity.';

  @override
  String get setUpYourWorkspace => 'Set up your workspace';

  @override
  String get independentCompanionPrototypeEmbeddedServiceCompatibility =>
      'Independent companion prototype. Embedded service compatibility and distribution permission are being validated. Use only accounts you are authorized to access.';

  @override
  String get aPlaceForEveryAccount => 'A place for every account';

  @override
  String get chooseYourWorkspace => 'Choose your workspace';

  @override
  String get startWithOneAccountGiveIt =>
      'Start with one account. Give it a name, then link it using the official page. You can add up to ten separate profiles.';

  @override
  String get yourSavedProfilesAreReadyTo =>
      'Your saved profiles are ready to select. Each opens in its own browser context.';

  @override
  String get linkYourFirstAccount => 'Link your first account';

  @override
  String get selectAccount => 'Select account';

  @override
  String get settingUp => 'Setting up';

  @override
  String get removalPending => 'Removal pending';

  @override
  String get storageUnavailable => 'Storage unavailable';

  @override
  String get needsReview => 'Needs review';

  @override
  String get userConfirmed => 'User confirmed';

  @override
  String get relinkRequested => 'Relink requested';

  @override
  String get savedLinkingMayBeNeeded => 'Saved · linking may be needed';

  @override
  String get addAnAccount => 'Add an account';

  @override
  String get editAccountLabel => 'Edit account label';

  @override
  String get giveThisProfileANameYou =>
      'Give this profile a name you will recognize. You’ll link the account on the official website next.';

  @override
  String get changingThisLabelKeepsTheSame =>
      'Changing this label keeps the same browser profile and session.';

  @override
  String get accountName => 'Account name';

  @override
  String get forExampleWorkOrPersonal => 'For example, Work or Personal';

  @override
  String get enterAnAccountName => 'Enter an account name.';

  @override
  String get useCharactersOrFewer => 'Use 40 characters or fewer.';

  @override
  String get thatNameIsAlreadyInUse => 'That name is already in use.';

  @override
  String get profileColor => 'Profile color';

  @override
  String colorValue(String value1) {
    return 'Color $value1';
  }

  @override
  String get saving => 'Saving…';

  @override
  String get createAndLinkAccount => 'Create and link account';

  @override
  String get saveLabel => 'Save label';

  @override
  String valueOfAccounts(String value1) {
    return '$value1 of 10 accounts';
  }

  @override
  String get labelsHelpYouFindYourAccounts =>
      'Labels help you find your accounts. Each profile keeps a separate browser session on this device.';

  @override
  String get noSavedAccountsYet => 'No saved accounts yet.';

  @override
  String get retryPendingCleanup => 'Retry pending cleanup';

  @override
  String get removeAllLocalProfiles => 'Remove all local profiles?';

  @override
  String get thisBlocksAccessAndRemovesSaved =>
      'This blocks access and removes saved sessions from this installation. It does not remotely unlink devices or remove exported files.';

  @override
  String get removeAll => 'Remove all';

  @override
  String get removeAllLocalProfiles116 => 'Remove all local profiles';

  @override
  String get selected => ' · Selected';

  @override
  String editValue(String value1) {
    return 'Edit $value1';
  }

  @override
  String moveValueUp(String value1) {
    return 'Move $value1 up';
  }

  @override
  String moveValueDown(String value1) {
    return 'Move $value1 down';
  }

  @override
  String get open => 'Open';

  @override
  String get accountRemoved => 'Account removed';

  @override
  String get thisLocalProfileHasBeenRemoved =>
      'This local profile has been removed.';

  @override
  String get accountDetails => 'Account details';

  @override
  String get localCleanupIsBeingTrackedAccess =>
      'Local cleanup is being tracked. Access stays blocked until the required steps finish.';

  @override
  String get replaceUnavailableProfile => 'Replace unavailable profile';

  @override
  String get createAFreshStoreAfterCleanup =>
      'Create a fresh store after cleanup. An Android installation restored from backup requires a full app-storage reset in system settings.';

  @override
  String replaceValue(String value1) {
    return 'Replace “$value1”?';
  }

  @override
  String get theUnavailableLocalStoreWillBe =>
      'The unavailable local store will be removed before a fresh profile is created. Then approve a new link in the primary app. On Android, an untrusted restored installation requires resetting all app storage in system settings first.';

  @override
  String get replaceAndKeepLabel => 'Replace and keep label';

  @override
  String get pauseAccountSetup => 'Pause account setup';

  @override
  String get keepTheReservedProfileForLater =>
      'Keep the reserved profile for later or remove this local setup.';

  @override
  String get renameOrChangeColor => 'Rename or change color';

  @override
  String get confirmTheLinkedAccount => 'Confirm the linked account';

  @override
  String get onlyAfterCheckingTheAccountShown =>
      'Only after checking the account shown on the official page.';

  @override
  String get haveYouCheckedTheAccount => 'Have you checked the account?';

  @override
  String confirmThatTheOfficialWebsiteShows(String value1) {
    return 'Confirm that the official website shows the account you intend to label “$value1”. This records your confirmation; the app does not inspect its identity.';
  }

  @override
  String get iCheckedTheAccount => 'I checked the account';

  @override
  String get openToRelink => 'Open to relink';

  @override
  String get usesTheExistingProfileWithoutClearing =>
      'Uses the existing profile without clearing other accounts.';

  @override
  String get resetLocalPermissions => 'Reset local permissions';

  @override
  String get removingThisProfileAffectsLocalAccess =>
      'Removing this profile affects local access only. To revoke this device, use Linked devices in the primary WhatsApp app. Files saved elsewhere remain there.';

  @override
  String removeValue(String value1) {
    return 'Remove “$value1”?';
  }

  @override
  String get theLocalSessionWillBeBlocked =>
      'The local session will be blocked and removed. Other accounts are preserved. Remote unlinking is a separate action in the primary app.';

  @override
  String get removeLocalProfile => 'Remove local profile';

  @override
  String get pauseThisSetup => 'Pause this setup?';

  @override
  String get keepForLaterReservesThisAccount =>
      'Keep for later reserves this account slot and its browser data. Remove local setup blocks access and frees the slot only after cleanup succeeds. It does not remotely unlink a device.';

  @override
  String get keepForLater => 'Keep for later';

  @override
  String get removeLocalSetup => 'Remove local setup';

  @override
  String get linkWithTheOfficialApp => 'Link with the official app';

  @override
  String get addAndNameAProfileHere =>
      '1. Add and name a profile here.\n2. On the primary phone, open WhatsApp → Linked devices → Link a device.\n3. Scan the QR displayed inside this profile.\n4. Check the account shown on the official page, then confirm its label in account details.';

  @override
  String get usingTheSamePhone => 'Using the same phone';

  @override
  String get youCannotScanAQROn =>
      'You cannot scan a QR on the same screen with that phone’s camera. Use a separate primary device. Phone-number linking is not yet a supported promise in this embedded client. A QR opened in another browser links that browser, not this profile.';

  @override
  String get savedDoesNotMeanConnected => 'Saved does not mean connected';

  @override
  String get onlyTheSelectedAccountHasA =>
      'Only the selected account has a live web view. Inactive profiles are not monitored and do not provide reliable notifications or unread counts. Switching may lose unsent drafts and temporary page activity. Ten slots are this app’s capacity; each account’s linked-device allowance still applies.';

  @override
  String get whenSomethingStopsWorking => 'When something stops working';

  @override
  String get checkYourConnectionAndReloadThe =>
      'Check your connection and reload the affected profile. If a send’s status is uncertain, inspect it on the official page before sending again. A service outage is not a reason to remove all profiles. If storage is lost or the primary phone revokes access, link that profile again.';

  @override
  String get removeAccessRemotely => 'Remove access remotely';

  @override
  String get inThePrimaryWhatsAppAppOpen =>
      'In the primary WhatsApp app, open Linked devices and log out the relevant device. Removing a local profile here does not prove remote unlinking, especially offline. Never send support a QR, pairing code, session export or private conversation.';

  @override
  String get officialLinkingHelp => 'Official linking help';

  @override
  String get officialLinkedDeviceHelp => 'Official linked-device help';

  @override
  String get officialConnectionHelp => 'Official connection help';

  @override
  String get thisDevice => 'This device';

  @override
  String get platform => 'Platform';

  @override
  String get browserProvider => 'Browser provider';

  @override
  String get isolatedProfiles => 'Isolated profiles';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get scopedCleanup => 'Scoped cleanup';

  @override
  String get nativeDownloads => 'Native downloads';

  @override
  String get availablePathsRequireServiceValidation =>
      'Available paths require service validation';

  @override
  String get notSupportedByThisEngine => 'Not supported by this engine';

  @override
  String get cameraMicrophoneAndCalls => 'Camera, microphone and calls';

  @override
  String get notEnabled => 'Not enabled';

  @override
  String get profileDeskIsAnIndependentCompanion =>
      'Profile Desk is an independent companion prototype. Actual embedded WhatsApp compatibility, ten linked accounts, retention and distribution permission remain separate validation gates.';

  @override
  String get shareSafeDiagnostics => 'Share safe diagnostics';

  @override
  String get noAccountSelected => 'No account selected';

  @override
  String get restoreQuarantined =>
      'This restored installation cannot safely reopen saved sessions. On Android, reset this app’s storage in system settings, then create fresh profiles and link again. Exported files are not removed by this reset.';

  @override
  String get openSourceLicenses => 'Open-source licenses';

  @override
  String get networkOffline =>
      'No network connection. Your saved profiles are kept.';

  @override
  String get fileActionInProgress => 'File action in progress';

  @override
  String fileProgress(String percent) {
    return 'File transfer: $percent%';
  }

  @override
  String get cancelFileAction => 'Cancel file action';

  @override
  String get networkPath => 'Network path';

  @override
  String get networkUnknown => 'Not established';

  @override
  String get networkDisconnected => 'Offline';

  @override
  String get networkPathAvailable =>
      'Available. Service connectivity is checked by the page.';

  @override
  String get linkingStepCreateProfile => 'Add and name a profile here.';

  @override
  String get linkingStepOpenDevices =>
      'On the primary phone, open WhatsApp → Linked devices → Link a device.';

  @override
  String get linkingStepScanProfile =>
      'Scan the QR displayed inside this profile.';

  @override
  String get linkingStepConfirmLabel =>
      'Check the account shown on the official page, then confirm its label in account details.';

  @override
  String get workspaceChatsMenu => 'Chats & menu';

  @override
  String get workspaceOriginalLayout => 'Original layout';

  @override
  String get workspacePhoneLayout => 'Phone layout';

  @override
  String get accountSetupBackup => 'Account setup backup';

  @override
  String get accountSetupHeading => 'Take your account setup with you';

  @override
  String get accountSetupDisclosure =>
      'Back up account names, colors, order and appearance. Chats and signed-in sessions are not included. Each imported account must be linked again.';

  @override
  String get exportAccountSetup => 'Export account setup';

  @override
  String get importAccountSetup => 'Import account setup';

  @override
  String get accountSetupExportNote =>
      'Save account names, colors, order and appearance as a readable JSON file. It is not encrypted. Choose a location you trust.';

  @override
  String get accountSetupImportNote =>
      'Preview a Profile Desk setup file and add its accounts to this device. Existing accounts stay in place.';

  @override
  String get accountSetupChooseFile => 'Choose setup file';

  @override
  String get accountSetupPreview => 'Review accounts to import';

  @override
  String accountSetupSlots(String count, String free) {
    return '$count accounts to add · $free slots available';
  }

  @override
  String accountSetupName(String number) {
    return 'Account $number name';
  }

  @override
  String get accountSetupCapacity =>
      'There is not enough room for this file. No accounts will be replaced. Free up slots in Manage accounts, then try again.';

  @override
  String get accountSetupEmpty => 'This setup file contains no accounts.';

  @override
  String get accountSetupApplyAppearance => 'Use appearance from this file';

  @override
  String get accountSetupKeepLock =>
      'Your device lock and security preferences stay the same.';

  @override
  String get accountSetupImportAccounts => 'Import accounts';

  @override
  String accountSetupImported(String count) {
    return 'Added $count accounts. Open each account and link it with its primary phone.';
  }

  @override
  String get accountSetupExported =>
      'Account setup file saved. Signed-in sessions were not exported.';

  @override
  String get accountSetupInvalidFile =>
      'This is not a supported Profile Desk account setup file. Choose a version 1 setup file with up to ten accounts.';

  @override
  String get accountSetupFileTooLarge =>
      'This setup file is too large. Use a Profile Desk setup file smaller than 64 KiB.';

  @override
  String get accountSetupFileUnavailable =>
      'The setup file could not be opened or saved. Choose a different location and try again.';

  @override
  String get nativeMessagingChats => 'Chats';

  @override
  String get nativeMessagingSearch => 'Search chats';

  @override
  String get nativeMessagingRefresh => 'Refresh chats';

  @override
  String get nativeMessagingOfficial => 'Open official interface';

  @override
  String get nativeMessagingBack => 'Back to chats';

  @override
  String get nativeMessagingEmpty => 'No chats to show';

  @override
  String get nativeMessagingEmptyDetail =>
      'Your available conversations will appear here.';

  @override
  String get nativeMessagingNoResults => 'No matching chats';

  @override
  String get nativeMessagingNoResultsDetail => 'Try another name.';

  @override
  String get nativeMessagingLoading => 'Loading chats…';

  @override
  String get nativeMessagingLoadingMessages => 'Loading messages…';

  @override
  String get nativeMessagingLoadFailed => 'Chats could not be loaded';

  @override
  String get nativeMessagingMessageFailed => 'Messages could not be loaded';

  @override
  String get nativeMessagingTryAgain => 'Try again';

  @override
  String get nativeMessagingLink => 'Link your account';

  @override
  String get nativeMessagingLinkDetail =>
      'Open the official interface to scan the QR code with your primary phone.';

  @override
  String get nativeMessagingLocked => 'Your conversation is protected';

  @override
  String get nativeMessagingLockedDetail => 'Unlock your account to continue.';

  @override
  String get nativeMessagingOffline => 'You are offline';

  @override
  String get nativeMessagingOfflineDetail =>
      'Reconnect, then refresh your chats.';

  @override
  String get nativeMessagingUnsupported => 'Native chats are unavailable';

  @override
  String get nativeMessagingUnsupportedDetail =>
      'Continue in the official interface for this account.';

  @override
  String get nativeMessagingMessage => 'Message';

  @override
  String get nativeMessagingSend => 'Send message';

  @override
  String get nativeMessagingSending => 'Sending…';

  @override
  String get nativeMessagingAccepted =>
      'Submitted to WhatsApp. Delivery is not yet confirmed.';

  @override
  String get nativeMessagingRejected =>
      'This message was not sent. Your draft is ready to edit or send again.';

  @override
  String get nativeMessagingUncertain =>
      'Send status is unknown. Check the official conversation before composing again.';

  @override
  String get nativeMessagingClearUncertain => 'I checked · clear draft';

  @override
  String get nativeMessagingReadOnly =>
      'This conversation is read-only here. Open the official interface for available actions.';

  @override
  String get nativeMessagingUnsupportedMessage =>
      'View this content in the official interface';

  @override
  String get nativeMessagingHistory => 'Load earlier messages';

  @override
  String get nativeMessagingHistoryFailed =>
      'Earlier messages could not be loaded.';

  @override
  String get nativeMessagingPartialHistory =>
      'Only supported, available messages are shown. Open the official interface for complete conversation features.';

  @override
  String get nativeMessagingNoMessages => 'No supported messages to show';

  @override
  String get nativeMessagingPending => 'Pending';

  @override
  String get nativeMessagingSent => 'Sent';

  @override
  String get nativeMessagingDelivered => 'Delivered';

  @override
  String get nativeMessagingRead => 'Read';

  @override
  String get nativeMessagingFailed => 'Not sent';

  @override
  String get nativeMessagingUnread => 'Unread messages';

  @override
  String get nativeMessagingDraftLimit =>
      'Messages can contain up to 4,096 characters.';

  @override
  String get workspacePresentationListShown => 'Chat list opened.';

  @override
  String get workspacePresentationMenuBackHint =>
      'Use Back inside the open WhatsApp panel to return to chats.';

  @override
  String get workspacePresentationDetailUnchanged =>
      'This conversation is still open. Try Original layout to reach its controls.';

  @override
  String get workspacePresentationOriginalSelected =>
      'Original layout selected.';

  @override
  String get workspacePresentationUnavailable =>
      'Phone layout is unavailable for this page. Use Original layout to continue.';

  @override
  String get workspacePresentationCheckFailed =>
      'The page layout could not be checked. Try Original layout.';

  @override
  String get workspacePresentationBackCheckFailed =>
      'The page could not be checked. Try Back again.';

  @override
  String get workspacePresentationUseOriginal => 'Use Original layout';
}
