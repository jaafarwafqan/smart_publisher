import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown in the OS task switcher / title bar.
  ///
  /// In ar, this message translates to:
  /// **'الناشر الذكي'**
  String get appName;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدر النشر والجدولة والحسابات والتسليم من واجهة تحكم واحدة.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeContinueButton.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة إلى تسجيل الدخول'**
  String get welcomeContinueButton;

  /// No description provided for @notFoundTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة غير موجودة'**
  String get notFoundTitle;

  /// No description provided for @notFoundSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة التي تبحث عنها غير موجودة أو ربما تم نقلها.'**
  String get notFoundSubtitle;

  /// No description provided for @notFoundGoHomeButton.
  ///
  /// In ar, this message translates to:
  /// **'الذهاب إلى لوحة التحكم'**
  String get notFoundGoHomeButton;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get commonConfirm;

  /// No description provided for @commonClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get commonNext;

  /// No description provided for @commonDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get commonLoading;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonYes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get commonNo;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول إلى الناشر الذكي'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لإدارة مساحة عملك للنشر.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get loginPasswordLabel;

  /// No description provided for @loginEmailValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get loginEmailValidationError;

  /// No description provided for @loginPasswordValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة مرور صحيحة'**
  String get loginPasswordValidationError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني أو كلمة المرور غير صحيحة.'**
  String get authInvalidCredentials;

  /// No description provided for @authConnectionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الوصول إلى الخادم. تحقق من اتصالك بالإنترنت.'**
  String get authConnectionError;

  /// No description provided for @authGenericFailure.
  ///
  /// In ar, this message translates to:
  /// **'فشلت المصادقة. يرجى المحاولة مرة أخرى.'**
  String get authGenericFailure;

  /// No description provided for @loginButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginButton;

  /// No description provided for @loginForgotPasswordLink.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get loginForgotPasswordLink;

  /// No description provided for @loginNoAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get loginNoAccountPrompt;

  /// No description provided for @loginCreateAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حسابًا'**
  String get loginCreateAccountLink;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حسابك'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أعدّ مساحة عمل Smart Publisher الخاصة بك.'**
  String get registerSubtitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get registerNameLabel;

  /// No description provided for @registerNameValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك'**
  String get registerNameValidationError;

  /// No description provided for @registerEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get registerEmailLabel;

  /// No description provided for @registerEmailValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get registerEmailValidationError;

  /// No description provided for @registerPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get registerPasswordLabel;

  /// No description provided for @registerPasswordValidationError.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل'**
  String get registerPasswordValidationError;

  /// No description provided for @registerPasswordConfirmationLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get registerPasswordConfirmationLabel;

  /// No description provided for @registerPasswordConfirmationValidationError.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get registerPasswordConfirmationValidationError;

  /// No description provided for @registerButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get registerButton;

  /// No description provided for @registerHaveAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get registerHaveAccountPrompt;

  /// No description provided for @registerLoginLink.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get registerLoginLink;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل البريد الإلكتروني لحسابك وسنرسل لك رابط إعادة تعيين كلمة المرور.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordEmailValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get forgotPasswordEmailValidationError;

  /// No description provided for @forgotPasswordSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط إعادة التعيين'**
  String get forgotPasswordSubmitButton;

  /// No description provided for @forgotPasswordSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'إذا كان هناك حساب مرتبط بهذا البريد الإلكتروني، فقد تم إرسال رابط إعادة تعيين كلمة المرور.'**
  String get forgotPasswordSuccessMessage;

  /// No description provided for @forgotPasswordHaveTokenLink.
  ///
  /// In ar, this message translates to:
  /// **'لديك رمز إعادة تعيين بالفعل؟'**
  String get forgotPasswordHaveTokenLink;

  /// No description provided for @forgotPasswordBackToLoginLink.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get forgotPasswordBackToLoginLink;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كلمة مرور جديدة'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز إعادة التعيين من بريدك الإلكتروني مع كلمة المرور الجديدة.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get resetPasswordEmailLabel;

  /// No description provided for @resetPasswordTokenLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز إعادة التعيين'**
  String get resetPasswordTokenLabel;

  /// No description provided for @resetPasswordNewPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get resetPasswordNewPasswordLabel;

  /// No description provided for @resetPasswordPasswordValidationError.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل'**
  String get resetPasswordPasswordValidationError;

  /// No description provided for @resetPasswordConfirmPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور الجديدة'**
  String get resetPasswordConfirmPasswordLabel;

  /// No description provided for @resetPasswordConfirmPasswordValidationError.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get resetPasswordConfirmPasswordValidationError;

  /// No description provided for @resetPasswordSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة تعيين كلمة المرور'**
  String get resetPasswordSubmitButton;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إعادة تعيين كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول.'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @resetPasswordBackToLoginLink.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get resetPasswordBackToLoginLink;

  /// No description provided for @twoFactorChallengeTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحقق بخطوتين'**
  String get twoFactorChallengeTitle;

  /// No description provided for @twoFactorChallengeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام من تطبيق المصادقة.'**
  String get twoFactorChallengeSubtitle;

  /// No description provided for @twoFactorChallengeCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get twoFactorChallengeCodeLabel;

  /// No description provided for @twoFactorChallengeCodeValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get twoFactorChallengeCodeValidationError;

  /// No description provided for @twoFactorChallengeUseRecoveryCodeLink.
  ///
  /// In ar, this message translates to:
  /// **'استخدام رمز استرداد بدلاً من ذلك'**
  String get twoFactorChallengeUseRecoveryCodeLink;

  /// No description provided for @twoFactorChallengeRecoveryCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز الاسترداد'**
  String get twoFactorChallengeRecoveryCodeLabel;

  /// No description provided for @twoFactorChallengeRecoveryCodeValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز استرداد'**
  String get twoFactorChallengeRecoveryCodeValidationError;

  /// No description provided for @twoFactorChallengeUseCodeLink.
  ///
  /// In ar, this message translates to:
  /// **'استخدام رمز تطبيق المصادقة بدلاً من ذلك'**
  String get twoFactorChallengeUseCodeLink;

  /// No description provided for @twoFactorChallengeSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'تحقق'**
  String get twoFactorChallengeSubmitButton;

  /// No description provided for @logoutTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutTooltip;

  /// No description provided for @performanceTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الأداء'**
  String get performanceTooltip;

  /// No description provided for @dashboardStatPosts.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get dashboardStatPosts;

  /// No description provided for @dashboardStatScheduled.
  ///
  /// In ar, this message translates to:
  /// **'مجدولة'**
  String get dashboardStatScheduled;

  /// No description provided for @dashboardStatPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشورة'**
  String get dashboardStatPublished;

  /// No description provided for @dashboardStatFailed.
  ///
  /// In ar, this message translates to:
  /// **'فاشلة'**
  String get dashboardStatFailed;

  /// No description provided for @dashboardStatAccounts.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات'**
  String get dashboardStatAccounts;

  /// No description provided for @dashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راقب المنشورات والجدولة وصحة النشر والمنصات المتصلة من مكان واحد.'**
  String get dashboardSubtitle;

  /// No description provided for @dashboardAuthenticatedUserFallback.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم مسجّل الدخول'**
  String get dashboardAuthenticatedUserFallback;

  /// No description provided for @dashboardNoEmailFallback.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد بريد إلكتروني'**
  String get dashboardNoEmailFallback;

  /// No description provided for @dashboardGuestRole.
  ///
  /// In ar, this message translates to:
  /// **'زائر'**
  String get dashboardGuestRole;

  /// No description provided for @dashboardRoleOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك المؤسسة'**
  String get dashboardRoleOwner;

  /// No description provided for @dashboardRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get dashboardRoleAdmin;

  /// No description provided for @dashboardRoleManager.
  ///
  /// In ar, this message translates to:
  /// **'مشرف'**
  String get dashboardRoleManager;

  /// No description provided for @dashboardRoleEditor.
  ///
  /// In ar, this message translates to:
  /// **'محرر'**
  String get dashboardRoleEditor;

  /// No description provided for @dashboardRoleViewer.
  ///
  /// In ar, this message translates to:
  /// **'مشاهد'**
  String get dashboardRoleViewer;

  /// No description provided for @dashboardChooseOrganizationRole.
  ///
  /// In ar, this message translates to:
  /// **'اختر مؤسسة'**
  String get dashboardChooseOrganizationRole;

  /// No description provided for @dashboardNoActiveMembershipRole.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عضوية نشطة'**
  String get dashboardNoActiveMembershipRole;

  /// No description provided for @dashboardCreatePostButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منشور'**
  String get dashboardCreatePostButton;

  /// No description provided for @dashboardPostsButton.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get dashboardPostsButton;

  /// No description provided for @dashboardApprovalsButton.
  ///
  /// In ar, this message translates to:
  /// **'الموافقات'**
  String get dashboardApprovalsButton;

  /// No description provided for @dashboardLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل لوحة التحكم. تحقق من الاتصال ثم أعد المحاولة.'**
  String get dashboardLoadFailed;

  /// No description provided for @dashboardSectionScheduledTodayTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجدولة اليوم'**
  String get dashboardSectionScheduledTodayTitle;

  /// No description provided for @dashboardSectionScheduledTodayEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء مجدول لهذا اليوم.'**
  String get dashboardSectionScheduledTodayEmpty;

  /// No description provided for @dashboardSectionPublishingQueueTitle.
  ///
  /// In ar, this message translates to:
  /// **'طابور النشر'**
  String get dashboardSectionPublishingQueueTitle;

  /// No description provided for @dashboardSectionPublishingQueueEmpty.
  ///
  /// In ar, this message translates to:
  /// **'الطابور فارغ.'**
  String get dashboardSectionPublishingQueueEmpty;

  /// No description provided for @dashboardSectionFailedPostsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات الفاشلة'**
  String get dashboardSectionFailedPostsTitle;

  /// No description provided for @dashboardSectionFailedPostsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد عمليات نشر فاشلة.'**
  String get dashboardSectionFailedPostsEmpty;

  /// No description provided for @dashboardSectionLastPublishedTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر ما تم نشره'**
  String get dashboardSectionLastPublishedTitle;

  /// No description provided for @dashboardSectionLastPublishedEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم يُنشر شيء بعد.'**
  String get dashboardSectionLastPublishedEmpty;

  /// No description provided for @dashboardSectionUpcomingScheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجدولة القادمة'**
  String get dashboardSectionUpcomingScheduleTitle;

  /// No description provided for @dashboardSectionUpcomingScheduleEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات مجدولة قادمة.'**
  String get dashboardSectionUpcomingScheduleEmpty;

  /// No description provided for @moduleMediaLibraryTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الوسائط'**
  String get moduleMediaLibraryTitle;

  /// No description provided for @moduleMediaLibraryDescription.
  ///
  /// In ar, this message translates to:
  /// **'الصور والفيديوهات والمرفقات.'**
  String get moduleMediaLibraryDescription;

  /// No description provided for @moduleCalendarTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقويم'**
  String get moduleCalendarTitle;

  /// No description provided for @moduleCalendarDescription.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات المجدولة عبر كل الأيام.'**
  String get moduleCalendarDescription;

  /// No description provided for @moduleCalendarBadge.
  ///
  /// In ar, this message translates to:
  /// **'{count} اليوم'**
  String moduleCalendarBadge(int count);

  /// No description provided for @moduleAnalyticsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحليلات'**
  String get moduleAnalyticsTitle;

  /// No description provided for @moduleAnalyticsDescription.
  ///
  /// In ar, this message translates to:
  /// **'أداء التفاعل والتسليم.'**
  String get moduleAnalyticsDescription;

  /// No description provided for @moduleNotificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get moduleNotificationsTitle;

  /// No description provided for @moduleNotificationsDescription.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات وتحديثات الحسابات.'**
  String get moduleNotificationsDescription;

  /// No description provided for @moduleSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get moduleSettingsTitle;

  /// No description provided for @moduleSettingsDescription.
  ///
  /// In ar, this message translates to:
  /// **'تفضيلات مساحة العمل.'**
  String get moduleSettingsDescription;

  /// No description provided for @moduleAdministrationTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get moduleAdministrationTitle;

  /// No description provided for @moduleAdministrationDescription.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون والأدوار والفروع.'**
  String get moduleAdministrationDescription;

  /// No description provided for @moduleProductionReleaseTitle.
  ///
  /// In ar, this message translates to:
  /// **'إصدار الإنتاج'**
  String get moduleProductionReleaseTitle;

  /// No description provided for @moduleProductionReleaseDescription.
  ///
  /// In ar, this message translates to:
  /// **'قائمة جاهزية الإصدار.'**
  String get moduleProductionReleaseDescription;

  /// No description provided for @accountConnectedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الاتصال بـ{name} بنجاح.'**
  String accountConnectedSuccess(String name);

  /// No description provided for @accountConnectFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاتصال بـ{name}.'**
  String accountConnectFailed(String name);

  /// No description provided for @telegramBotConnectedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم ربط بوت تيليجرام بنجاح.'**
  String get telegramBotConnectedSuccess;

  /// No description provided for @telegramBotConnectFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل ربط بوت تيليجرام.'**
  String get telegramBotConnectFailed;

  /// No description provided for @platformConnectionStartFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل بدء الاتصال بـ{platform}.'**
  String platformConnectionStartFailed(String platform);

  /// No description provided for @platformConnectionCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الاتصال بـ{platform}.'**
  String platformConnectionCancelled(String platform);

  /// No description provided for @platformConnectedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الاتصال بـ{platform} بنجاح.'**
  String platformConnectedSuccess(String platform);

  /// No description provided for @whatsappBusinessIdSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ معرّف النشاط التجاري — اضغط مزامنة الصفحات لاكتشاف أرقام واتساب الخاصة بك.'**
  String get whatsappBusinessIdSaved;

  /// No description provided for @whatsappBusinessIdSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ معرّف النشاط التجاري لواتساب.'**
  String get whatsappBusinessIdSaveFailed;

  /// No description provided for @instagramDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنستغرام يتصل عبر فيسبوك'**
  String get instagramDialogTitle;

  /// No description provided for @instagramDialogBody.
  ///
  /// In ar, this message translates to:
  /// **'لا تملك حسابات إنستغرام للأعمال تسجيل دخول منفصلًا خاصًا بها — يتم اكتشافها تلقائيًا من خلال اتصال فيسبوك الخاص بك. اتصل بفيسبوك، ثم اضغط \"مزامنة الصفحات\" لجلب أي حساب إنستغرام للأعمال مرتبط.'**
  String get instagramDialogBody;

  /// No description provided for @gotIt.
  ///
  /// In ar, this message translates to:
  /// **'فهمت'**
  String get gotIt;

  /// No description provided for @pagesSyncedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت مزامنة الصفحات لـ{name}.'**
  String pagesSyncedSuccess(String name);

  /// No description provided for @pagesSyncFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت مزامنة الصفحات لـ{name}.'**
  String pagesSyncFailed(String name);

  /// No description provided for @channelAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة القناة إلى {name}.'**
  String channelAddedSuccess(String name);

  /// No description provided for @channelAddFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت إضافة القناة إلى {name}.'**
  String channelAddFailed(String name);

  /// No description provided for @selectedPagesUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الصفحات المختارة لـ{name}.'**
  String selectedPagesUpdatedSuccess(String name);

  /// No description provided for @selectedPagesUpdateFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديث الصفحات المختارة.'**
  String get selectedPagesUpdateFailed;

  /// No description provided for @pageRemovedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إزالة الصفحة من {name}.'**
  String pageRemovedSuccess(String name);

  /// No description provided for @pageRemoveFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت إزالة الصفحة.'**
  String get pageRemoveFailed;

  /// No description provided for @accountDisconnectedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم فصل {name}.'**
  String accountDisconnectedSuccess(String name);

  /// No description provided for @accountDisconnectFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل فصل {name}.'**
  String accountDisconnectFailed(String name);

  /// No description provided for @refreshTokenRequestedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم طلب تحديث الرمز لـ{name}.'**
  String refreshTokenRequestedSuccess(String name);

  /// No description provided for @refreshTokenFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديث الرمز لـ{name}.'**
  String refreshTokenFailed(String name);

  /// No description provided for @testConnectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل اختبار الاتصال لـ{name}.'**
  String testConnectionFailed(String name);

  /// No description provided for @accountCardNoPermissions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صلاحيات مُسندة'**
  String get accountCardNoPermissions;

  /// No description provided for @accountCardTokenExpires.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء صلاحية الرمز: {date}'**
  String accountCardTokenExpires(String date);

  /// No description provided for @accountCardLastSynced.
  ///
  /// In ar, this message translates to:
  /// **'آخر مزامنة: {date}'**
  String accountCardLastSynced(String date);

  /// No description provided for @accountCardLastPublished.
  ///
  /// In ar, this message translates to:
  /// **'آخر نشر: {date}'**
  String accountCardLastPublished(String date);

  /// No description provided for @accountCardTodayPrefix.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get accountCardTodayPrefix;

  /// No description provided for @accountCardWhatsappSendingUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الإرسال غير متاح بعد لواتساب — يمكنك الاتصال لاكتشاف الأرقام، لكن النشر سيبقى محظورًا حتى إطلاق هذه الميزة.'**
  String get accountCardWhatsappSendingUnavailable;

  /// No description provided for @betaTag.
  ///
  /// In ar, this message translates to:
  /// **'تجريبي'**
  String get betaTag;

  /// No description provided for @comingSoonSuffix.
  ///
  /// In ar, this message translates to:
  /// **'{platform} — قريبًا'**
  String comingSoonSuffix(String platform);

  /// No description provided for @accountStatusConnected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get accountStatusConnected;

  /// No description provided for @accountStatusExpired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي الصلاحية'**
  String get accountStatusExpired;

  /// No description provided for @accountStatusRevoked.
  ///
  /// In ar, this message translates to:
  /// **'مُلغى'**
  String get accountStatusRevoked;

  /// No description provided for @accountStatusFailed.
  ///
  /// In ar, this message translates to:
  /// **'فاشل'**
  String get accountStatusFailed;

  /// No description provided for @accountStatusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار…'**
  String get accountStatusPending;

  /// No description provided for @accountStatusDisconnected.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل'**
  String get accountStatusDisconnected;

  /// No description provided for @actionTestConnection.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الاتصال'**
  String get actionTestConnection;

  /// No description provided for @actionDisconnect.
  ///
  /// In ar, this message translates to:
  /// **'قطع الاتصال'**
  String get actionDisconnect;

  /// No description provided for @actionRefreshToken.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الرمز'**
  String get actionRefreshToken;

  /// No description provided for @actionReauthenticate.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المصادقة'**
  String get actionReauthenticate;

  /// No description provided for @actionWorkingOnIt.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ العمل عليه…'**
  String get actionWorkingOnIt;

  /// No description provided for @actionConnect.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get actionConnect;

  /// No description provided for @accountsGridTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات'**
  String get accountsGridTitle;

  /// No description provided for @accountsGridLoadingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مساحات العمل المتصلة والصلاحيات عبر جميع المنصات.'**
  String get accountsGridLoadingSubtitle;

  /// No description provided for @accountsGridSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة حسابات فيسبوك وإنستغرام وتيليجرام وواتساب ولينكد إن وX.'**
  String get accountsGridSubtitle;

  /// No description provided for @postStatusSectionDefaultEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء هنا الآن.'**
  String get postStatusSectionDefaultEmpty;

  /// No description provided for @postUntitled.
  ///
  /// In ar, this message translates to:
  /// **'منشور بلا عنوان'**
  String get postUntitled;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @publishingHealthTitle.
  ///
  /// In ar, this message translates to:
  /// **'صحة النشر'**
  String get publishingHealthTitle;

  /// No description provided for @publishingHealthSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لمحة تشغيلية حالية عبر التسليم والحسابات.'**
  String get publishingHealthSubtitle;

  /// No description provided for @publishingHealthConnectedAccounts.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات المتصلة'**
  String get publishingHealthConnectedAccounts;

  /// No description provided for @publishingHealthQueueHealth.
  ///
  /// In ar, this message translates to:
  /// **'صحة الطابور'**
  String get publishingHealthQueueHealth;

  /// No description provided for @publishingHealthNeedsAttention.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج إلى انتباه'**
  String get publishingHealthNeedsAttention;

  /// No description provided for @publishingHealthStable.
  ///
  /// In ar, this message translates to:
  /// **'مستقر'**
  String get publishingHealthStable;

  /// No description provided for @publishingHealthFailedDeliveries.
  ///
  /// In ar, this message translates to:
  /// **'عمليات التسليم الفاشلة'**
  String get publishingHealthFailedDeliveries;

  /// No description provided for @publishingHealthDistributionByPlatform.
  ///
  /// In ar, this message translates to:
  /// **'التوزيع حسب المنصة'**
  String get publishingHealthDistributionByPlatform;

  /// No description provided for @publishingHealthSuccess.
  ///
  /// In ar, this message translates to:
  /// **'نجاح'**
  String get publishingHealthSuccess;

  /// No description provided for @recentActivityTitle.
  ///
  /// In ar, this message translates to:
  /// **'النشاط الأخير'**
  String get recentActivityTitle;

  /// No description provided for @recentActivitySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أحدث عناصر النشر وعمليات المنشورات.'**
  String get recentActivitySubtitle;

  /// No description provided for @recentActivityEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات بعد — أنشئ واحدًا لتراه هنا.'**
  String get recentActivityEmpty;

  /// No description provided for @activityPublishedTo.
  ///
  /// In ar, this message translates to:
  /// **'نُشر على {platform}'**
  String activityPublishedTo(String platform);

  /// No description provided for @activityFailedOn.
  ///
  /// In ar, this message translates to:
  /// **'فشل على {platform}'**
  String activityFailedOn(String platform);

  /// No description provided for @activityPartiallyPublished.
  ///
  /// In ar, this message translates to:
  /// **'نُشر جزئيًا — فشلت بعض الوجهات'**
  String get activityPartiallyPublished;

  /// No description provided for @activityCancelled.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي قبل النشر'**
  String get activityCancelled;

  /// No description provided for @activityCurrentlyPublishing.
  ///
  /// In ar, this message translates to:
  /// **'يُنشر الآن'**
  String get activityCurrentlyPublishing;

  /// No description provided for @activitySavedAsDraft.
  ///
  /// In ar, this message translates to:
  /// **'محفوظ كمسودة'**
  String get activitySavedAsDraft;

  /// No description provided for @activityScheduledForPublishing.
  ///
  /// In ar, this message translates to:
  /// **'مجدول للنشر'**
  String get activityScheduledForPublishing;

  /// No description provided for @activityScheduledForToday.
  ///
  /// In ar, this message translates to:
  /// **'مجدول لليوم'**
  String get activityScheduledForToday;

  /// No description provided for @activityScheduledForTomorrow.
  ///
  /// In ar, this message translates to:
  /// **'مجدول للغد'**
  String get activityScheduledForTomorrow;

  /// No description provided for @activityScheduledForDate.
  ///
  /// In ar, this message translates to:
  /// **'مجدول لـ{date}'**
  String activityScheduledForDate(String date);

  /// No description provided for @activityThePlatform.
  ///
  /// In ar, this message translates to:
  /// **'المنصة'**
  String get activityThePlatform;

  /// No description provided for @workspaceModulesTitle.
  ///
  /// In ar, this message translates to:
  /// **'وحدات مساحة العمل'**
  String get workspaceModulesTitle;

  /// No description provided for @workspaceModulesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الوصول إلى مكتبة الوسائط والتقويم والتحليلات والإشعارات والإعدادات والإدارة وإصدار الإنتاج.'**
  String get workspaceModulesSubtitle;

  /// No description provided for @pagesPanelNoneYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صفحات أو قنوات بعد'**
  String get pagesPanelNoneYet;

  /// No description provided for @pagesPanelCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} صفحة/قناة'**
  String pagesPanelCount(int count);

  /// No description provided for @pagesPanelSyncPages.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة الصفحات'**
  String get pagesPanelSyncPages;

  /// No description provided for @pagesPanelAddChannel.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قناة'**
  String get pagesPanelAddChannel;

  /// No description provided for @pagesPanelNothingAdded.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة شيء بعد.'**
  String get pagesPanelNothingAdded;

  /// No description provided for @pagesPanelMembersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} أعضاء'**
  String pagesPanelMembersCount(int count);

  /// No description provided for @pagesPanelRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة'**
  String get pagesPanelRemove;

  /// No description provided for @pagesPanelSaveSelection.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الاختيار'**
  String get pagesPanelSaveSelection;

  /// No description provided for @pageKindInstagram.
  ///
  /// In ar, this message translates to:
  /// **'إنستغرام'**
  String get pageKindInstagram;

  /// No description provided for @pageKindWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get pageKindWhatsapp;

  /// No description provided for @pageKindChannel.
  ///
  /// In ar, this message translates to:
  /// **'قناة'**
  String get pageKindChannel;

  /// No description provided for @pageKindPage.
  ///
  /// In ar, this message translates to:
  /// **'صفحة'**
  String get pageKindPage;

  /// No description provided for @pageStatusValid.
  ///
  /// In ar, this message translates to:
  /// **'صالح'**
  String get pageStatusValid;

  /// No description provided for @pageStatusNeedsReauth.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج إعادة مصادقة'**
  String get pageStatusNeedsReauth;

  /// No description provided for @pageStatusInvalid.
  ///
  /// In ar, this message translates to:
  /// **'غير صالح'**
  String get pageStatusInvalid;

  /// No description provided for @addTelegramChannelTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قناة تيليجرام'**
  String get addTelegramChannelTitle;

  /// No description provided for @addTelegramChannelBody.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من أن البوت مُشرف بالفعل في القناة، ثم أدخل اسمها (@username) أو معرّفها الرقمي.'**
  String get addTelegramChannelBody;

  /// No description provided for @addTelegramChannelLabel.
  ///
  /// In ar, this message translates to:
  /// **'القناة'**
  String get addTelegramChannelLabel;

  /// No description provided for @addTelegramChannelHint.
  ///
  /// In ar, this message translates to:
  /// **'@my_channel أو -1001234567890'**
  String get addTelegramChannelHint;

  /// No description provided for @addTelegramChannelAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get addTelegramChannelAdd;

  /// No description provided for @connectTelegramBotTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط بوت تيليجرام'**
  String get connectTelegramBotTitle;

  /// No description provided for @connectTelegramBotBody.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ بوتًا عبر @BotFather في تيليجرام، ثم الصق رمزه (Token) أدناه.'**
  String get connectTelegramBotBody;

  /// No description provided for @connectTelegramBotLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز البوت'**
  String get connectTelegramBotLabel;

  /// No description provided for @connectTelegramBotConnect.
  ///
  /// In ar, this message translates to:
  /// **'اتصال'**
  String get connectTelegramBotConnect;

  /// No description provided for @whatsappBusinessIdTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل معرّف نشاطك التجاري في Meta'**
  String get whatsappBusinessIdTitle;

  /// No description provided for @whatsappBusinessIdBody.
  ///
  /// In ar, this message translates to:
  /// **'ستجد هذا في Meta Business Suite ضمن إعدادات النشاط التجاري — يحدد حسابات واتساب للأعمال التي سيتم اكتشافها.'**
  String get whatsappBusinessIdBody;

  /// No description provided for @whatsappBusinessIdLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرّف النشاط التجاري'**
  String get whatsappBusinessIdLabel;

  /// No description provided for @whatsappBusinessIdSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get whatsappBusinessIdSave;

  /// No description provided for @settingsScreenTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsScreenTitle;

  /// No description provided for @settingsOrganizationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المؤسسات'**
  String get settingsOrganizationsTitle;

  /// No description provided for @settingsOrganizationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'التبديل بين المؤسسات التي تنتمي إليها.'**
  String get settingsOrganizationsSubtitle;

  /// No description provided for @settingsMembersTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعضاء الفريق'**
  String get settingsMembersTitle;

  /// No description provided for @settingsMembersSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أو إدارة أعضاء مؤسستك.'**
  String get settingsMembersSubtitle;

  /// No description provided for @settingsAuditLogTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get settingsAuditLogTitle;

  /// No description provided for @settingsAuditLogSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'راجع من فعل ماذا داخل هذه المؤسسة.'**
  String get settingsAuditLogSubtitle;

  /// No description provided for @settingsTwoFactorTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصادقة الثنائية'**
  String get settingsTwoFactorTitle;

  /// No description provided for @settingsTwoFactorSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف طبقة حماية إضافية لحسابك.'**
  String get settingsTwoFactorSubtitle;

  /// No description provided for @settingsDataExportTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل بياناتي'**
  String get settingsDataExportTitle;

  /// No description provided for @settingsDataExportSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'احصل على نسخة من حسابك ومنشوراتك وحساباتك المرتبطة.'**
  String get settingsDataExportSubtitle;

  /// No description provided for @settingsDataDeletionTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابي'**
  String get settingsDataDeletionTitle;

  /// No description provided for @settingsDataDeletionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب حذف دائم لحسابك وبياناتك.'**
  String get settingsDataDeletionSubtitle;

  /// No description provided for @emailVerificationBannerMessage.
  ///
  /// In ar, this message translates to:
  /// **'يرجى توثيق بريدك الإلكتروني للحفاظ على الوصول الكامل لحسابك.'**
  String get emailVerificationBannerMessage;

  /// No description provided for @emailVerificationBannerResendButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال رابط التحقق'**
  String get emailVerificationBannerResendButton;

  /// No description provided for @emailVerificationResendSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط التحقق. تحقق من بريدك الإلكتروني.'**
  String get emailVerificationResendSuccess;

  /// No description provided for @dataExportAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'تنزيل بياناتي'**
  String get dataExportAppBarTitle;

  /// No description provided for @dataExportIntro.
  ///
  /// In ar, this message translates to:
  /// **'يشمل هذا تفاصيل حسابك وكل ما هو مرتبط به عبر جميع المؤسسات التي تنتمي إليها.'**
  String get dataExportIntro;

  /// No description provided for @dataExportUserSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get dataExportUserSectionTitle;

  /// No description provided for @dataExportOrganizationsCount.
  ///
  /// In ar, this message translates to:
  /// **'المؤسسات'**
  String get dataExportOrganizationsCount;

  /// No description provided for @dataExportPostsCount.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get dataExportPostsCount;

  /// No description provided for @dataExportSocialAccountsCount.
  ///
  /// In ar, this message translates to:
  /// **'حسابات التواصل الاجتماعي المتصلة'**
  String get dataExportSocialAccountsCount;

  /// No description provided for @dataExportMediaAttachmentsCount.
  ///
  /// In ar, this message translates to:
  /// **'مرفقات الوسائط'**
  String get dataExportMediaAttachmentsCount;

  /// No description provided for @dataExportExportedAtLabel.
  ///
  /// In ar, this message translates to:
  /// **'تم الإنشاء في'**
  String get dataExportExportedAtLabel;

  /// No description provided for @dataExportCopyJsonButton.
  ///
  /// In ar, this message translates to:
  /// **'نسخ كامل البيانات بصيغة JSON'**
  String get dataExportCopyJsonButton;

  /// No description provided for @dataExportCopiedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ إلى الحافظة.'**
  String get dataExportCopiedMessage;

  /// No description provided for @dataExportLoadError.
  ///
  /// In ar, this message translates to:
  /// **'فشل إنشاء تصدير بياناتك.'**
  String get dataExportLoadError;

  /// No description provided for @dataExportRetryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get dataExportRetryButton;

  /// No description provided for @dataDeletionAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابي'**
  String get dataDeletionAppBarTitle;

  /// No description provided for @dataDeletionWarningTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن التراجع عن هذا الإجراء'**
  String get dataDeletionWarningTitle;

  /// No description provided for @dataDeletionWarningMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيُراجع أحد المشغّلين طلبك قبل حذف أي شيء — هذا ليس فوريًا. سيتم في النهاية حذف حسابات التواصل الاجتماعي المتصلة والمنشورات والوسائط المرتبطة بحسابك نهائيًا.'**
  String get dataDeletionWarningMessage;

  /// No description provided for @dataDeletionReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'السبب (اختياري)'**
  String get dataDeletionReasonLabel;

  /// No description provided for @dataDeletionConfirmCheckboxLabel.
  ///
  /// In ar, this message translates to:
  /// **'أفهم أن هذا سيحذف حسابي وبياناتي نهائيًا.'**
  String get dataDeletionConfirmCheckboxLabel;

  /// No description provided for @dataDeletionConfirmValidationError.
  ///
  /// In ar, this message translates to:
  /// **'يجب التأكيد قبل الإرسال.'**
  String get dataDeletionConfirmValidationError;

  /// No description provided for @dataDeletionSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'طلب حذف الحساب'**
  String get dataDeletionSubmitButton;

  /// No description provided for @dataDeletionSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل طلب الحذف'**
  String get dataDeletionSuccessTitle;

  /// No description provided for @dataDeletionSuccessMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل طلبك وسيتم مراجعته. الحالة: {status}.'**
  String dataDeletionSuccessMessage(String status);

  /// No description provided for @organizationMembersAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعضاء الفريق'**
  String get organizationMembersAppBarTitle;

  /// No description provided for @organizationMembersEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أعضاء بعد.'**
  String get organizationMembersEmptyMessage;

  /// No description provided for @organizationMembersLoadError.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل الأعضاء.'**
  String get organizationMembersLoadError;

  /// No description provided for @organizationMembersYouLabel.
  ///
  /// In ar, this message translates to:
  /// **'أنت'**
  String get organizationMembersYouLabel;

  /// No description provided for @organizationMembersAddButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو'**
  String get organizationMembersAddButton;

  /// No description provided for @organizationMembersAddDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو للفريق'**
  String get organizationMembersAddDialogTitle;

  /// No description provided for @organizationMembersAddDialogSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون البريد الإلكتروني مرتبطًا بحساب مسجّل بالفعل في Smart Publisher.'**
  String get organizationMembersAddDialogSubtitle;

  /// No description provided for @organizationMembersEmailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get organizationMembersEmailLabel;

  /// No description provided for @organizationMembersEmailValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدًا إلكترونيًا صحيحًا'**
  String get organizationMembersEmailValidationError;

  /// No description provided for @organizationMembersRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get organizationMembersRoleLabel;

  /// No description provided for @organizationMembersAddSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get organizationMembersAddSubmitButton;

  /// No description provided for @organizationMembersAddedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة العضو.'**
  String get organizationMembersAddedSuccess;

  /// No description provided for @organizationMembersRoleUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الدور.'**
  String get organizationMembersRoleUpdatedSuccess;

  /// No description provided for @organizationMembersRemoveConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف العضو؟'**
  String get organizationMembersRemoveConfirmTitle;

  /// No description provided for @organizationMembersRemoveConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيفقد {name} إمكانية الوصول إلى هذه المؤسسة.'**
  String organizationMembersRemoveConfirmMessage(String name);

  /// No description provided for @organizationMembersRemovedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف العضو.'**
  String get organizationMembersRemovedSuccess;

  /// No description provided for @organizationMembersRemoveButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get organizationMembersRemoveButton;

  /// No description provided for @auditLogAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل التدقيق'**
  String get auditLogAppBarTitle;

  /// No description provided for @auditLogEmptyMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أحداث تدقيق مطابقة.'**
  String get auditLogEmptyMessage;

  /// No description provided for @auditLogLoadError.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل سجل التدقيق.'**
  String get auditLogLoadError;

  /// No description provided for @auditLogRetryButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get auditLogRetryButton;

  /// No description provided for @auditLogForbiddenTitle.
  ///
  /// In ar, this message translates to:
  /// **'غير مصرح لك'**
  String get auditLogForbiddenTitle;

  /// No description provided for @auditLogForbiddenMessage.
  ///
  /// In ar, this message translates to:
  /// **'رفض الخادم الوصول إلى سجل التدقيق هذا.'**
  String get auditLogForbiddenMessage;

  /// No description provided for @auditLogFilterActionLabel.
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب الإجراء'**
  String get auditLogFilterActionLabel;

  /// No description provided for @auditLogFilterDateFromLabel.
  ///
  /// In ar, this message translates to:
  /// **'من'**
  String get auditLogFilterDateFromLabel;

  /// No description provided for @auditLogFilterDateToLabel.
  ///
  /// In ar, this message translates to:
  /// **'إلى'**
  String get auditLogFilterDateToLabel;

  /// No description provided for @auditLogFilterClearButton.
  ///
  /// In ar, this message translates to:
  /// **'مسح الفلاتر'**
  String get auditLogFilterClearButton;

  /// No description provided for @auditLogSystemActor.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get auditLogSystemActor;

  /// No description provided for @auditLogEntrySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'{type} رقم {id}'**
  String auditLogEntrySubtitle(String type, String id);

  /// No description provided for @auditLogViewDetailsButton.
  ///
  /// In ar, this message translates to:
  /// **'عرض التفاصيل'**
  String get auditLogViewDetailsButton;

  /// No description provided for @auditLogDetailsOldValues.
  ///
  /// In ar, this message translates to:
  /// **'القيم السابقة'**
  String get auditLogDetailsOldValues;

  /// No description provided for @auditLogDetailsNewValues.
  ///
  /// In ar, this message translates to:
  /// **'القيم الجديدة'**
  String get auditLogDetailsNewValues;

  /// No description provided for @auditLogDetailsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سجل.'**
  String get auditLogDetailsNone;

  /// No description provided for @auditLogPaginationLabel.
  ///
  /// In ar, this message translates to:
  /// **'صفحة {page} من {lastPage}'**
  String auditLogPaginationLabel(String page, String lastPage);

  /// No description provided for @auditLogPreviousPage.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get auditLogPreviousPage;

  /// No description provided for @auditLogNextPage.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get auditLogNextPage;

  /// No description provided for @auditLogOrganizationColumn.
  ///
  /// In ar, this message translates to:
  /// **'المؤسسة'**
  String get auditLogOrganizationColumn;

  /// No description provided for @twoFactorSetupAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصادقة الثنائية'**
  String get twoFactorSetupAppBarTitle;

  /// No description provided for @twoFactorSetupEnabledStatus.
  ///
  /// In ar, this message translates to:
  /// **'المصادقة الثنائية مفعّلة على حسابك.'**
  String get twoFactorSetupEnabledStatus;

  /// No description provided for @twoFactorSetupDisabledStatus.
  ///
  /// In ar, this message translates to:
  /// **'المصادقة الثنائية غير مفعّلة.'**
  String get twoFactorSetupDisabledStatus;

  /// No description provided for @twoFactorSetupIntro.
  ///
  /// In ar, this message translates to:
  /// **'احمِ حسابك باستخدام تطبيق مصادقة (Google Authenticator أو Authy أو 1Password وغيرها).'**
  String get twoFactorSetupIntro;

  /// No description provided for @twoFactorSetupEnableButton.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل المصادقة الثنائية'**
  String get twoFactorSetupEnableButton;

  /// No description provided for @twoFactorSetupDisableButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء تفعيل المصادقة الثنائية'**
  String get twoFactorSetupDisableButton;

  /// No description provided for @twoFactorSetupSecretLabel.
  ///
  /// In ar, this message translates to:
  /// **'المفتاح السري'**
  String get twoFactorSetupSecretLabel;

  /// No description provided for @twoFactorSetupSecretHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل هذا المفتاح يدويًا في تطبيق المصادقة، أو انسخ رابط الإعداد أدناه.'**
  String get twoFactorSetupSecretHint;

  /// No description provided for @twoFactorSetupOtpAuthUrlLabel.
  ///
  /// In ar, this message translates to:
  /// **'رابط الإعداد'**
  String get twoFactorSetupOtpAuthUrlLabel;

  /// No description provided for @twoFactorSetupCopyTooltip.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get twoFactorSetupCopyTooltip;

  /// No description provided for @twoFactorSetupCopiedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ إلى الحافظة.'**
  String get twoFactorSetupCopiedMessage;

  /// No description provided for @twoFactorSetupCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام من التطبيق'**
  String get twoFactorSetupCodeLabel;

  /// No description provided for @twoFactorSetupCodeValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز المكوّن من 6 أرقام'**
  String get twoFactorSetupCodeValidationError;

  /// No description provided for @twoFactorSetupConfirmButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد والتفعيل'**
  String get twoFactorSetupConfirmButton;

  /// No description provided for @twoFactorSetupCancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get twoFactorSetupCancelButton;

  /// No description provided for @twoFactorSetupRecoveryCodesTitle.
  ///
  /// In ar, this message translates to:
  /// **'احفظ رموز الاسترداد'**
  String get twoFactorSetupRecoveryCodesTitle;

  /// No description provided for @twoFactorSetupRecoveryCodesWarning.
  ///
  /// In ar, this message translates to:
  /// **'احفظ هذه الرموز في مكان آمن. يمكن استخدام كل رمز مرة واحدة فقط لتسجيل الدخول في حال فقدان الوصول إلى تطبيق المصادقة. لن تُعرض هذه الرموز مرة أخرى.'**
  String get twoFactorSetupRecoveryCodesWarning;

  /// No description provided for @twoFactorSetupDoneButton.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get twoFactorSetupDoneButton;

  /// No description provided for @twoFactorSetupDisablePasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get twoFactorSetupDisablePasswordLabel;

  /// No description provided for @twoFactorSetupDisablePasswordValidationError.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور الحالية'**
  String get twoFactorSetupDisablePasswordValidationError;

  /// No description provided for @twoFactorSetupDisableConfirmButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء التفعيل'**
  String get twoFactorSetupDisableConfirmButton;

  /// No description provided for @twoFactorSetupSuccessEnabled.
  ///
  /// In ar, this message translates to:
  /// **'تم تفعيل المصادقة الثنائية.'**
  String get twoFactorSetupSuccessEnabled;

  /// No description provided for @twoFactorSetupSuccessDisabled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء تفعيل المصادقة الثنائية.'**
  String get twoFactorSetupSuccessDisabled;

  /// No description provided for @settingsPushNotificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات الفورية'**
  String get settingsPushNotificationsTitle;

  /// No description provided for @settingsPushNotificationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح بعد — لا يوجد تكامل إشعارات فورية في هذا الإصدار.'**
  String get settingsPushNotificationsSubtitle;

  /// No description provided for @settingsAutoScheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'اقتراحات الجدولة التلقائية'**
  String get settingsAutoScheduleTitle;

  /// No description provided for @settingsAutoScheduleSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح بعد — التوصيات الذكية لأوقات النشر غير مطبقة في هذا الإصدار.'**
  String get settingsAutoScheduleSubtitle;

  /// No description provided for @settingsCanaryReleaseTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع الإصدار التجريبي (Canary)'**
  String get settingsCanaryReleaseTitle;

  /// No description provided for @settingsCanaryReleaseSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح بعد — لا يوجد نظام تحكم بالنشر التدريجي في هذا الإصدار.'**
  String get settingsCanaryReleaseSubtitle;

  /// No description provided for @settingsPreferredTheme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر المفضّل'**
  String get settingsPreferredTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsSaveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإعدادات'**
  String get settingsSaveButton;

  /// No description provided for @settingsSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات بنجاح.'**
  String get settingsSavedSuccess;

  /// No description provided for @composerAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منشور'**
  String get composerAppBarTitle;

  /// No description provided for @composerHeading.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ منشورك'**
  String get composerHeading;

  /// No description provided for @composerSubheading.
  ///
  /// In ar, this message translates to:
  /// **'العنوان والمحتوى والوسائط والمنصات والجدولة والمعاينة والنشر في مسار واحد.'**
  String get composerSubheading;

  /// No description provided for @composerEditingDraftChip.
  ///
  /// In ar, this message translates to:
  /// **'تعديل مسودة موجودة'**
  String get composerEditingDraftChip;

  /// No description provided for @composerDraftIdChip.
  ///
  /// In ar, this message translates to:
  /// **'المعرّف: {id}'**
  String composerDraftIdChip(String id);

  /// No description provided for @composerTitleLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get composerTitleLabel;

  /// No description provided for @composerTitleHint.
  ///
  /// In ar, this message translates to:
  /// **'عنوان المنشور'**
  String get composerTitleHint;

  /// No description provided for @composerContentLabel.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get composerContentLabel;

  /// No description provided for @composerContentHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب محتوى منشورك... (الوسوم # والإشارات @ تُبرَز تلقائيًا)'**
  String get composerContentHint;

  /// No description provided for @composerMediaTitle.
  ///
  /// In ar, this message translates to:
  /// **'الوسائط'**
  String get composerMediaTitle;

  /// No description provided for @composerMediaSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أرفق روابط وسائط أو ارفع ملفات من جهازك.'**
  String get composerMediaSubtitle;

  /// No description provided for @composerMediaUrlHint.
  ///
  /// In ar, this message translates to:
  /// **'https://cdn.example.com/image.png'**
  String get composerMediaUrlHint;

  /// No description provided for @composerAddUrl.
  ///
  /// In ar, this message translates to:
  /// **'إضافة رابط'**
  String get composerAddUrl;

  /// No description provided for @composerUploadFile.
  ///
  /// In ar, this message translates to:
  /// **'رفع ملف'**
  String get composerUploadFile;

  /// No description provided for @composerNoMediaYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد وسائط مُرفقة بعد.'**
  String get composerNoMediaYet;

  /// No description provided for @composerPagesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات والقنوات'**
  String get composerPagesTitle;

  /// No description provided for @composerPagesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر الصفحات/القنوات المحددة للنشر عليها — وليس مجرد منصة.'**
  String get composerPagesSubtitle;

  /// No description provided for @composerNoUsablePages.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صفحات أو قنوات قابلة للاستخدام بعد. اتصل بحساب وأضف/اختر صفحاته من لوحة التحكم > الحسابات.'**
  String get composerNoUsablePages;

  /// No description provided for @composerFailedToLoadAccounts.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل الحسابات المتصلة.'**
  String get composerFailedToLoadAccounts;

  /// No description provided for @composerPerPlatformContentTitle.
  ///
  /// In ar, this message translates to:
  /// **'محتوى مخصص لكل منصة'**
  String get composerPerPlatformContentTitle;

  /// No description provided for @composerPerPlatformContentSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك اختياريًا كتابة نص مختلف لمنصة معينة — اتركه فارغًا لاستخدام المحتوى المشترك أعلاه.'**
  String get composerPerPlatformContentSubtitle;

  /// No description provided for @composerPlatformOverrideLabel.
  ///
  /// In ar, this message translates to:
  /// **'تخصيص {platform}'**
  String composerPlatformOverrideLabel(String platform);

  /// No description provided for @composerPlatformOverrideHint.
  ///
  /// In ar, this message translates to:
  /// **'اتركه فارغًا لاستخدام المحتوى المشترك'**
  String get composerPlatformOverrideHint;

  /// No description provided for @composerPerPlatformPreviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاينة لكل منصة'**
  String get composerPerPlatformPreviewTitle;

  /// No description provided for @composerPerPlatformPreviewSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يعرض بالضبط ما ستُظهره كل منصة فعليًا — لا يظهر التنسيق إلا حيث تدعمه المنصة فعلاً.'**
  String get composerPerPlatformPreviewSubtitle;

  /// No description provided for @composerSchedulingTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجدولة'**
  String get composerSchedulingTitle;

  /// No description provided for @composerNoScheduleSelected.
  ///
  /// In ar, this message translates to:
  /// **'لم يُحدَّد موعد (سيُنشر فورًا).'**
  String get composerNoScheduleSelected;

  /// No description provided for @composerScheduledFor.
  ///
  /// In ar, this message translates to:
  /// **'مجدول لـ {date}'**
  String composerScheduledFor(String date);

  /// No description provided for @composerPickTime.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الوقت'**
  String get composerPickTime;

  /// No description provided for @composerClearScheduleTooltip.
  ///
  /// In ar, this message translates to:
  /// **'مسح الجدولة'**
  String get composerClearScheduleTooltip;

  /// No description provided for @composerPreviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعاينة'**
  String get composerPreviewTitle;

  /// No description provided for @composerOpenPreview.
  ///
  /// In ar, this message translates to:
  /// **'فتح المعاينة'**
  String get composerOpenPreview;

  /// No description provided for @composerSaveDraftButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كمسودة'**
  String get composerSaveDraftButton;

  /// No description provided for @composerScheduleButton.
  ///
  /// In ar, this message translates to:
  /// **'جدولة'**
  String get composerScheduleButton;

  /// No description provided for @composerPublishButton.
  ///
  /// In ar, this message translates to:
  /// **'نشر'**
  String get composerPublishButton;

  /// No description provided for @composerSubmitScheduleForApprovalButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الجدولة للموافقة'**
  String get composerSubmitScheduleForApprovalButton;

  /// No description provided for @composerSubmitPublishForApprovalButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب النشر للموافقة'**
  String get composerSubmitPublishForApprovalButton;

  /// No description provided for @composerApprovalRequiredNotice.
  ///
  /// In ar, this message translates to:
  /// **'سيُرسل طلب الجدولة أو النشر للموافقة قبل تنفيذه.'**
  String get composerApprovalRequiredNotice;

  /// No description provided for @composerOrganizationAccessLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحقق من صلاحيات المؤسسة…'**
  String get composerOrganizationAccessLoading;

  /// No description provided for @composerOrganizationAccessUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات المؤسسة غير متاحة. اختر مؤسسة أو حاول مرة أخرى.'**
  String get composerOrganizationAccessUnavailable;

  /// No description provided for @composerPostActionNotAllowed.
  ///
  /// In ar, this message translates to:
  /// **'ليست لديك صلاحية إرسال إجراء هذا المنشور.'**
  String get composerPostActionNotAllowed;

  /// No description provided for @composerPreviewSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'معاينة المنشور'**
  String get composerPreviewSheetTitle;

  /// No description provided for @composerNoContentYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محتوى بعد.'**
  String get composerNoContentYet;

  /// No description provided for @composerPreviewMediaLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوسائط'**
  String get composerPreviewMediaLabel;

  /// No description provided for @composerPreviewTargetsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأهداف'**
  String get composerPreviewTargetsLabel;

  /// No description provided for @composerPreviewScheduleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجدولة'**
  String get composerPreviewScheduleLabel;

  /// No description provided for @composerMediaNone.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء'**
  String get composerMediaNone;

  /// No description provided for @composerMediaItemCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} عنصر'**
  String composerMediaItemCount(int count);

  /// No description provided for @composerNoneSelected.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء محدد'**
  String get composerNoneSelected;

  /// No description provided for @composerPublishNow.
  ///
  /// In ar, this message translates to:
  /// **'النشر الآن'**
  String get composerPublishNow;

  /// No description provided for @composerInvalidMediaUrl.
  ///
  /// In ar, this message translates to:
  /// **'هذا لا يبدو رابطًا صحيحًا (http:// أو https://). لإرفاق ملف من جهازك استخدم \"رفع ملف\" بدلاً من ذلك.'**
  String get composerInvalidMediaUrl;

  /// No description provided for @composerMediaUrlAlreadyAdded.
  ///
  /// In ar, this message translates to:
  /// **'رابط الوسائط مُضاف بالفعل.'**
  String get composerMediaUrlAlreadyAdded;

  /// No description provided for @composerTitleContentRequired.
  ///
  /// In ar, this message translates to:
  /// **'العنوان والمحتوى مطلوبان.'**
  String get composerTitleContentRequired;

  /// No description provided for @composerSelectAtLeastOnePage.
  ///
  /// In ar, this message translates to:
  /// **'اختر صفحة أو قناة واحدة على الأقل للنشر.'**
  String get composerSelectAtLeastOnePage;

  /// No description provided for @composerSelectScheduleTime.
  ///
  /// In ar, this message translates to:
  /// **'اختر وقت الجدولة قبل الجدولة.'**
  String get composerSelectScheduleTime;

  /// No description provided for @composerScheduleTimeMustBeFuture.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون وقت الجدولة في المستقبل.'**
  String get composerScheduleTimeMustBeFuture;

  /// No description provided for @composerFailedSaveDraft.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ المسودة.'**
  String get composerFailedSaveDraft;

  /// No description provided for @composerFailedUpdateDraft.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحديث المسودة.'**
  String get composerFailedUpdateDraft;

  /// No description provided for @composerDraftSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المسودة بنجاح.'**
  String get composerDraftSavedSuccess;

  /// No description provided for @composerDraftUpdatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث المسودة بنجاح.'**
  String get composerDraftUpdatedSuccess;

  /// No description provided for @composerFailedSchedulePost.
  ///
  /// In ar, this message translates to:
  /// **'فشلت جدولة المنشور.'**
  String get composerFailedSchedulePost;

  /// No description provided for @composerPostScheduledSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت جدولة المنشور بنجاح.'**
  String get composerPostScheduledSuccess;

  /// No description provided for @composerFailedPublishPost.
  ///
  /// In ar, this message translates to:
  /// **'فشل نشر المنشور.'**
  String get composerFailedPublishPost;

  /// No description provided for @composerPostQueuedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إدراج المنشور في طابور النشر.'**
  String get composerPostQueuedSuccess;

  /// No description provided for @composerFileDataUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الملف المحدد غير متاحة.'**
  String get composerFileDataUnavailable;

  /// No description provided for @composerFilePathUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'مسار الملف المحدد غير متاح.'**
  String get composerFilePathUnavailable;

  /// No description provided for @composerFailedUploadMedia.
  ///
  /// In ar, this message translates to:
  /// **'فشل رفع ملف الوسائط.'**
  String get composerFailedUploadMedia;

  /// No description provided for @composerMediaAlreadyAttached.
  ///
  /// In ar, this message translates to:
  /// **'ملف الوسائط مُرفق بالفعل.'**
  String get composerMediaAlreadyAttached;

  /// No description provided for @composerMediaUploadedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع ملف الوسائط وإرفاقه.'**
  String get composerMediaUploadedSuccess;

  /// No description provided for @calendarAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقويم النشر'**
  String get calendarAppBarTitle;

  /// No description provided for @calendarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تتبّع المنشورات المجدولة حسب التاريخ وحافظ على وتيرة النشر في وقتها.'**
  String get calendarSubtitle;

  /// No description provided for @calendarMonthLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشهر: {month}'**
  String calendarMonthLabel(String month);

  /// No description provided for @calendarEventsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الأحداث: {count}'**
  String calendarEventsLabel(int count);

  /// No description provided for @calendarScheduledForDate.
  ///
  /// In ar, this message translates to:
  /// **'مجدول لـ{date}'**
  String calendarScheduledForDate(String date);

  /// No description provided for @calendarNoScheduledPosts.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات مجدولة في هذا التاريخ.'**
  String get calendarNoScheduledPosts;

  /// No description provided for @calendarFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل التقويم.'**
  String get calendarFailedToLoad;

  /// No description provided for @calendarStatusLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحالة: {status}'**
  String calendarStatusLabel(String status);

  /// No description provided for @calendarScheduleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجدولة: {date}'**
  String calendarScheduleLabel(String date);

  /// No description provided for @calendarDefaultStatus.
  ///
  /// In ar, this message translates to:
  /// **'مجدول'**
  String get calendarDefaultStatus;

  /// No description provided for @mediaAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة الوسائط'**
  String get mediaAppBarTitle;

  /// No description provided for @mediaSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة وسائط حقيقية من الخادم — بحث وتصفية وضغط وإعادة استخدام الأصول عبر المنشورات.'**
  String get mediaSubtitle;

  /// No description provided for @mediaSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'بحث في الوسائط'**
  String get mediaSearchLabel;

  /// No description provided for @mediaSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم الملف الأصلي'**
  String get mediaSearchHint;

  /// No description provided for @mediaFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get mediaFilterAll;

  /// No description provided for @mediaFilterImages.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get mediaFilterImages;

  /// No description provided for @mediaFilterVideos.
  ///
  /// In ar, this message translates to:
  /// **'الفيديوهات'**
  String get mediaFilterVideos;

  /// No description provided for @mediaFilterDocuments.
  ///
  /// In ar, this message translates to:
  /// **'المستندات'**
  String get mediaFilterDocuments;

  /// No description provided for @mediaCompressTooltipImage.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ترميز هذه الصورة بحجم أصغر'**
  String get mediaCompressTooltipImage;

  /// No description provided for @mediaCompressTooltipOther.
  ///
  /// In ar, this message translates to:
  /// **'الضغط متاح فقط للصور حاليًا'**
  String get mediaCompressTooltipOther;

  /// No description provided for @mediaCompressButton.
  ///
  /// In ar, this message translates to:
  /// **'ضغط'**
  String get mediaCompressButton;

  /// No description provided for @mediaReuseInPostButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الاستخدام في منشور'**
  String get mediaReuseInPostButton;

  /// No description provided for @mediaDeleteTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حذف أصل الوسائط'**
  String get mediaDeleteTooltip;

  /// No description provided for @mediaFailedDelete.
  ///
  /// In ar, this message translates to:
  /// **'فشل حذف أصل الوسائط.'**
  String get mediaFailedDelete;

  /// No description provided for @mediaFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل مكتبة الوسائط.'**
  String get mediaFailedToLoad;

  /// No description provided for @mediaLoadMore.
  ///
  /// In ar, this message translates to:
  /// **'تحميل المزيد'**
  String get mediaLoadMore;

  /// No description provided for @mediaDeletedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف أصل الوسائط.'**
  String get mediaDeletedSuccess;

  /// No description provided for @mediaCompressedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الضغط بنجاح.'**
  String get mediaCompressedSuccess;

  /// No description provided for @mediaFailedCompress.
  ///
  /// In ar, this message translates to:
  /// **'فشل ضغط الوسائط.'**
  String get mediaFailedCompress;

  /// No description provided for @mediaNoPostsToAttach.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات متاحة لإرفاق هذه الوسائط بها.'**
  String get mediaNoPostsToAttach;

  /// No description provided for @mediaReuseDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الاستخدام في منشور'**
  String get mediaReuseDialogTitle;

  /// No description provided for @mediaAttachedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرفاق الوسائط بالمنشور المحدد.'**
  String get mediaAttachedSuccess;

  /// No description provided for @mediaFailedReuse.
  ///
  /// In ar, this message translates to:
  /// **'فشلت إعادة استخدام الوسائط في المنشور.'**
  String get mediaFailedReuse;

  /// No description provided for @mediaUnknownDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ غير معروف'**
  String get mediaUnknownDate;

  /// No description provided for @mediaEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يُعثر على أصول وسائط.'**
  String get mediaEmptyTitle;

  /// No description provided for @mediaEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ارفع وسائط من محرر الإنشاء، ثم عد لهذه المكتبة.'**
  String get mediaEmptySubtitle;

  /// No description provided for @analyticsAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'التحليلات'**
  String get analyticsAppBarTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على الأداء ومقاييس المنشورات واتجاهات التفاعل.'**
  String get analyticsSubtitle;

  /// No description provided for @analyticsMetricReach.
  ///
  /// In ar, this message translates to:
  /// **'الوصول'**
  String get analyticsMetricReach;

  /// No description provided for @analyticsMetricImpressions.
  ///
  /// In ar, this message translates to:
  /// **'مرات الظهور'**
  String get analyticsMetricImpressions;

  /// No description provided for @analyticsMetricEngagement.
  ///
  /// In ar, this message translates to:
  /// **'التفاعل'**
  String get analyticsMetricEngagement;

  /// No description provided for @analyticsMetricAvgEngagementRate.
  ///
  /// In ar, this message translates to:
  /// **'متوسط معدل التفاعل'**
  String get analyticsMetricAvgEngagementRate;

  /// No description provided for @analyticsBestTimeToPost.
  ///
  /// In ar, this message translates to:
  /// **'أفضل وقت للنشر'**
  String get analyticsBestTimeToPost;

  /// No description provided for @analyticsBestPlatform.
  ///
  /// In ar, this message translates to:
  /// **'أفضل منصة'**
  String get analyticsBestPlatform;

  /// No description provided for @analyticsNotEnoughData.
  ///
  /// In ar, this message translates to:
  /// **'لا تتوفر بيانات كافية بعد'**
  String get analyticsNotEnoughData;

  /// No description provided for @analyticsNoPostsYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات متاحة للتحليل بعد.'**
  String get analyticsNoPostsYet;

  /// No description provided for @analyticsFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل التحليلات.'**
  String get analyticsFailedToLoad;

  /// No description provided for @analyticsMetricClicks.
  ///
  /// In ar, this message translates to:
  /// **'النقرات'**
  String get analyticsMetricClicks;

  /// No description provided for @analyticsMetricShares.
  ///
  /// In ar, this message translates to:
  /// **'المشاركات'**
  String get analyticsMetricShares;

  /// No description provided for @analyticsMetricReactions.
  ///
  /// In ar, this message translates to:
  /// **'التفاعلات'**
  String get analyticsMetricReactions;

  /// No description provided for @analyticsMetricEngagementRate.
  ///
  /// In ar, this message translates to:
  /// **'معدل التفاعل'**
  String get analyticsMetricEngagementRate;

  /// No description provided for @notificationsAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsAppBarTitle;

  /// No description provided for @notificationsMarkAllReadTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notificationsMarkAllReadTooltip;

  /// No description provided for @notificationsClearReadTooltip.
  ///
  /// In ar, this message translates to:
  /// **'مسح المقروء'**
  String get notificationsClearReadTooltip;

  /// No description provided for @notificationsInboxSummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الوارد'**
  String get notificationsInboxSummaryTitle;

  /// No description provided for @notificationsInboxSummarySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء: {unread} • الإجمالي: {total}'**
  String notificationsInboxSummarySubtitle(int unread, int total);

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات متاحة.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkReadButton.
  ///
  /// In ar, this message translates to:
  /// **'تعليم كمقروء'**
  String get notificationsMarkReadButton;

  /// No description provided for @notificationsLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الإشعارات. تحقق من الاتصال ثم أعد المحاولة.'**
  String get notificationsLoadFailed;

  /// No description provided for @administrationAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإدارة'**
  String get administrationAppBarTitle;

  /// No description provided for @administrationReadOnlyNotice.
  ///
  /// In ar, this message translates to:
  /// **'الإجراءات الإدارية مقتصرة على المسؤولين. لديك حاليًا صلاحية قراءة فقط.'**
  String get administrationReadOnlyNotice;

  /// No description provided for @administrationAccessProfileTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف الصلاحيات'**
  String get administrationAccessProfileTitle;

  /// No description provided for @administrationAccessProfileSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'الدور الحالي: {role}'**
  String administrationAccessProfileSubtitle(String role);

  /// No description provided for @administrationMaintenanceModeTitle.
  ///
  /// In ar, this message translates to:
  /// **'وضع الصيانة'**
  String get administrationMaintenanceModeTitle;

  /// No description provided for @administrationMaintenanceModeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييد وصول المحررين أثناء إجراء عمليات الصيانة.'**
  String get administrationMaintenanceModeSubtitle;

  /// No description provided for @administrationFreezePublishingTitle.
  ///
  /// In ar, this message translates to:
  /// **'تجميد قائمة انتظار النشر'**
  String get administrationFreezePublishingTitle;

  /// No description provided for @administrationFreezePublishingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مهام النشر الجديدة مؤقتًا حتى انتهاء المهام الحالية.'**
  String get administrationFreezePublishingSubtitle;

  /// No description provided for @administrationCredentialsTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات اعتماد المنصات الاجتماعية'**
  String get administrationCredentialsTitle;

  /// No description provided for @administrationCredentialsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة معرف/سر تطبيق OAuth لفيسبوك وإنستغرام ولينكدإن وX وواتساب.'**
  String get administrationCredentialsSubtitle;

  /// No description provided for @administrationReleaseHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الإصدارات'**
  String get administrationReleaseHistoryTitle;

  /// No description provided for @administrationReleaseHistorySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الإصدارات المنشورة مؤخرًا وملاحظات الطرح.'**
  String get administrationReleaseHistorySubtitle;

  /// No description provided for @administrationOperationalReadinessTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجاهزية التشغيلية'**
  String get administrationOperationalReadinessTitle;

  /// No description provided for @administrationOperationalReadinessSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تتبع فحوصات الإطلاق وأدلة الحوادث وجاهزية التراجع.'**
  String get administrationOperationalReadinessSubtitle;

  /// No description provided for @administrationApplyPoliciesButton.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق السياسات الإدارية'**
  String get administrationApplyPoliciesButton;

  /// No description provided for @administrationPoliciesAppliedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تطبيق السياسات الإدارية بنجاح.'**
  String get administrationPoliciesAppliedSuccess;

  /// No description provided for @administrationOperationsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة وتجميد النشر وتطبيق السياسات غير متاحة من هذا الإصدار. استخدم مسار العمليات الخلفي المراجع.'**
  String get administrationOperationsUnavailable;

  /// No description provided for @oauthSettingsIntro.
  ///
  /// In ar, this message translates to:
  /// **'هذه بيانات اعتماد OAuth على مستوى التطبيق (معرف/سر) تُستخدم لكل مستخدم يربط حسابًا — وليست إعدادًا خاصًا بمستخدم واحد.'**
  String get oauthSettingsIntro;

  /// No description provided for @oauthSettingsFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل إعدادات المزود.'**
  String get oauthSettingsFailedToLoad;

  /// No description provided for @oauthSettingsHistoryTooltip.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get oauthSettingsHistoryTooltip;

  /// No description provided for @oauthSettingsMockNotice.
  ///
  /// In ar, this message translates to:
  /// **'تكامل محاكاة — تهيئة بيانات الاعتماد هنا لا تُفعّل النشر الفعلي. لا يتم إجراء أي اتصالات HTTP حقيقية بهذه المنصة بعد.'**
  String get oauthSettingsMockNotice;

  /// No description provided for @oauthSettingsClientIdSet.
  ///
  /// In ar, this message translates to:
  /// **'معرف العميل: {clientId}'**
  String oauthSettingsClientIdSet(String clientId);

  /// No description provided for @oauthSettingsClientIdNotSet.
  ///
  /// In ar, this message translates to:
  /// **'معرف العميل: غير محدد'**
  String get oauthSettingsClientIdNotSet;

  /// No description provided for @oauthSettingsUpdatedBy.
  ///
  /// In ar, this message translates to:
  /// **'حدّثه {name} • {timestamp}'**
  String oauthSettingsUpdatedBy(String name, String timestamp);

  /// No description provided for @oauthSettingsTestAgain.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الاختبار'**
  String get oauthSettingsTestAgain;

  /// No description provided for @oauthSettingsTestConnection.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الاتصال'**
  String get oauthSettingsTestConnection;

  /// No description provided for @oauthSettingsNotConfigured.
  ///
  /// In ar, this message translates to:
  /// **'غير مهيأ'**
  String get oauthSettingsNotConfigured;

  /// No description provided for @oauthSettingsConfigured.
  ///
  /// In ar, this message translates to:
  /// **'🟢 مهيأ'**
  String get oauthSettingsConfigured;

  /// No description provided for @oauthSettingsLastVerified.
  ///
  /// In ar, this message translates to:
  /// **'آخر تحقق: {timestamp}'**
  String oauthSettingsLastVerified(String timestamp);

  /// No description provided for @oauthSettingsInvalidConfig.
  ///
  /// In ar, this message translates to:
  /// **'🔴 إعداد غير صالح'**
  String get oauthSettingsInvalidConfig;

  /// No description provided for @oauthSettingsAuthFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت المصادقة.'**
  String get oauthSettingsAuthFailed;

  /// No description provided for @oauthSettingsConfiguredNotTested.
  ///
  /// In ar, this message translates to:
  /// **'مهيأ (لم يُختبر بعد)'**
  String get oauthSettingsConfiguredNotTested;

  /// No description provided for @oauthSettingsHistorySheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل {label}'**
  String oauthSettingsHistorySheetTitle(String label);

  /// No description provided for @oauthSettingsNoHistory.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تغييرات مسجلة بعد.'**
  String get oauthSettingsNoHistory;

  /// No description provided for @oauthSettingsTestedSucceeded.
  ///
  /// In ar, this message translates to:
  /// **'تم اختبار الاتصال — نجح'**
  String get oauthSettingsTestedSucceeded;

  /// No description provided for @oauthSettingsTestedFailed.
  ///
  /// In ar, this message translates to:
  /// **'تم اختبار الاتصال — فشل'**
  String get oauthSettingsTestedFailed;

  /// No description provided for @oauthSettingsUpdatedSettings.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث الإعدادات'**
  String get oauthSettingsUpdatedSettings;

  /// No description provided for @oauthSettingsUpdatedFields.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث {fields}'**
  String oauthSettingsUpdatedFields(String fields);

  /// No description provided for @oauthSettingsAutomatedCheck.
  ///
  /// In ar, this message translates to:
  /// **'فحص تلقائي'**
  String get oauthSettingsAutomatedCheck;

  /// No description provided for @oauthSettingsSaveSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ إعدادات {label}.'**
  String oauthSettingsSaveSuccess(String label);

  /// No description provided for @oauthSettingsSaveFailedDefault.
  ///
  /// In ar, this message translates to:
  /// **'فشل حفظ إعدادات المزود.'**
  String get oauthSettingsSaveFailedDefault;

  /// No description provided for @oauthSettingsTestFailedDefault.
  ///
  /// In ar, this message translates to:
  /// **'فشل اختبار الاتصال.'**
  String get oauthSettingsTestFailedDefault;

  /// No description provided for @oauthSettingsEditDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات اعتماد {label}'**
  String oauthSettingsEditDialogTitle(String label);

  /// No description provided for @oauthSettingsClientIdLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرف العميل (App ID)'**
  String get oauthSettingsClientIdLabel;

  /// No description provided for @oauthSettingsClientSecretLabel.
  ///
  /// In ar, this message translates to:
  /// **'سر العميل (App Secret)'**
  String get oauthSettingsClientSecretLabel;

  /// No description provided for @oauthSettingsClientSecretHintKeep.
  ///
  /// In ar, this message translates to:
  /// **'اتركه فارغًا للاحتفاظ بالسر الحالي'**
  String get oauthSettingsClientSecretHintKeep;

  /// No description provided for @oauthSettingsClientSecretHintNotSet.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get oauthSettingsClientSecretHintNotSet;

  /// No description provided for @oauthSettingsEnabledLabel.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get oauthSettingsEnabledLabel;

  /// No description provided for @releaseAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'إصدار الإنتاج'**
  String get releaseAppBarTitle;

  /// No description provided for @releaseChannelLabel.
  ///
  /// In ar, this message translates to:
  /// **'قناة الإصدار: {channel}'**
  String releaseChannelLabel(String channel);

  /// No description provided for @releaseCanaryPercentLabel.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإصدار التجريبي: {percent}%'**
  String releaseCanaryPercentLabel(int percent);

  /// No description provided for @releaseReadinessLabel.
  ///
  /// In ar, this message translates to:
  /// **'الجاهزية: {percent}%'**
  String releaseReadinessLabel(String percent);

  /// No description provided for @releaseCommandsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أوامر الإصدار'**
  String get releaseCommandsTitle;

  /// No description provided for @releaseStartButton.
  ///
  /// In ar, this message translates to:
  /// **'بدء إصدار الإنتاج'**
  String get releaseStartButton;

  /// No description provided for @releaseActionsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تنفيذ الإصدار غير متاح من التطبيق. استخدم مسار CI/CD المعتمد ودليل النشر.'**
  String get releaseActionsUnavailable;

  /// No description provided for @releaseInitiatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم بدء إصدار الإنتاج بنجاح.'**
  String get releaseInitiatedSuccess;

  /// No description provided for @releaseCheckTestsPassed.
  ///
  /// In ar, this message translates to:
  /// **'اجتازت جميع الاختبارات الحرجة'**
  String get releaseCheckTestsPassed;

  /// No description provided for @releaseCheckAnalyzeClean.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مشكلات في flutter analyze'**
  String get releaseCheckAnalyzeClean;

  /// No description provided for @releaseCheckApiContracts.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من عقود API لنقاط النهاية v1'**
  String get releaseCheckApiContracts;

  /// No description provided for @releaseCheckSecretsVerified.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من مفاتيح الأمان والأسرار'**
  String get releaseCheckSecretsVerified;

  /// No description provided for @releaseCheckQueueChecks.
  ///
  /// In ar, this message translates to:
  /// **'تم إكمال فحوصات إعادة المحاولة وقاطع الدارة'**
  String get releaseCheckQueueChecks;

  /// No description provided for @releaseCheckObservability.
  ///
  /// In ar, this message translates to:
  /// **'تم التحقق من لوحات المراقبة'**
  String get releaseCheckObservability;

  /// No description provided for @releaseCheckRunbook.
  ///
  /// In ar, this message translates to:
  /// **'تمت مراجعة دليل الحوادث مع فريق المناوبة'**
  String get releaseCheckRunbook;

  /// No description provided for @releaseCheckRollback.
  ///
  /// In ar, this message translates to:
  /// **'تم تأكيد واختبار استراتيجية التراجع'**
  String get releaseCheckRollback;

  /// No description provided for @releaseCheckCanaryApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على نسبة الإصدار التجريبي'**
  String get releaseCheckCanaryApproved;

  /// No description provided for @releaseCheckSignoff.
  ///
  /// In ar, this message translates to:
  /// **'تم توثيق موافقة أصحاب المصلحة'**
  String get releaseCheckSignoff;

  /// No description provided for @releaseChecksUnverifiedBanner.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مصدر أدلة آلي متصل بعد بهذه الشاشة — كل بند أدناه غير متحقق منه حتى يُدعم بتشغيل CI حقيقي أو سجل نشر أو وثيقة موافقة فعلية.'**
  String get releaseChecksUnverifiedBanner;

  /// No description provided for @releaseCheckStatusUnverified.
  ///
  /// In ar, this message translates to:
  /// **'غير متحقق منه'**
  String get releaseCheckStatusUnverified;

  /// No description provided for @orgSwitcherAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'المؤسسات'**
  String get orgSwitcherAppBarTitle;

  /// No description provided for @orgSwitcherFailedToSwitch.
  ///
  /// In ar, this message translates to:
  /// **'فشل تبديل المؤسسة.'**
  String get orgSwitcherFailedToSwitch;

  /// No description provided for @orgSwitcherFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المؤسسات. تحقق من الاتصال ثم حاول مرة أخرى.'**
  String get orgSwitcherFailedToLoad;

  /// No description provided for @orgSwitcherRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get orgSwitcherRetry;

  /// No description provided for @orgSwitcherSelectActive.
  ///
  /// In ar, this message translates to:
  /// **'اختر مؤسسة للمتابعة.'**
  String get orgSwitcherSelectActive;

  /// No description provided for @orgSwitcherSwitchedTo.
  ///
  /// In ar, this message translates to:
  /// **'تم التبديل إلى {name}.'**
  String orgSwitcherSwitchedTo(String name);

  /// No description provided for @orgSwitcherWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا، {name}'**
  String orgSwitcherWelcomeTitle(String name);

  /// No description provided for @orgSwitcherWelcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابك في {appName} جاهز. لم يتبقَّ سوى الانضمام إلى مؤسسة لتبدأ النشر.'**
  String orgSwitcherWelcomeSubtitle(String appName);

  /// No description provided for @orgSwitcherEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مؤسسة بعد'**
  String get orgSwitcherEmptyTitle;

  /// No description provided for @orgSwitcherEmpty.
  ///
  /// In ar, this message translates to:
  /// **'أنت لست عضوًا في أي مؤسسة بعد. يحتاج مالك أو مسؤول مؤسسة لإضافتك، أو يمكن لمسؤول المنصة إنشاء مؤسسة لك. يمكنك مع ذلك إدارة أمان حسابك أدناه.'**
  String get orgSwitcherEmpty;

  /// No description provided for @orgSwitcherEmptyAccountAction.
  ///
  /// In ar, this message translates to:
  /// **'أمان الحساب'**
  String get orgSwitcherEmptyAccountAction;

  /// No description provided for @orgSwitcherActiveChip.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get orgSwitcherActiveChip;

  /// No description provided for @orgSwitcherSwitchButton.
  ///
  /// In ar, this message translates to:
  /// **'تبديل'**
  String get orgSwitcherSwitchButton;

  /// No description provided for @orgSwitcherRoleOwner.
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get orgSwitcherRoleOwner;

  /// No description provided for @orgSwitcherRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول'**
  String get orgSwitcherRoleAdmin;

  /// No description provided for @orgSwitcherRoleManager.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get orgSwitcherRoleManager;

  /// No description provided for @orgSwitcherRoleEditor.
  ///
  /// In ar, this message translates to:
  /// **'محرر'**
  String get orgSwitcherRoleEditor;

  /// No description provided for @orgSwitcherRoleViewer.
  ///
  /// In ar, this message translates to:
  /// **'مشاهد'**
  String get orgSwitcherRoleViewer;

  /// No description provided for @postsListAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنشورات'**
  String get postsListAppBarTitle;

  /// No description provided for @postsListCreateTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء منشور'**
  String get postsListCreateTooltip;

  /// No description provided for @postsListHeadline.
  ///
  /// In ar, this message translates to:
  /// **'مكتبة المنشورات'**
  String get postsListHeadline;

  /// No description provided for @postsListSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في مسوداتك ومنشوراتك المجدولة والمنشورة وصفّها وعدّلها.'**
  String get postsListSubtitle;

  /// No description provided for @postsListSearchLabel.
  ///
  /// In ar, this message translates to:
  /// **'البحث في المنشورات'**
  String get postsListSearchLabel;

  /// No description provided for @postsListSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'العنوان أو المحتوى'**
  String get postsListSearchHint;

  /// No description provided for @postsListFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get postsListFilterAll;

  /// No description provided for @postsListFilterDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get postsListFilterDraft;

  /// No description provided for @postsListFilterScheduled.
  ///
  /// In ar, this message translates to:
  /// **'مجدول'**
  String get postsListFilterScheduled;

  /// No description provided for @postsListFilterPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get postsListFilterPublished;

  /// No description provided for @postsListStatusPublishing.
  ///
  /// In ar, this message translates to:
  /// **'قيد النشر'**
  String get postsListStatusPublishing;

  /// No description provided for @postsListStatusFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل'**
  String get postsListStatusFailed;

  /// No description provided for @postsListStatusPartialSuccess.
  ///
  /// In ar, this message translates to:
  /// **'نجاح جزئي'**
  String get postsListStatusPartialSuccess;

  /// No description provided for @postsListStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'أُلغي'**
  String get postsListStatusCancelled;

  /// No description provided for @postsListLoadMore.
  ///
  /// In ar, this message translates to:
  /// **'تحميل المزيد'**
  String get postsListLoadMore;

  /// No description provided for @postsListFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل المنشورات.'**
  String get postsListFailedToLoad;

  /// No description provided for @postsListEditTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المسودة'**
  String get postsListEditTooltip;

  /// No description provided for @postsListNewPostButton.
  ///
  /// In ar, this message translates to:
  /// **'منشور جديد'**
  String get postsListNewPostButton;

  /// No description provided for @postsListEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد منشورات مطابقة لهذا الفلتر.'**
  String get postsListEmpty;

  /// No description provided for @approvalsAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'الموافقات'**
  String get approvalsAppBarTitle;

  /// No description provided for @approvalsHeadline.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الموافقة'**
  String get approvalsHeadline;

  /// No description provided for @approvalsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'منشورات أرسلها محرر للمراجعة — وافق للنشر/الجدولة كما طُلب، أو ارفض مع ملاحظة اختيارية.'**
  String get approvalsSubtitle;

  /// No description provided for @approvalsFailedToLoad.
  ///
  /// In ar, this message translates to:
  /// **'فشل تحميل قائمة الموافقات.'**
  String get approvalsFailedToLoad;

  /// No description provided for @approvalsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ما ينتظر الموافقة حاليًا.'**
  String get approvalsEmpty;

  /// No description provided for @approvalsLoadMore.
  ///
  /// In ar, this message translates to:
  /// **'تحميل المزيد'**
  String get approvalsLoadMore;

  /// No description provided for @approvalsRequestedByMeta.
  ///
  /// In ar, this message translates to:
  /// **'طلبه {name}'**
  String approvalsRequestedByMeta(String name);

  /// No description provided for @approvalsRequestedActionSchedule.
  ///
  /// In ar, this message translates to:
  /// **'الطلب: جدولة'**
  String get approvalsRequestedActionSchedule;

  /// No description provided for @approvalsRequestedActionPublishNow.
  ///
  /// In ar, this message translates to:
  /// **'الطلب: نشر فوري'**
  String get approvalsRequestedActionPublishNow;

  /// No description provided for @approvalsApproveButton.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get approvalsApproveButton;

  /// No description provided for @approvalsRejectButton.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get approvalsRejectButton;

  /// No description provided for @approvalsApproveSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على المنشور.'**
  String get approvalsApproveSuccess;

  /// No description provided for @approvalsRejectSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض المنشور.'**
  String get approvalsRejectSuccess;

  /// No description provided for @approvalsRejectDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفض هذا المنشور؟'**
  String get approvalsRejectDialogTitle;

  /// No description provided for @approvalsRejectDialogNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة لمقدّم الطلب (اختياري)'**
  String get approvalsRejectDialogNoteLabel;

  /// No description provided for @approvalsRejectDialogConfirm.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get approvalsRejectDialogConfirm;

  /// No description provided for @postsListPublishedMeta.
  ///
  /// In ar, this message translates to:
  /// **'نُشر {date}'**
  String postsListPublishedMeta(String date);

  /// No description provided for @postsListScheduledMeta.
  ///
  /// In ar, this message translates to:
  /// **'مجدول {date}'**
  String postsListScheduledMeta(String date);

  /// No description provided for @postsListMediaCountMeta.
  ///
  /// In ar, this message translates to:
  /// **'{count} وسائط'**
  String postsListMediaCountMeta(int count);

  /// No description provided for @postsListPlatformsCountMeta.
  ///
  /// In ar, this message translates to:
  /// **'{count} منصات'**
  String postsListPlatformsCountMeta(int count);

  /// No description provided for @composerFormatBoldTooltip.
  ///
  /// In ar, this message translates to:
  /// **'غامق (تيليجرام فقط — يُحذف في المنصات الأخرى)'**
  String get composerFormatBoldTooltip;

  /// No description provided for @composerFormatItalicTooltip.
  ///
  /// In ar, this message translates to:
  /// **'مائل (تيليجرام فقط — يُحذف في المنصات الأخرى)'**
  String get composerFormatItalicTooltip;

  /// No description provided for @composerInsertEmojiTooltip.
  ///
  /// In ar, this message translates to:
  /// **'إدراج رمز تعبيري'**
  String get composerInsertEmojiTooltip;

  /// No description provided for @moduleHelpCenterTitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get moduleHelpCenterTitle;

  /// No description provided for @moduleHelpCenterDescription.
  ///
  /// In ar, this message translates to:
  /// **'أدلة وأسئلة شائعة وخطوات استخدام {appName}.'**
  String moduleHelpCenterDescription(String appName);

  /// No description provided for @helpIconTooltip.
  ///
  /// In ar, this message translates to:
  /// **'المساعدة'**
  String get helpIconTooltip;

  /// No description provided for @settingsAboutTitle.
  ///
  /// In ar, this message translates to:
  /// **'حول {appName}'**
  String settingsAboutTitle(String appName);

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رقم الإصدار والمنصات المدعومة ونظرة على الأمان.'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsHelpCenterTitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get settingsHelpCenterTitle;

  /// No description provided for @settingsHelpCenterSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل الاستخدام الكامل خطوة بخطوة.'**
  String get settingsHelpCenterSubtitle;

  /// No description provided for @welcomeAboutLinkLabel.
  ///
  /// In ar, this message translates to:
  /// **'حول {appName}'**
  String welcomeAboutLinkLabel(String appName);

  /// No description provided for @aboutAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'حول {appName}'**
  String aboutAppBarTitle(String appName);

  /// No description provided for @aboutSectionDefinitionTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما هو {appName}؟'**
  String aboutSectionDefinitionTitle(String appName);

  /// No description provided for @aboutSectionGoalsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أهداف النظام'**
  String get aboutSectionGoalsTitle;

  /// No description provided for @aboutSectionFeaturesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المزايا المتاحة'**
  String get aboutSectionFeaturesTitle;

  /// No description provided for @aboutSectionPlatformsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المنصات المدعومة'**
  String get aboutSectionPlatformsTitle;

  /// No description provided for @aboutSectionRolesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأدوار داخل المؤسسة'**
  String get aboutSectionRolesTitle;

  /// No description provided for @aboutSectionSecurityTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأمان والخصوصية'**
  String get aboutSectionSecurityTitle;

  /// No description provided for @aboutSectionAppInfoTitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات التطبيق'**
  String get aboutSectionAppInfoTitle;

  /// No description provided for @aboutSectionTeamTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفريق والجهة المالكة'**
  String get aboutSectionTeamTitle;

  /// No description provided for @aboutAppVersionLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الإصدار'**
  String get aboutAppVersionLabel;

  /// No description provided for @aboutAppBuildLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم البناء'**
  String get aboutAppBuildLabel;

  /// No description provided for @aboutAppEnvironmentLabel.
  ///
  /// In ar, this message translates to:
  /// **'البيئة'**
  String get aboutAppEnvironmentLabel;

  /// No description provided for @aboutAppPackageLabel.
  ///
  /// In ar, this message translates to:
  /// **'معرّف الحزمة'**
  String get aboutAppPackageLabel;

  /// No description provided for @aboutCopyrightLabel.
  ///
  /// In ar, this message translates to:
  /// **'جميع الحقوق محفوظة © {year} {holder}.'**
  String aboutCopyrightLabel(String year, String holder);

  /// No description provided for @aboutPrivacyPolicyLink.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get aboutPrivacyPolicyLink;

  /// No description provided for @aboutTermsOfServiceLink.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get aboutTermsOfServiceLink;

  /// No description provided for @aboutDataDeletionLink.
  ///
  /// In ar, this message translates to:
  /// **'حذف بيانات المستخدم'**
  String get aboutDataDeletionLink;

  /// No description provided for @aboutSupportLink.
  ///
  /// In ar, this message translates to:
  /// **'الدعم والتواصل'**
  String get aboutSupportLink;

  /// No description provided for @aboutOpenHelpGuideButton.
  ///
  /// In ar, this message translates to:
  /// **'افتح دليل الاستخدام'**
  String get aboutOpenHelpGuideButton;

  /// No description provided for @aboutLoadErrorMessage.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل بعض معلومات التطبيق.'**
  String get aboutLoadErrorMessage;

  /// No description provided for @aboutSuperAdminRoleNote.
  ///
  /// In ar, this message translates to:
  /// **'صلاحيات مسؤول المنصة موثّقة بصورة منفصلة داخل مساحة إدارة المنصة، ولا تُعرض هنا.'**
  String get aboutSuperAdminRoleNote;

  /// No description provided for @platformStatusAvailableBeta.
  ///
  /// In ar, this message translates to:
  /// **'متاح (تجريبي - Beta)'**
  String get platformStatusAvailableBeta;

  /// No description provided for @platformStatusPartial.
  ///
  /// In ar, this message translates to:
  /// **'متاح جزئيًا'**
  String get platformStatusPartial;

  /// No description provided for @platformStatusComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get platformStatusComingSoon;

  /// No description provided for @platformStatusConnect.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال'**
  String get platformStatusConnect;

  /// No description provided for @platformStatusDiscoverPages.
  ///
  /// In ar, this message translates to:
  /// **'جلب الصفحات'**
  String get platformStatusDiscoverPages;

  /// No description provided for @platformStatusTestConnection.
  ///
  /// In ar, this message translates to:
  /// **'اختبار الاتصال'**
  String get platformStatusTestConnection;

  /// No description provided for @platformStatusPublish.
  ///
  /// In ar, this message translates to:
  /// **'النشر'**
  String get platformStatusPublish;

  /// No description provided for @platformStatusYes.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get platformStatusYes;

  /// No description provided for @platformStatusNo.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح'**
  String get platformStatusNo;

  /// No description provided for @helpCenterAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get helpCenterAppBarTitle;

  /// No description provided for @helpCenterSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كل ما تحتاج معرفته لاستخدام {appName}.'**
  String helpCenterSubtitle(String appName);

  /// No description provided for @helpCenterSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في دليل الاستخدام…'**
  String get helpCenterSearchHint;

  /// No description provided for @helpCenterQuickLinksTitle.
  ///
  /// In ar, this message translates to:
  /// **'روابط سريعة'**
  String get helpCenterQuickLinksTitle;

  /// No description provided for @helpCenterOpenGuideButton.
  ///
  /// In ar, this message translates to:
  /// **'افتح دليل الاستخدام الكامل'**
  String get helpCenterOpenGuideButton;

  /// No description provided for @helpCenterAboutCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'حول النظام'**
  String get helpCenterAboutCardTitle;

  /// No description provided for @helpCenterAboutCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تعرّف على {appName} وميزاته وحالة كل منصة.'**
  String helpCenterAboutCardSubtitle(String appName);

  /// No description provided for @helpCenterFaqCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة الشائعة'**
  String get helpCenterFaqCardTitle;

  /// No description provided for @helpCenterFaqCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إجابات سريعة على الأسئلة المتكررة.'**
  String get helpCenterFaqCardSubtitle;

  /// No description provided for @helpCenterTroubleshootingCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'استكشاف الأخطاء'**
  String get helpCenterTroubleshootingCardTitle;

  /// No description provided for @helpCenterTroubleshootingCardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حلول لأكثر رسائل الخطأ شيوعًا.'**
  String get helpCenterTroubleshootingCardSubtitle;

  /// No description provided for @helpCenterNoOrganizationNotice.
  ///
  /// In ar, this message translates to:
  /// **'أنت لست عضوًا في أي مؤسسة بعد — بعض أقسام الدليل ستفيدك أكثر بعد انضمامك لمؤسسة.'**
  String get helpCenterNoOrganizationNotice;

  /// No description provided for @userGuideAppBarTitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل استخدام {appName}'**
  String userGuideAppBarTitle(String appName);

  /// No description provided for @userGuideSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن موضوع…'**
  String get userGuideSearchHint;

  /// No description provided for @userGuideTocTitle.
  ///
  /// In ar, this message translates to:
  /// **'فهرس الأقسام'**
  String get userGuideTocTitle;

  /// No description provided for @userGuideNoResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get userGuideNoResultsTitle;

  /// No description provided for @userGuideNoResultsMessage.
  ///
  /// In ar, this message translates to:
  /// **'جرّب كلمات بحث مختلفة.'**
  String get userGuideNoResultsMessage;

  /// No description provided for @userGuideClearSearchButton.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get userGuideClearSearchButton;

  /// No description provided for @userGuideFaqSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأسئلة الشائعة'**
  String get userGuideFaqSectionTitle;

  /// No description provided for @userGuideTroubleshootingSectionTitle.
  ///
  /// In ar, this message translates to:
  /// **'استكشاف الأخطاء'**
  String get userGuideTroubleshootingSectionTitle;

  /// No description provided for @userGuideRolePermissionTableTitle.
  ///
  /// In ar, this message translates to:
  /// **'من يستطيع فعل ماذا؟'**
  String get userGuideRolePermissionTableTitle;

  /// No description provided for @userGuideRequiredPermissionBadge.
  ///
  /// In ar, this message translates to:
  /// **'يتطلب: {role}'**
  String userGuideRequiredPermissionBadge(String role);

  /// No description provided for @userGuideNoOrganizationNotice.
  ///
  /// In ar, this message translates to:
  /// **'أنت لست عضوًا في أي مؤسسة بعد — بعض الأقسام أدناه ستنطبق عليك بعد انضمامك لمؤسسة.'**
  String get userGuideNoOrganizationNotice;

  /// No description provided for @platformAdminGuideButton.
  ///
  /// In ar, this message translates to:
  /// **'دليل الإدارة'**
  String get platformAdminGuideButton;

  /// No description provided for @platformAdminGuideDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'دليل مسؤول المنصة'**
  String get platformAdminGuideDialogTitle;

  /// No description provided for @platformAdminUnexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'**
  String get platformAdminUnexpectedError;

  /// No description provided for @platformAdminOwnerListLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل قائمة المستخدمين.'**
  String get platformAdminOwnerListLoadError;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
