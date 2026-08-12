// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Smart Publisher';

  @override
  String get welcomeSubtitle =>
      'Manage publishing, scheduling, accounts, and delivery from one control surface.';

  @override
  String get welcomeContinueButton => 'Continue to Login';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundSubtitle =>
      'The page you\'re looking for doesn\'t exist or may have moved.';

  @override
  String get notFoundGoHomeButton => 'Go to Dashboard';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get loginTitle => 'Smart Publisher Login';

  @override
  String get loginSubtitle => 'Sign in to manage your publishing workspace.';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginEmailValidationError => 'Enter a valid email';

  @override
  String get loginPasswordValidationError => 'Enter a valid password';

  @override
  String get authInvalidCredentials => 'Invalid email or password.';

  @override
  String get authConnectionError =>
      'Unable to reach the server. Check your connection.';

  @override
  String get authGenericFailure => 'Authentication failed. Please try again.';

  @override
  String get loginButton => 'Login';

  @override
  String get loginForgotPasswordLink => 'Forgot password?';

  @override
  String get loginNoAccountPrompt => 'Don\'t have an account?';

  @override
  String get loginCreateAccountLink => 'Create one';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Set up your Smart Publisher workspace.';

  @override
  String get registerNameLabel => 'Full name';

  @override
  String get registerNameValidationError => 'Enter your name';

  @override
  String get registerEmailLabel => 'Email';

  @override
  String get registerEmailValidationError => 'Enter a valid email';

  @override
  String get registerPasswordLabel => 'Password';

  @override
  String get registerPasswordValidationError =>
      'Password must be at least 8 characters';

  @override
  String get registerPasswordConfirmationLabel => 'Confirm password';

  @override
  String get registerPasswordConfirmationValidationError =>
      'Passwords do not match';

  @override
  String get registerButton => 'Create account';

  @override
  String get registerHaveAccountPrompt => 'Already have an account?';

  @override
  String get registerLoginLink => 'Log in';

  @override
  String get forgotPasswordTitle => 'Reset your password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your account email and we\'ll send a password reset link.';

  @override
  String get forgotPasswordEmailLabel => 'Email';

  @override
  String get forgotPasswordEmailValidationError => 'Enter a valid email';

  @override
  String get forgotPasswordSubmitButton => 'Send reset link';

  @override
  String get forgotPasswordSuccessMessage =>
      'If an account exists for that email address, a password reset link has been sent.';

  @override
  String get forgotPasswordHaveTokenLink => 'Already have a reset code?';

  @override
  String get forgotPasswordBackToLoginLink => 'Back to login';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get resetPasswordSubtitle =>
      'Enter the reset code from your email along with your new password.';

  @override
  String get resetPasswordEmailLabel => 'Email';

  @override
  String get resetPasswordTokenLabel => 'Reset code';

  @override
  String get resetPasswordNewPasswordLabel => 'New password';

  @override
  String get resetPasswordPasswordValidationError =>
      'Password must be at least 8 characters';

  @override
  String get resetPasswordConfirmPasswordLabel => 'Confirm new password';

  @override
  String get resetPasswordConfirmPasswordValidationError =>
      'Passwords do not match';

  @override
  String get resetPasswordSubmitButton => 'Reset password';

  @override
  String get resetPasswordSuccessMessage =>
      'Your password has been reset successfully. You can now log in.';

  @override
  String get resetPasswordBackToLoginLink => 'Back to login';

  @override
  String get twoFactorChallengeTitle => 'Two-factor verification';

  @override
  String get twoFactorChallengeSubtitle =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get twoFactorChallengeCodeLabel => 'Authentication code';

  @override
  String get twoFactorChallengeCodeValidationError =>
      'Enter your authentication code';

  @override
  String get twoFactorChallengeUseRecoveryCodeLink =>
      'Use a recovery code instead';

  @override
  String get twoFactorChallengeRecoveryCodeLabel => 'Recovery code';

  @override
  String get twoFactorChallengeRecoveryCodeValidationError =>
      'Enter a recovery code';

  @override
  String get twoFactorChallengeUseCodeLink =>
      'Use an authenticator code instead';

  @override
  String get twoFactorChallengeSubmitButton => 'Verify';

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get performanceTooltip => 'Performance';

  @override
  String get platformAdministrationTooltip => 'Platform administration';

  @override
  String get dashboardStatPosts => 'Posts';

  @override
  String get dashboardStatScheduled => 'Scheduled';

  @override
  String get dashboardStatPublished => 'Published';

  @override
  String get dashboardStatFailed => 'Failed';

  @override
  String get dashboardStatAccounts => 'Accounts';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle =>
      'Monitor posts, scheduled work, publishing health, and connected platforms from one place.';

  @override
  String get dashboardAuthenticatedUserFallback => 'Authenticated User';

  @override
  String get dashboardNoEmailFallback => 'No email available';

  @override
  String get dashboardGuestRole => 'Guest';

  @override
  String get dashboardRoleOwner => 'Organization Owner';

  @override
  String get dashboardRoleAdmin => 'Admin';

  @override
  String get dashboardRoleManager => 'Manager';

  @override
  String get dashboardRoleEditor => 'Editor';

  @override
  String get dashboardRoleViewer => 'Viewer';

  @override
  String get dashboardChooseOrganizationRole => 'Choose an organization';

  @override
  String get dashboardNoActiveMembershipRole => 'No active membership';

  @override
  String get dashboardCreatePostButton => 'Create Post';

  @override
  String get dashboardPostsButton => 'Posts';

  @override
  String get dashboardApprovalsButton => 'Approvals';

  @override
  String get dashboardLoadFailed =>
      'Dashboard could not be loaded. Check your connection and try again.';

  @override
  String get dashboardSectionScheduledTodayTitle => 'Scheduled Today';

  @override
  String get dashboardSectionScheduledTodayEmpty =>
      'Nothing scheduled for today.';

  @override
  String get dashboardSectionPublishingQueueTitle => 'Publishing Queue';

  @override
  String get dashboardSectionPublishingQueueEmpty => 'The queue is empty.';

  @override
  String get dashboardSectionFailedPostsTitle => 'Failed Posts';

  @override
  String get dashboardSectionFailedPostsEmpty => 'No failed deliveries.';

  @override
  String get dashboardSectionLastPublishedTitle => 'Last Published';

  @override
  String get dashboardSectionLastPublishedEmpty => 'Nothing published yet.';

  @override
  String get dashboardSectionUpcomingScheduleTitle => 'Upcoming Schedule';

  @override
  String get dashboardSectionUpcomingScheduleEmpty =>
      'No upcoming scheduled posts.';

  @override
  String get moduleMediaLibraryTitle => 'Media Library';

  @override
  String get moduleMediaLibraryDescription => 'Images, video, and attachments.';

  @override
  String get moduleCalendarTitle => 'Calendar';

  @override
  String get moduleCalendarDescription => 'Scheduled posts across every day.';

  @override
  String moduleCalendarBadge(int count) {
    return '$count today';
  }

  @override
  String get moduleAnalyticsTitle => 'Analytics';

  @override
  String get moduleAnalyticsDescription =>
      'Engagement and delivery performance.';

  @override
  String get moduleNotificationsTitle => 'Notifications';

  @override
  String get moduleNotificationsDescription => 'Alerts and account updates.';

  @override
  String get moduleSettingsTitle => 'Settings';

  @override
  String get moduleSettingsDescription => 'Workspace preferences.';

  @override
  String get moduleAdministrationTitle => 'Administration';

  @override
  String get moduleAdministrationDescription => 'Users, roles, and branches.';

  @override
  String get moduleProductionReleaseTitle => 'Production Release';

  @override
  String get moduleProductionReleaseDescription =>
      'Release readiness checklist.';

  @override
  String accountConnectedSuccess(String name) {
    return '$name connected successfully.';
  }

  @override
  String accountConnectFailed(String name) {
    return 'Failed to connect $name.';
  }

  @override
  String get telegramBotConnectedSuccess =>
      'Telegram bot connected successfully.';

  @override
  String get telegramBotConnectFailed => 'Failed to connect Telegram bot.';

  @override
  String platformConnectionStartFailed(String platform) {
    return 'Failed to start $platform connection.';
  }

  @override
  String platformConnectionCancelled(String platform) {
    return '$platform connection was cancelled.';
  }

  @override
  String platformConnectedSuccess(String platform) {
    return '$platform connected successfully.';
  }

  @override
  String get whatsappBusinessIdSaved =>
      'Business ID saved — tap Sync Pages to discover your WhatsApp numbers.';

  @override
  String get whatsappBusinessIdSaveFailed =>
      'Failed to save the WhatsApp Business ID.';

  @override
  String get instagramDialogTitle => 'Instagram Connects via Facebook';

  @override
  String get instagramDialogBody =>
      'Instagram Business accounts have no separate login of their own — they are discovered automatically through your Facebook connection. Connect Facebook, then tap \"Sync Pages\" to bring in any linked Instagram Business account.';

  @override
  String get gotIt => 'Got it';

  @override
  String pagesSyncedSuccess(String name) {
    return 'Pages synced for $name.';
  }

  @override
  String pagesSyncFailed(String name) {
    return 'Failed to sync pages for $name.';
  }

  @override
  String channelAddedSuccess(String name) {
    return 'Channel added to $name.';
  }

  @override
  String channelAddFailed(String name) {
    return 'Failed to add channel to $name.';
  }

  @override
  String selectedPagesUpdatedSuccess(String name) {
    return 'Selected pages updated for $name.';
  }

  @override
  String get selectedPagesUpdateFailed => 'Failed to update selected pages.';

  @override
  String pageRemovedSuccess(String name) {
    return 'Page removed from $name.';
  }

  @override
  String get pageRemoveFailed => 'Failed to remove page.';

  @override
  String accountDisconnectedSuccess(String name) {
    return '$name disconnected.';
  }

  @override
  String accountDisconnectFailed(String name) {
    return 'Failed to disconnect $name.';
  }

  @override
  String refreshTokenRequestedSuccess(String name) {
    return 'Refresh token requested for $name.';
  }

  @override
  String refreshTokenFailed(String name) {
    return 'Failed to refresh token for $name.';
  }

  @override
  String testConnectionFailed(String name) {
    return 'Failed to test the connection for $name.';
  }

  @override
  String get accountCardNoPermissions => 'No permissions assigned';

  @override
  String accountCardTokenExpires(String date) {
    return 'Token expires: $date';
  }

  @override
  String accountCardLastSynced(String date) {
    return 'Last synced: $date';
  }

  @override
  String accountCardLastPublished(String date) {
    return 'Last published: $date';
  }

  @override
  String get accountCardTodayPrefix => 'Today';

  @override
  String get accountCardWhatsappSendingUnavailable =>
      'Sending is not available yet for WhatsApp — connect to discover numbers, but Publish will be blocked until this ships.';

  @override
  String get betaTag => 'Beta';

  @override
  String comingSoonSuffix(String platform) {
    return '$platform — Coming soon';
  }

  @override
  String get accountStatusConnected => 'Connected';

  @override
  String get accountStatusExpired => 'Expired';

  @override
  String get accountStatusRevoked => 'Revoked';

  @override
  String get accountStatusFailed => 'Failed';

  @override
  String get accountStatusPending => 'Pending…';

  @override
  String get accountStatusDisconnected => 'Disconnected';

  @override
  String get actionTestConnection => 'Test Connection';

  @override
  String get actionDisconnect => 'Disconnect';

  @override
  String get actionRefreshToken => 'Refresh Token';

  @override
  String get actionReauthenticate => 'Re-authenticate';

  @override
  String get actionWorkingOnIt => 'Working on it…';

  @override
  String get actionConnect => 'Connect';

  @override
  String get accountsGridTitle => 'Accounts';

  @override
  String get accountsGridLoadingSubtitle =>
      'Connected workspaces and permissions across all platforms.';

  @override
  String get accountsGridSubtitle =>
      'Manage Facebook, Instagram, Telegram, WhatsApp, LinkedIn, and X accounts.';

  @override
  String get postStatusSectionDefaultEmpty => 'Nothing here right now.';

  @override
  String get postUntitled => 'Untitled post';

  @override
  String get viewAll => 'View all';

  @override
  String get publishingHealthTitle => 'Publishing Health';

  @override
  String get publishingHealthSubtitle =>
      'Current operational snapshot across delivery and accounts.';

  @override
  String get publishingHealthConnectedAccounts => 'Connected Accounts';

  @override
  String get publishingHealthQueueHealth => 'Queue Health';

  @override
  String get publishingHealthNeedsAttention => 'Needs attention';

  @override
  String get publishingHealthStable => 'Stable';

  @override
  String get publishingHealthFailedDeliveries => 'Failed Deliveries';

  @override
  String get publishingHealthDistributionByPlatform =>
      'Distribution by platform';

  @override
  String get publishingHealthSuccess => 'Success';

  @override
  String get recentActivityTitle => 'Recent Activity';

  @override
  String get recentActivitySubtitle =>
      'Latest publishing items and post operations.';

  @override
  String get recentActivityEmpty =>
      'No posts yet — create one to see it show up here.';

  @override
  String activityPublishedTo(String platform) {
    return 'Published to $platform';
  }

  @override
  String activityFailedOn(String platform) {
    return 'Failed on $platform';
  }

  @override
  String get activityPartiallyPublished =>
      'Partially published — some targets failed';

  @override
  String get activityCancelled => 'Cancelled before publishing';

  @override
  String get activityCurrentlyPublishing => 'Currently publishing';

  @override
  String get activitySavedAsDraft => 'Saved as draft';

  @override
  String get activityScheduledForPublishing => 'Scheduled for publishing';

  @override
  String get activityScheduledForToday => 'Scheduled for today';

  @override
  String get activityScheduledForTomorrow => 'Scheduled for tomorrow';

  @override
  String activityScheduledForDate(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get activityThePlatform => 'the platform';

  @override
  String get workspaceModulesTitle => 'Workspace Modules';

  @override
  String get workspaceModulesSubtitle =>
      'Access Media Library, Calendar, Analytics, Notifications, Settings, Administration, and Production Release.';

  @override
  String get pagesPanelNoneYet => 'No pages or channels yet';

  @override
  String pagesPanelCount(int count) {
    return '$count page(s)/channel(s)';
  }

  @override
  String get pagesPanelSyncPages => 'Sync Pages';

  @override
  String get pagesPanelAddChannel => 'Add Channel';

  @override
  String get pagesPanelNothingAdded => 'Nothing added yet.';

  @override
  String pagesPanelMembersCount(int count) {
    return '$count members';
  }

  @override
  String get pagesPanelRemove => 'Remove';

  @override
  String get pagesPanelSaveSelection => 'Save Selection';

  @override
  String get pageKindInstagram => 'Instagram';

  @override
  String get pageKindWhatsapp => 'WhatsApp';

  @override
  String get pageKindChannel => 'Channel';

  @override
  String get pageKindPage => 'Page';

  @override
  String get pageStatusValid => 'Valid';

  @override
  String get pageStatusNeedsReauth => 'Needs reauth';

  @override
  String get pageStatusInvalid => 'Invalid';

  @override
  String get addTelegramChannelTitle => 'Add Telegram Channel';

  @override
  String get addTelegramChannelBody =>
      'Make sure the bot is already an admin of the channel, then enter its @username or chat id.';

  @override
  String get addTelegramChannelLabel => 'Channel';

  @override
  String get addTelegramChannelHint => '@my_channel or -1001234567890';

  @override
  String get addTelegramChannelAdd => 'Add';

  @override
  String get connectTelegramBotTitle => 'Connect Telegram Bot';

  @override
  String get connectTelegramBotBody =>
      'Create a bot via @BotFather on Telegram, then paste its token below.';

  @override
  String get connectTelegramBotLabel => 'Bot Token';

  @override
  String get connectTelegramBotConnect => 'Connect';

  @override
  String get whatsappBusinessIdTitle => 'Enter Your Meta Business ID';

  @override
  String get whatsappBusinessIdBody =>
      'Find this in Meta Business Suite under Business Settings — it identifies which WhatsApp Business Accounts to discover.';

  @override
  String get whatsappBusinessIdLabel => 'Business ID';

  @override
  String get whatsappBusinessIdSave => 'Save';

  @override
  String get settingsScreenTitle => 'Settings';

  @override
  String get settingsOrganizationsTitle => 'Organizations';

  @override
  String get settingsOrganizationsSubtitle =>
      'Switch between organizations you belong to.';

  @override
  String get settingsMembersTitle => 'Team members';

  @override
  String get settingsMembersSubtitle =>
      'Add or manage members of your organization.';

  @override
  String get settingsAuditLogTitle => 'Audit log';

  @override
  String get settingsAuditLogSubtitle =>
      'Review who did what across this organization.';

  @override
  String get settingsTwoFactorTitle => 'Two-factor authentication';

  @override
  String get settingsTwoFactorSubtitle =>
      'Add an extra layer of security to your account.';

  @override
  String get settingsDataExportTitle => 'Download my data';

  @override
  String get settingsDataExportSubtitle =>
      'Get a copy of your account, posts, and connections.';

  @override
  String get settingsDataDeletionTitle => 'Delete my account';

  @override
  String get settingsDataDeletionSubtitle =>
      'Request permanent deletion of your account and data.';

  @override
  String get emailVerificationBannerMessage =>
      'Please verify your email address to keep full access to your account.';

  @override
  String get emailVerificationBannerResendButton => 'Resend verification email';

  @override
  String get emailVerificationResendSuccess =>
      'Verification link sent. Check your email.';

  @override
  String get dataExportAppBarTitle => 'Download my data';

  @override
  String get dataExportIntro =>
      'This includes your account details and everything linked to it across every organization you belong to.';

  @override
  String get dataExportUserSectionTitle => 'Account';

  @override
  String get dataExportOrganizationsCount => 'Organizations';

  @override
  String get dataExportPostsCount => 'Posts';

  @override
  String get dataExportSocialAccountsCount => 'Connected social accounts';

  @override
  String get dataExportMediaAttachmentsCount => 'Media attachments';

  @override
  String get dataExportExportedAtLabel => 'Generated at';

  @override
  String get dataExportCopyJsonButton => 'Copy full data as JSON';

  @override
  String get dataExportCopiedMessage => 'Copied to clipboard.';

  @override
  String get dataExportLoadError => 'Failed to generate your data export.';

  @override
  String get dataExportRetryButton => 'Retry';

  @override
  String get dataDeletionAppBarTitle => 'Delete my account';

  @override
  String get dataDeletionWarningTitle => 'This cannot be undone';

  @override
  String get dataDeletionWarningMessage =>
      'Your request will be reviewed by an operator before anything is deleted — this is not instant. Connected social accounts, posts, and media tied to your account will eventually be permanently removed.';

  @override
  String get dataDeletionReasonLabel => 'Reason (optional)';

  @override
  String get dataDeletionConfirmCheckboxLabel =>
      'I understand this will permanently delete my account and data.';

  @override
  String get dataDeletionConfirmValidationError =>
      'You must confirm before submitting.';

  @override
  String get dataDeletionSubmitButton => 'Request account deletion';

  @override
  String get dataDeletionSuccessTitle => 'Deletion request recorded';

  @override
  String dataDeletionSuccessMessage(String status) {
    return 'Your request has been recorded and will be reviewed. Status: $status.';
  }

  @override
  String get organizationMembersAppBarTitle => 'Team members';

  @override
  String get organizationMembersEmptyMessage => 'No members yet.';

  @override
  String get organizationMembersLoadError => 'Failed to load members.';

  @override
  String get organizationMembersYouLabel => 'You';

  @override
  String get organizationMembersAddButton => 'Add member';

  @override
  String get organizationMembersAddDialogTitle => 'Add a team member';

  @override
  String get organizationMembersAddDialogSubtitle =>
      'The email must already belong to a registered Smart Publisher account.';

  @override
  String get organizationMembersEmailLabel => 'Email';

  @override
  String get organizationMembersEmailValidationError => 'Enter a valid email';

  @override
  String get organizationMembersRoleLabel => 'Role';

  @override
  String get organizationMembersAddSubmitButton => 'Add';

  @override
  String get organizationMembersAddedSuccess => 'Member added.';

  @override
  String get organizationMembersRoleUpdatedSuccess => 'Role updated.';

  @override
  String get organizationMembersRemoveConfirmTitle => 'Remove member?';

  @override
  String organizationMembersRemoveConfirmMessage(String name) {
    return '$name will lose access to this organization.';
  }

  @override
  String get organizationMembersRemovedSuccess => 'Member removed.';

  @override
  String get organizationMembersRemoveButton => 'Remove';

  @override
  String organizationMembersRemoveTooltip(String name) {
    return 'Remove $name';
  }

  @override
  String get auditLogAppBarTitle => 'Audit log';

  @override
  String get auditLogEmptyMessage => 'No matching audit events.';

  @override
  String get auditLogLoadError => 'Failed to load the audit log.';

  @override
  String get auditLogRetryButton => 'Retry';

  @override
  String get auditLogForbiddenTitle => 'Not authorized';

  @override
  String get auditLogForbiddenMessage =>
      'The server denied access to this audit log.';

  @override
  String get auditLogFilterActionLabel => 'Filter by action';

  @override
  String get auditLogFilterDateFromLabel => 'From';

  @override
  String get auditLogFilterDateToLabel => 'To';

  @override
  String get auditLogFilterClearButton => 'Clear filters';

  @override
  String get auditLogSystemActor => 'System';

  @override
  String auditLogEntrySubtitle(String type, String id) {
    return '$type #$id';
  }

  @override
  String get auditLogViewDetailsButton => 'View details';

  @override
  String get auditLogDetailsOldValues => 'Previous values';

  @override
  String get auditLogDetailsNewValues => 'New values';

  @override
  String get auditLogDetailsNone => 'None recorded.';

  @override
  String auditLogPaginationLabel(String page, String lastPage) {
    return 'Page $page of $lastPage';
  }

  @override
  String get auditLogPreviousPage => 'Previous';

  @override
  String get auditLogNextPage => 'Next';

  @override
  String get auditLogOrganizationColumn => 'Organization';

  @override
  String get twoFactorSetupAppBarTitle => 'Two-factor authentication';

  @override
  String get twoFactorSetupEnabledStatus =>
      'Two-factor authentication is enabled on your account.';

  @override
  String get twoFactorSetupDisabledStatus =>
      'Two-factor authentication is not enabled.';

  @override
  String get twoFactorSetupIntro =>
      'Protect your account with an authenticator app (Google Authenticator, Authy, 1Password, etc.).';

  @override
  String get twoFactorSetupEnableButton => 'Enable two-factor authentication';

  @override
  String get twoFactorSetupDisableButton => 'Disable two-factor authentication';

  @override
  String get twoFactorSetupSecretLabel => 'Secret key';

  @override
  String get twoFactorSetupSecretHint =>
      'Enter this key manually in your authenticator app, or copy the setup link below.';

  @override
  String get twoFactorSetupOtpAuthUrlLabel => 'Setup link';

  @override
  String get twoFactorSetupCopyTooltip => 'Copy';

  @override
  String get twoFactorSetupCopiedMessage => 'Copied to clipboard.';

  @override
  String get twoFactorSetupCodeLabel => 'Enter the 6-digit code from your app';

  @override
  String get twoFactorSetupCodeValidationError => 'Enter the 6-digit code';

  @override
  String get twoFactorSetupConfirmButton => 'Confirm and enable';

  @override
  String get twoFactorSetupCancelButton => 'Cancel';

  @override
  String get twoFactorSetupRecoveryCodesTitle => 'Save your recovery codes';

  @override
  String get twoFactorSetupRecoveryCodesWarning =>
      'Store these codes somewhere safe. Each one can be used once to sign in if you lose access to your authenticator app. They will not be shown again.';

  @override
  String get twoFactorSetupDoneButton => 'Done';

  @override
  String get twoFactorSetupDisablePasswordLabel => 'Current password';

  @override
  String get twoFactorSetupDisablePasswordValidationError =>
      'Enter your current password';

  @override
  String get twoFactorSetupDisableConfirmButton => 'Disable';

  @override
  String get twoFactorSetupSuccessEnabled =>
      'Two-factor authentication enabled.';

  @override
  String get twoFactorSetupSuccessDisabled =>
      'Two-factor authentication disabled.';

  @override
  String get settingsPushNotificationsTitle => 'Push Notifications';

  @override
  String get settingsPushNotificationsSubtitle =>
      'Not available yet — no push notification integration exists in this build.';

  @override
  String get settingsAutoScheduleTitle => 'Auto Scheduling Suggestions';

  @override
  String get settingsAutoScheduleSubtitle =>
      'Not available yet — smart scheduling recommendations aren\'t implemented in this build.';

  @override
  String get settingsCanaryReleaseTitle => 'Canary Release Mode';

  @override
  String get settingsCanaryReleaseSubtitle =>
      'Not available yet — there is no progressive-delivery controller in this build.';

  @override
  String get settingsPreferredTheme => 'Preferred Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageArabic => 'العربية';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsSaveButton => 'Save Settings';

  @override
  String get settingsSavedSuccess => 'Settings saved successfully.';

  @override
  String get composerAppBarTitle => 'Create Post';

  @override
  String get composerHeading => 'Build your post';

  @override
  String get composerSubheading =>
      'Title, content, media, platforms, schedule, preview, and publish in one flow.';

  @override
  String get composerEditingDraftChip => 'Editing Existing Draft';

  @override
  String composerDraftIdChip(String id) {
    return 'ID: $id';
  }

  @override
  String get composerTitleLabel => 'Title';

  @override
  String get composerTitleHint => 'Post title';

  @override
  String get composerContentLabel => 'Content';

  @override
  String get composerContentHint =>
      'Write your post content... (#hashtags and @mentions highlight automatically)';

  @override
  String get composerMediaTitle => 'Media';

  @override
  String get composerMediaSubtitle =>
      'Attach media links or upload files from your device.';

  @override
  String get composerMediaUrlHint => 'https://cdn.example.com/image.png';

  @override
  String get composerAddUrl => 'Add URL';

  @override
  String get composerUploadFile => 'Upload File';

  @override
  String get composerNoMediaYet => 'No media attached yet.';

  @override
  String get composerPagesTitle => 'Pages & Channels';

  @override
  String get composerPagesSubtitle =>
      'Select the specific pages/channels to publish to — not just a platform.';

  @override
  String get composerNoUsablePages =>
      'No usable pages or channels yet. Connect an account and add/select its pages from Dashboard > Accounts.';

  @override
  String get composerFailedToLoadAccounts =>
      'Failed to load connected accounts.';

  @override
  String get composerPerPlatformContentTitle => 'Per-Platform Content';

  @override
  String get composerPerPlatformContentSubtitle =>
      'Optionally write different text for a platform — leave blank to use the shared content above.';

  @override
  String composerPlatformOverrideLabel(String platform) {
    return '$platform override';
  }

  @override
  String get composerPlatformOverrideHint =>
      'Leave blank to use the shared content';

  @override
  String get composerPerPlatformPreviewTitle => 'Per-Platform Preview';

  @override
  String get composerPerPlatformPreviewSubtitle =>
      'Shows exactly what each platform will really display — formatting only renders where the platform actually supports it.';

  @override
  String get composerSchedulingTitle => 'Scheduling';

  @override
  String get composerNoScheduleSelected =>
      'No schedule selected (publish immediately).';

  @override
  String composerScheduledFor(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get composerPickTime => 'Pick time';

  @override
  String get composerClearScheduleTooltip => 'Clear schedule';

  @override
  String get composerPreviewTitle => 'Preview';

  @override
  String get composerOpenPreview => 'Open Preview';

  @override
  String get composerSaveDraftButton => 'Save Draft';

  @override
  String get composerScheduleButton => 'Schedule';

  @override
  String get composerPublishButton => 'Publish';

  @override
  String get composerSubmitScheduleForApprovalButton =>
      'Submit schedule for approval';

  @override
  String get composerSubmitPublishForApprovalButton =>
      'Submit publish request for approval';

  @override
  String get composerApprovalRequiredNotice =>
      'Your schedule and publish requests will be sent for approval before they are executed.';

  @override
  String get composerOrganizationAccessLoading =>
      'Checking organization access…';

  @override
  String get composerOrganizationAccessUnavailable =>
      'Organization access is unavailable. Select an organization or try again.';

  @override
  String get composerPostActionNotAllowed =>
      'You do not have permission to submit this post action.';

  @override
  String get composerPreviewSheetTitle => 'Post Preview';

  @override
  String get composerNoContentYet => 'No content yet.';

  @override
  String get composerPreviewMediaLabel => 'Media';

  @override
  String get composerPreviewTargetsLabel => 'Targets';

  @override
  String get composerPreviewScheduleLabel => 'Schedule';

  @override
  String get composerMediaNone => 'None';

  @override
  String composerMediaItemCount(int count) {
    return '$count item(s)';
  }

  @override
  String get composerNoneSelected => 'None selected';

  @override
  String get composerPublishNow => 'Publish now';

  @override
  String get composerInvalidMediaUrl =>
      'That doesn\'t look like a URL (http:// or https://). To attach a file from your device, use \"Upload File\" instead.';

  @override
  String get composerMediaUrlAlreadyAdded => 'Media URL already added.';

  @override
  String get composerTitleContentRequired => 'Title and content are required.';

  @override
  String get composerTitleRequiredForMedia =>
      'Add a post title first before attaching media.';

  @override
  String get composerSelectAtLeastOnePage =>
      'Select at least one page or channel for publishing.';

  @override
  String get composerSelectScheduleTime =>
      'Select a schedule time before scheduling.';

  @override
  String get composerScheduleTimeMustBeFuture =>
      'Schedule time must be in the future.';

  @override
  String get composerFailedSaveDraft => 'Failed to save draft.';

  @override
  String get composerFailedUpdateDraft => 'Failed to update draft.';

  @override
  String get composerDraftSavedSuccess => 'Draft saved successfully.';

  @override
  String get composerDraftUpdatedSuccess => 'Draft updated successfully.';

  @override
  String get composerFailedSchedulePost => 'Failed to schedule post.';

  @override
  String get composerPostScheduledSuccess => 'Post scheduled successfully.';

  @override
  String get composerFailedPublishPost => 'Failed to publish post.';

  @override
  String get composerPostQueuedSuccess => 'Post queued for publishing.';

  @override
  String get composerFileDataUnavailable =>
      'Selected file data is not available.';

  @override
  String get composerFilePathUnavailable =>
      'Selected file path is not available.';

  @override
  String get composerFailedUploadMedia => 'Failed to upload media file.';

  @override
  String get composerMediaAlreadyAttached => 'Media file already attached.';

  @override
  String get composerMediaUploadedSuccess =>
      'Media file uploaded and attached.';

  @override
  String get calendarAppBarTitle => 'Publishing Calendar';

  @override
  String get calendarSubtitle =>
      'Track scheduled posts by date and keep publishing cadence on time.';

  @override
  String calendarMonthLabel(String month) {
    return 'Month: $month';
  }

  @override
  String calendarEventsLabel(int count) {
    return 'Events: $count';
  }

  @override
  String calendarScheduledForDate(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get calendarNoScheduledPosts => 'No scheduled posts on this date.';

  @override
  String get calendarFailedToLoad => 'Failed to load the calendar.';

  @override
  String calendarStatusLabel(String status) {
    return 'Status: $status';
  }

  @override
  String calendarScheduleLabel(String date) {
    return 'Schedule: $date';
  }

  @override
  String get calendarDefaultStatus => 'scheduled';

  @override
  String get mediaAppBarTitle => 'Media Library';

  @override
  String get mediaSubtitle =>
      'Real, server-side media library — search, filter, compress, and reuse assets across posts.';

  @override
  String get mediaSearchLabel => 'Search media';

  @override
  String get mediaSearchHint => 'Original file name';

  @override
  String get mediaFilterAll => 'All';

  @override
  String get mediaFilterImages => 'Images';

  @override
  String get mediaFilterVideos => 'Videos';

  @override
  String get mediaFilterDocuments => 'Documents';

  @override
  String get mediaCompressTooltipImage =>
      'Re-encode this image at a smaller size';

  @override
  String get mediaCompressTooltipOther =>
      'Compression is only available for images right now';

  @override
  String get mediaCompressButton => 'Compress';

  @override
  String get mediaReuseInPostButton => 'Reuse in Post';

  @override
  String get mediaDeleteTooltip => 'Delete media asset';

  @override
  String get mediaFailedDelete => 'Failed to delete media asset.';

  @override
  String get mediaFailedToLoad => 'Failed to load the media library.';

  @override
  String get mediaLoadMore => 'Load more';

  @override
  String get mediaDeletedSuccess => 'Media asset deleted.';

  @override
  String get mediaCompressedSuccess => 'Compressed successfully.';

  @override
  String get mediaFailedCompress => 'Failed to compress media.';

  @override
  String get mediaNoPostsToAttach =>
      'No posts available to attach this media to.';

  @override
  String get mediaReuseDialogTitle => 'Reuse in Post';

  @override
  String get mediaAttachedSuccess => 'Media attached to the selected post.';

  @override
  String get mediaFailedReuse => 'Failed to reuse media in the post.';

  @override
  String get mediaUnknownDate => 'Unknown date';

  @override
  String get mediaEmptyTitle => 'No media assets found.';

  @override
  String get mediaEmptySubtitle =>
      'Upload media from the composer, then revisit this library.';

  @override
  String get analyticsAppBarTitle => 'Analytics';

  @override
  String get analyticsSubtitle =>
      'Performance overview, post-level metrics, and engagement trends.';

  @override
  String get analyticsMetricReach => 'Reach';

  @override
  String get analyticsMetricImpressions => 'Impressions';

  @override
  String get analyticsMetricEngagement => 'Engagement';

  @override
  String get analyticsMetricAvgEngagementRate => 'Avg. Engagement Rate';

  @override
  String get analyticsBestTimeToPost => 'Best Time to Post';

  @override
  String get analyticsBestPlatform => 'Best Platform';

  @override
  String get analyticsNotEnoughData => 'Not enough data yet';

  @override
  String get analyticsNoPostsYet => 'No posts available for analytics yet.';

  @override
  String get analyticsFailedToLoad => 'Failed to load analytics.';

  @override
  String get analyticsMetricClicks => 'Clicks';

  @override
  String get analyticsMetricShares => 'Shares';

  @override
  String get analyticsMetricReactions => 'Reactions';

  @override
  String get analyticsMetricEngagementRate => 'Engagement Rate';

  @override
  String get notificationsAppBarTitle => 'Notifications';

  @override
  String get notificationsMarkAllReadTooltip => 'Mark all as read';

  @override
  String get notificationsClearReadTooltip => 'Clear read';

  @override
  String get notificationsInboxSummaryTitle => 'Inbox Summary';

  @override
  String notificationsInboxSummarySubtitle(int unread, int total) {
    return 'Unread: $unread • Total: $total';
  }

  @override
  String get notificationsEmpty => 'No notifications available.';

  @override
  String get notificationsMarkReadButton => 'Mark read';

  @override
  String get notificationsLoadFailed =>
      'Notifications could not be loaded. Check your connection and try again.';

  @override
  String get administrationAppBarTitle => 'Administration';

  @override
  String get administrationReadOnlyNotice =>
      'Administrative actions are restricted to admins. You currently have read-only access.';

  @override
  String get administrationAccessProfileTitle => 'Access Profile';

  @override
  String administrationAccessProfileSubtitle(String role) {
    return 'Current role: $role';
  }

  @override
  String get administrationMaintenanceModeTitle => 'Maintenance Mode';

  @override
  String get administrationMaintenanceModeSubtitle =>
      'Limit editor access while conducting maintenance operations.';

  @override
  String get administrationFreezePublishingTitle => 'Freeze Publishing Queue';

  @override
  String get administrationFreezePublishingSubtitle =>
      'Pause new publish jobs while existing jobs complete.';

  @override
  String get administrationCredentialsTitle => 'Social Platform Credentials';

  @override
  String get administrationCredentialsSubtitle =>
      'Manage OAuth App ID/Secret for Facebook, Instagram, LinkedIn, X, and WhatsApp.';

  @override
  String get administrationReleaseHistoryTitle => 'Release History';

  @override
  String get administrationReleaseHistorySubtitle =>
      'Review recently deployed versions and rollout notes.';

  @override
  String get administrationOperationalReadinessTitle => 'Operational Readiness';

  @override
  String get administrationOperationalReadinessSubtitle =>
      'Track go-live checks, incident playbooks, and rollback readiness.';

  @override
  String get administrationApplyPoliciesButton =>
      'Apply Administrative Policies';

  @override
  String get administrationPoliciesAppliedSuccess =>
      'Administrative policies applied successfully.';

  @override
  String get administrationOperationsUnavailable =>
      'Maintenance, publishing freeze, and policy deployment are unavailable in this build. Use the audited backend operations workflow.';

  @override
  String get oauthSettingsIntro =>
      'These are application-wide OAuth credentials (App ID/Secret) used for every user who connects an account — not a per-user setting.';

  @override
  String get oauthSettingsFailedToLoad => 'Failed to load provider settings.';

  @override
  String get oauthSettingsHistoryTooltip => 'History';

  @override
  String get oauthSettingsMockNotice =>
      'Simulated integration — configuring credentials here does not enable real posting. No live HTTP calls are made to this platform yet.';

  @override
  String oauthSettingsClientIdSet(String clientId) {
    return 'Client ID: $clientId';
  }

  @override
  String get oauthSettingsClientIdNotSet => 'Client ID: not set';

  @override
  String oauthSettingsUpdatedBy(String name, String timestamp) {
    return 'Updated by $name • $timestamp';
  }

  @override
  String get oauthSettingsTestAgain => 'Test Again';

  @override
  String get oauthSettingsTestConnection => 'Test Connection';

  @override
  String get oauthSettingsNotConfigured => 'Not Configured';

  @override
  String get oauthSettingsConfigured => '🟢 Configured';

  @override
  String oauthSettingsLastVerified(String timestamp) {
    return 'Last verified: $timestamp';
  }

  @override
  String get oauthSettingsInvalidConfig => '🔴 Invalid Configuration';

  @override
  String get oauthSettingsAuthFailed => 'Authentication failed.';

  @override
  String get oauthSettingsConfiguredNotTested => 'Configured (not yet tested)';

  @override
  String oauthSettingsHistorySheetTitle(String label) {
    return '$label History';
  }

  @override
  String get oauthSettingsNoHistory => 'No changes recorded yet.';

  @override
  String get oauthSettingsTestedSucceeded => 'Tested connection — succeeded';

  @override
  String get oauthSettingsTestedFailed => 'Tested connection — failed';

  @override
  String get oauthSettingsUpdatedSettings => 'Updated settings';

  @override
  String oauthSettingsUpdatedFields(String fields) {
    return 'Updated $fields';
  }

  @override
  String get oauthSettingsAutomatedCheck => 'Automated check';

  @override
  String oauthSettingsSaveSuccess(String label) {
    return '$label settings saved.';
  }

  @override
  String get oauthSettingsSaveFailedDefault =>
      'Failed to save provider settings.';

  @override
  String get oauthSettingsTestFailedDefault => 'Failed to test the connection.';

  @override
  String oauthSettingsEditDialogTitle(String label) {
    return '$label Credentials';
  }

  @override
  String get oauthSettingsClientIdLabel => 'Client ID (App ID)';

  @override
  String get oauthSettingsClientSecretLabel => 'Client Secret (App Secret)';

  @override
  String get oauthSettingsClientSecretHintKeep =>
      'Leave blank to keep the current secret';

  @override
  String get oauthSettingsClientSecretHintNotSet => 'Not set';

  @override
  String get oauthSettingsEnabledLabel => 'Enabled';

  @override
  String get releaseAppBarTitle => 'Production Release';

  @override
  String releaseChannelLabel(String channel) {
    return 'Release Channel: $channel';
  }

  @override
  String releaseCanaryPercentLabel(int percent) {
    return 'Canary Percent: $percent%';
  }

  @override
  String releaseReadinessLabel(String percent) {
    return 'Readiness: $percent%';
  }

  @override
  String get releaseCommandsTitle => 'Release Commands';

  @override
  String get releaseStartButton => 'Start Production Release';

  @override
  String get releaseActionsUnavailable =>
      'Release execution is unavailable from the app. Use the approved CI/CD workflow and deployment runbook.';

  @override
  String get releaseInitiatedSuccess =>
      'Production release initiated successfully.';

  @override
  String get releaseCheckTestsPassed => 'All critical tests passed';

  @override
  String get releaseCheckAnalyzeClean => 'flutter analyze reports no issues';

  @override
  String get releaseCheckApiContracts =>
      'API contracts validated for v1 endpoints';

  @override
  String get releaseCheckSecretsVerified =>
      'Security keys and secrets verified';

  @override
  String get releaseCheckQueueChecks =>
      'Queue retry and circuit breaker checks completed';

  @override
  String get releaseCheckObservability => 'Observability dashboards verified';

  @override
  String get releaseCheckRunbook =>
      'Incident runbook reviewed with on-call team';

  @override
  String get releaseCheckRollback => 'Rollback strategy confirmed and tested';

  @override
  String get releaseCheckCanaryApproved => 'Canary release percentage approved';

  @override
  String get releaseCheckSignoff => 'Stakeholder sign-off captured';

  @override
  String get releaseChecksUnverifiedBanner =>
      'No automated evidence source is connected to this screen yet — every check below is unverified until it\'s backed by a real CI run, deployment log, or sign-off record.';

  @override
  String get releaseCheckStatusUnverified => 'Not verified';

  @override
  String get orgSwitcherAppBarTitle => 'Organizations';

  @override
  String get orgSwitcherFailedToSwitch => 'Failed to switch organizations.';

  @override
  String get orgSwitcherFailedToLoad =>
      'Unable to load organizations. Check your connection and try again.';

  @override
  String get orgSwitcherRetry => 'Retry';

  @override
  String get orgSwitcherSelectActive => 'Select an organization to continue.';

  @override
  String orgSwitcherSwitchedTo(String name) {
    return 'Switched to $name.';
  }

  @override
  String orgSwitcherWelcomeTitle(String name) {
    return 'Welcome, $name';
  }

  @override
  String orgSwitcherWelcomeSubtitle(String appName) {
    return 'Your $appName account is ready. One step left: join an organization to start publishing.';
  }

  @override
  String get orgSwitcherEmptyTitle => 'No organization yet';

  @override
  String get orgSwitcherEmpty =>
      'You are not a member of any organization yet. An organization owner or admin needs to add you, or a platform administrator can create one for you. You can still manage your account security below.';

  @override
  String get orgSwitcherEmptyAccountAction => 'Account security';

  @override
  String get orgSwitcherActiveChip => 'Active';

  @override
  String get orgSwitcherSwitchButton => 'Switch';

  @override
  String get orgSwitcherRoleOwner => 'Owner';

  @override
  String get orgSwitcherRoleAdmin => 'Admin';

  @override
  String get orgSwitcherRoleManager => 'Manager';

  @override
  String get orgSwitcherRoleEditor => 'Editor';

  @override
  String get orgSwitcherRoleViewer => 'Viewer';

  @override
  String get postsListAppBarTitle => 'Posts';

  @override
  String get postsListCreateTooltip => 'Create post';

  @override
  String get postsListHeadline => 'Posts Library';

  @override
  String get postsListSubtitle =>
      'Search, filter, and edit your drafts, scheduled, and published posts.';

  @override
  String get postsListSearchLabel => 'Search posts';

  @override
  String get postsListSearchHint => 'Title or content';

  @override
  String get postsListFilterAll => 'All';

  @override
  String get postsListFilterDraft => 'Draft';

  @override
  String get postsListFilterScheduled => 'Scheduled';

  @override
  String get postsListFilterPublished => 'Published';

  @override
  String get postsListStatusPublishing => 'Publishing';

  @override
  String get postsListStatusFailed => 'Failed';

  @override
  String get postsListStatusPartialSuccess => 'Partially published';

  @override
  String get postsListStatusCancelled => 'Cancelled';

  @override
  String get postsListLoadMore => 'Load more';

  @override
  String get postsListFailedToLoad => 'Failed to load posts.';

  @override
  String get postsListEditTooltip => 'Edit draft';

  @override
  String get postsListNewPostButton => 'New Post';

  @override
  String get postsListEmpty => 'No posts found for this filter.';

  @override
  String get approvalsAppBarTitle => 'Approvals';

  @override
  String get approvalsHeadline => 'Pending approval';

  @override
  String get approvalsSubtitle =>
      'Posts an editor submitted for review — approve to publish/schedule as requested, or reject with an optional note.';

  @override
  String get approvalsFailedToLoad => 'Failed to load the approvals queue.';

  @override
  String get approvalsEmpty => 'Nothing is waiting for approval right now.';

  @override
  String get approvalsLoadMore => 'Load more';

  @override
  String approvalsRequestedByMeta(String name) {
    return 'Requested by $name';
  }

  @override
  String get approvalsRequestedActionSchedule => 'Requested: schedule';

  @override
  String get approvalsRequestedActionPublishNow => 'Requested: publish now';

  @override
  String get approvalsApproveButton => 'Approve';

  @override
  String get approvalsRejectButton => 'Reject';

  @override
  String get approvalsApproveSuccess => 'Post approved.';

  @override
  String get approvalsRejectSuccess => 'Post rejected.';

  @override
  String get approvalsRejectDialogTitle => 'Reject this post?';

  @override
  String get approvalsRejectDialogNoteLabel =>
      'Note for the requester (optional)';

  @override
  String get approvalsRejectDialogConfirm => 'Reject';

  @override
  String postsListPublishedMeta(String date) {
    return 'Published $date';
  }

  @override
  String postsListScheduledMeta(String date) {
    return 'Scheduled $date';
  }

  @override
  String postsListMediaCountMeta(int count) {
    return '$count media';
  }

  @override
  String postsListPlatformsCountMeta(int count) {
    return '$count platforms';
  }

  @override
  String get composerFormatBoldTooltip =>
      'Bold (Telegram only — stripped elsewhere)';

  @override
  String get composerFormatItalicTooltip =>
      'Italic (Telegram only — stripped elsewhere)';

  @override
  String get composerInsertEmojiTooltip => 'Insert emoji';

  @override
  String get moduleHelpCenterTitle => 'Help Center';

  @override
  String moduleHelpCenterDescription(String appName) {
    return 'Guides, FAQs, and how-to steps for using $appName.';
  }

  @override
  String get helpIconTooltip => 'Help';

  @override
  String settingsAboutTitle(String appName) {
    return 'About $appName';
  }

  @override
  String get settingsAboutSubtitle =>
      'Version, supported platforms, and security overview.';

  @override
  String get settingsHelpCenterTitle => 'Help Center';

  @override
  String get settingsHelpCenterSubtitle => 'The full step-by-step user guide.';

  @override
  String welcomeAboutLinkLabel(String appName) {
    return 'About $appName';
  }

  @override
  String aboutAppBarTitle(String appName) {
    return 'About $appName';
  }

  @override
  String aboutSectionDefinitionTitle(String appName) {
    return 'What is $appName?';
  }

  @override
  String get aboutSectionGoalsTitle => 'Goals';

  @override
  String get aboutSectionFeaturesTitle => 'Available features';

  @override
  String get aboutSectionPlatformsTitle => 'Supported platforms';

  @override
  String get aboutSectionRolesTitle => 'Roles within an organization';

  @override
  String get aboutSectionSecurityTitle => 'Security & privacy';

  @override
  String get aboutSectionAppInfoTitle => 'App information';

  @override
  String get aboutSectionTeamTitle => 'Team & ownership';

  @override
  String get aboutAppVersionLabel => 'Version';

  @override
  String get aboutAppBuildLabel => 'Build number';

  @override
  String get aboutAppEnvironmentLabel => 'Environment';

  @override
  String get aboutAppPackageLabel => 'Package identifier';

  @override
  String aboutCopyrightLabel(String year, String holder) {
    return '© $year $holder. All rights reserved.';
  }

  @override
  String get aboutPrivacyPolicyLink => 'Privacy Policy';

  @override
  String get aboutTermsOfServiceLink => 'Terms of Service';

  @override
  String get aboutDataDeletionLink => 'Delete my data';

  @override
  String get aboutSupportLink => 'Support & contact';

  @override
  String get aboutOpenHelpGuideButton => 'Open the user guide';

  @override
  String get aboutLoadErrorMessage =>
      'Some app information could not be loaded.';

  @override
  String get aboutSuperAdminRoleNote =>
      'Platform administrator capabilities are documented separately inside Platform Administration, not shown here.';

  @override
  String get platformStatusAvailableBeta => 'Available (Beta)';

  @override
  String get platformStatusPartial => 'Partially available';

  @override
  String get platformStatusComingSoon => 'Coming soon';

  @override
  String get platformStatusConnect => 'Connect';

  @override
  String get platformStatusDiscoverPages => 'Fetch pages';

  @override
  String get platformStatusTestConnection => 'Test connection';

  @override
  String get platformStatusPublish => 'Publish';

  @override
  String get platformStatusYes => 'Yes';

  @override
  String get platformStatusNo => 'No';

  @override
  String get helpCenterAppBarTitle => 'Help Center';

  @override
  String helpCenterSubtitle(String appName) {
    return 'Everything you need to use $appName.';
  }

  @override
  String get helpCenterSearchHint => 'Search the user guide…';

  @override
  String get helpCenterQuickLinksTitle => 'Quick links';

  @override
  String get helpCenterOpenGuideButton => 'Open the full user guide';

  @override
  String get helpCenterAboutCardTitle => 'About the system';

  @override
  String helpCenterAboutCardSubtitle(String appName) {
    return 'Learn about $appName, its features, and platform status.';
  }

  @override
  String get helpCenterFaqCardTitle => 'Frequently asked questions';

  @override
  String get helpCenterFaqCardSubtitle => 'Quick answers to common questions.';

  @override
  String get helpCenterTroubleshootingCardTitle => 'Troubleshooting';

  @override
  String get helpCenterTroubleshootingCardSubtitle =>
      'Fixes for common error messages.';

  @override
  String get helpCenterNoOrganizationNotice =>
      'You are not a member of any organization yet — some guide sections will only make sense once you join one.';

  @override
  String userGuideAppBarTitle(String appName) {
    return '$appName user guide';
  }

  @override
  String get userGuideSearchHint => 'Search a topic…';

  @override
  String get userGuideTocTitle => 'Table of contents';

  @override
  String get userGuideNoResultsTitle => 'No results';

  @override
  String get userGuideNoResultsMessage => 'Try different search words.';

  @override
  String get userGuideClearSearchButton => 'Clear search';

  @override
  String get userGuideFaqSectionTitle => 'Frequently asked questions';

  @override
  String get userGuideTroubleshootingSectionTitle => 'Troubleshooting';

  @override
  String get userGuideRolePermissionTableTitle => 'Who can do what?';

  @override
  String userGuideRequiredPermissionBadge(String role) {
    return 'Requires: $role';
  }

  @override
  String get userGuideNoOrganizationNotice =>
      'You are not a member of any organization yet — some sections below will apply once you join one.';

  @override
  String get platformAdminGuideButton => 'Admin guide';

  @override
  String get platformAdminGuideDialogTitle => 'Platform administrator guide';

  @override
  String get platformAdminUnexpectedError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get platformAdminOwnerListLoadError => 'Failed to load the user list.';

  @override
  String get platformAdminRoleOwner => 'Organization owner';

  @override
  String get platformAdminRoleAdmin => 'Organization admin';

  @override
  String get platformAdminRoleManager => 'Manager';

  @override
  String get platformAdminRoleEditor => 'Editor';

  @override
  String get platformAdminRoleViewer => 'Viewer';

  @override
  String get platformAdminNotAvailable => 'Not available';

  @override
  String get platformAdminCreateOrgButton => 'Create organization';

  @override
  String get platformAdminGuideCreateOrgBody =>
      'From \"Organizations\", tap \"Create organization\" — pick an existing owner or create a new one with a password of at least 12 characters.';

  @override
  String get platformAdminManageUsersButton => 'Manage system users';

  @override
  String get platformAdminGuideUsersBody =>
      'From \"System users\": activate/deactivate an account, grant or revoke platform administrator access, and edit a user\'s memberships across organizations.';

  @override
  String get platformAdminOAuthSettingsButton => 'OAuth provider settings';

  @override
  String get platformAdminGuideOAuthBody =>
      'App ID and App Secret for each provider — protected exclusively by the platform administrator permission, entirely separate from organization roles.';

  @override
  String get platformAdminAuditLogButton => 'Platform audit log';

  @override
  String get platformAdminGuideAuditBody =>
      'Logs every sensitive administrative action (disabling an organization, changing an admin\'s role, editing OAuth settings) for later review.';

  @override
  String get platformAdminAboutSystemButton => 'About the system';

  @override
  String get platformAdminAppBarTitle => 'Platform administration';

  @override
  String get platformAdminManageUsersShortcut => 'Manage users';

  @override
  String get platformAdminRefreshTooltip => 'Refresh data';

  @override
  String get platformAdminOverviewTitle => 'Platform overview';

  @override
  String get platformAdminOverviewSubtitle =>
      'Live data from the system via platform administration permissions.';

  @override
  String get platformAdminMetricOrgsTotal => 'Total organizations';

  @override
  String get platformAdminMetricOrgsActive => 'Active organizations';

  @override
  String get platformAdminMetricOrgsInactive => 'Inactive organizations';

  @override
  String get platformAdminMetricUsersTotal => 'Total users';

  @override
  String get platformAdminMetricUsersNew30d => 'New users (30 days)';

  @override
  String get platformAdminMetricOrgsWithoutOwner => 'Without an active owner';

  @override
  String get platformAdminManageOrgsButton => 'Manage organizations';

  @override
  String get platformAdminLatestOrgsTitle => 'Latest organizations';

  @override
  String get platformAdminNoRecentOrgsTitle => 'No recent organizations';

  @override
  String get platformAdminNoRecentOrgsMessage =>
      'Organizations will appear here once created.';

  @override
  String get platformAdminLatestUsersTitle => 'Latest users';

  @override
  String get platformAdminNoRecentUsersTitle => 'No recent users';

  @override
  String get platformAdminNoRecentUsersMessage =>
      'Newly created accounts will appear here.';

  @override
  String get platformAdminDisableOrgTitle => 'Disable organization';

  @override
  String get platformAdminEnableOrgTitle => 'Re-enable organization';

  @override
  String platformAdminDisableOrgMessage(String name) {
    return '\"$name\" will be disabled. No data will be deleted.';
  }

  @override
  String platformAdminEnableOrgMessage(String name) {
    return '\"$name\" will be re-enabled.';
  }

  @override
  String get platformAdminOrgDisabledMessage => 'Organization disabled.';

  @override
  String get platformAdminOrgEnabledMessage => 'Organization enabled.';

  @override
  String get platformAdminNoEligibleOwnerMessage =>
      'No eligible member to take ownership — assign the owner role to a member first.';

  @override
  String platformAdminPrimaryOwnerAssignedMessage(String name) {
    return 'Primary owner assigned: $name.';
  }

  @override
  String get platformAdminOrgsAppBarTitle => 'Organizations';

  @override
  String get platformAdminSearchByNameOrOwnerHint => 'Search by name or owner';

  @override
  String get platformAdminSearchTooltip => 'Search';

  @override
  String get platformAdminFilterAllChip => 'All';

  @override
  String get platformAdminOrgActiveStatus => 'Active';

  @override
  String get platformAdminOrgInactiveStatus => 'Inactive';

  @override
  String get platformAdminNoMatchingOrgsTitle => 'No matching organizations';

  @override
  String get platformAdminNoMatchingOrgsMessage =>
      'Try adjusting your search terms or create a new organization.';

  @override
  String get platformAdminOrgDetailAppBarTitle => 'Organization details';

  @override
  String get platformAdminActivateAccountTitle => 'Activate account';

  @override
  String get platformAdminDeactivateAccountTitle => 'Deactivate account';

  @override
  String platformAdminActivateAccountMessage(String email) {
    return '$email\'s account will be activated.';
  }

  @override
  String platformAdminDeactivateAccountMessage(String email) {
    return '$email\'s account will be deactivated and its current sessions ended.';
  }

  @override
  String get platformAdminAccountActivatedMessage => 'Account activated.';

  @override
  String get platformAdminAccountDeactivatedMessage => 'Account deactivated.';

  @override
  String get platformAdminGrantSuperAdminTitle =>
      'Grant platform administrator';

  @override
  String get platformAdminRevokeSuperAdminTitle =>
      'Revoke platform administrator';

  @override
  String platformAdminGrantSuperAdminMessage(String email) {
    return '$email will be granted independent platform administration access.';
  }

  @override
  String platformAdminRevokeSuperAdminMessage(String email) {
    return '$email\'s access to platform administration will be revoked.';
  }

  @override
  String get platformAdminSuperAdminGrantedMessage =>
      'Platform administrator access granted.';

  @override
  String get platformAdminSuperAdminRevokedMessage =>
      'Platform administrator access revoked.';

  @override
  String get platformAdminUsersAppBarTitle => 'System users';

  @override
  String get platformAdminAddUserButton => 'Add user';

  @override
  String get platformAdminSearchByNameOrEmailHint => 'Search by name or email';

  @override
  String get platformAdminActiveOnlyChip => 'Active only';

  @override
  String get platformAdminInactiveOnlyChip => 'Inactive only';

  @override
  String get platformAdminSuperAdminsChip => 'Platform administrators';

  @override
  String get platformAdminAllOrgsOption => 'All organizations';

  @override
  String get platformAdminAllRolesOption => 'All roles';

  @override
  String get platformAdminNoMatchingUsersTitle => 'No matching accounts';

  @override
  String get platformAdminNoMatchingUsersMessage =>
      'Adjust the filters or add a new user.';

  @override
  String get platformAdminFilterByActionHint => 'Filter by action';

  @override
  String get platformAdminNoMatchingEventsTitle => 'No matching events';

  @override
  String get platformAdminNoMatchingEventsMessage =>
      'Try adjusting the filters.';

  @override
  String get platformAdminViewAllButton => 'View all';

  @override
  String platformAdminOrgCountLabel(int count) {
    return '$count organizations';
  }

  @override
  String platformAdminUserCountLabel(int count) {
    return '$count users';
  }

  @override
  String get platformAdminEditOrgNameMenuItem => 'Edit organization name';

  @override
  String get platformAdminReactivateMenuItem => 'Re-activate';

  @override
  String get platformAdminPrimaryOwnerMissingLabel => 'No primary owner';

  @override
  String platformAdminMembersCountLabel(int count) {
    return '$count members';
  }

  @override
  String get platformAdminFixButton => 'Fix';

  @override
  String get platformAdminPrimaryOwnerMissingBannerBody =>
      'An active Owner membership exists but has not been designated as the primary owner — this can affect governance, alerts, and ownership transfer.';

  @override
  String platformAdminOrgSummaryLine(String owner, int count, String date) {
    return '$owner · $count members · created $date';
  }

  @override
  String platformAdminLastActivityLabel(String date) {
    return 'Last activity: $date';
  }

  @override
  String get platformAdminMembersSectionTitle => 'Members and roles';

  @override
  String get platformAdminNoMembersTitle => 'No members';

  @override
  String get platformAdminNoMembersMessage =>
      'No memberships recorded for this organization.';

  @override
  String get platformAdminSocialAccountsSectionTitle =>
      'Connected social accounts';

  @override
  String get platformAdminNoSocialAccountsTitle => 'No connected accounts';

  @override
  String get platformAdminNoSocialAccountsMessage =>
      'No access tokens or secrets are shown here.';

  @override
  String get platformAdminUnnamedAccountFallback => 'Account';

  @override
  String get platformAdminUnnamedFallback => 'Unnamed';

  @override
  String get platformAdminPostsSummarySectionTitle => 'Posts summary';

  @override
  String get platformAdminNoPostsTitle => 'No posts';

  @override
  String get platformAdminNoPostsMessage =>
      'A status summary will appear once posts exist.';

  @override
  String get platformAdminEditUserDataMenuItem => 'Edit details';

  @override
  String get platformAdminManageMembershipsMenuItem => 'Manage memberships';

  @override
  String get platformAdminNoOrgLabel => 'No organization';

  @override
  String get platformAdminSuperAdminBadge => 'Platform administrator';

  @override
  String get platformAdminActiveLabel => 'Active';

  @override
  String get platformAdminInactiveLabel => 'Inactive';

  @override
  String get platformAdminPreviousPageButton => 'Previous';

  @override
  String platformAdminPageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get platformAdminUnauthorizedTitle => 'You are not authorized';

  @override
  String get platformAdminLoadErrorTitle => 'Failed to load data';

  @override
  String get platformAdminForbiddenMessage =>
      'The server denied access. Make sure the account has platform administrator permission.';

  @override
  String get platformAdminGenericLoadErrorMessage =>
      'Failed to connect to platform administration data. Please try again.';

  @override
  String get platformAdminOrgNameLabel => 'Organization name';

  @override
  String get platformAdminOrgNameRequiredError =>
      'Organization name is required.';

  @override
  String get platformAdminNewOwnerSegment => 'New owner';

  @override
  String get platformAdminExistingOwnerSegment => 'Existing owner';

  @override
  String get platformAdminOwnerFieldLabel => 'Organization owner';

  @override
  String get platformAdminSelectActiveOwnerError => 'Select an active owner.';

  @override
  String get platformAdminNewOwnerNameLabel => 'Owner name';

  @override
  String get platformAdminNewOwnerNameRequiredError =>
      'Owner name is required.';

  @override
  String get platformAdminNewOwnerEmailLabel => 'Owner email';

  @override
  String get platformAdminValidEmailRequiredError =>
      'Enter a valid email address.';

  @override
  String get platformAdminValidEmailShortError => 'Enter a valid email.';

  @override
  String get platformAdminNewOwnerPasswordLabel =>
      'Owner password (at least 12 characters)';

  @override
  String get platformAdminPasswordMinLengthError =>
      'Enter a password of at least 12 characters.';

  @override
  String get platformAdminCreateOrgSubmitButton => 'Create organization';

  @override
  String get platformAdminNameLabel => 'Name';

  @override
  String get platformAdminNameRequiredError => 'Name is required.';

  @override
  String get platformAdminEmailLabel => 'Email';

  @override
  String get platformAdminPasswordLabel => 'Password (at least 12 characters)';

  @override
  String get platformAdminNoOrgOption => 'No organization';

  @override
  String get platformAdminAddButtonShort => 'Add';

  @override
  String get platformAdminEditUserDialogTitle => 'Edit user details';

  @override
  String platformAdminMembershipsDialogTitle(String name) {
    return '$name\'s memberships';
  }

  @override
  String get platformAdminMembershipsHint =>
      'Changing an owner\'s role or removing their membership requires at least one active owner to remain; the server enforces this as the final check.';

  @override
  String get platformAdminRemoveMembershipTooltip => 'Remove membership';

  @override
  String get platformAdminAddToOrgLabel => 'Add to an organization';

  @override
  String get platformAdminSaveMembershipsButton => 'Save memberships';

  @override
  String get platformAdminConfirmActionButton => 'Confirm action';
}
