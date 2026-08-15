import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AuraLearn'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get navMember;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get navProfile;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load: {message}'**
  String commonErrorWithMessage(String message);

  /// No description provided for @commonGoSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get commonGoSettings;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String timeMinutesAgo(int n);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String timeHoursAgo(int n);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} days ago'**
  String timeDaysAgo(int n);

  /// No description provided for @timeTodayAt.
  ///
  /// In en, this message translates to:
  /// **'today {time}'**
  String timeTodayAt(String time);

  /// No description provided for @subjectGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get subjectGeneral;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingDefaultName.
  ///
  /// In en, this message translates to:
  /// **'buddy'**
  String get greetingDefaultName;

  /// No description provided for @homeGreetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stuck on a problem? Snap it, get it.'**
  String get homeGreetingSubtitle;

  /// No description provided for @homeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Snap & Solve'**
  String get homeHeroTitle;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo, get step-by-step help'**
  String get homeHeroSubtitle;

  /// No description provided for @homeTextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type a question'**
  String get homeTextQuestion;

  /// No description provided for @homeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistory;

  /// No description provided for @homeStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get homeStudy;

  /// No description provided for @homeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get homeReview;

  /// No description provided for @homeErrorBook.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get homeErrorBook;

  /// No description provided for @homeMyDocuments.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get homeMyDocuments;

  /// No description provided for @homeRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// No description provided for @homeEmptyRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'No solved problems yet'**
  String get homeEmptyRecentTitle;

  /// No description provided for @homeEmptyRecentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Snap your first problem and get step-by-step help'**
  String get homeEmptyRecentSubtitle;

  /// No description provided for @homeGoSolve.
  ///
  /// In en, this message translates to:
  /// **'Snap a problem'**
  String get homeGoSolve;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @usageTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly usage'**
  String get usageTitle;

  /// No description provided for @usageQuestions.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit} questions'**
  String usageQuestions(int used, int limit);

  /// No description provided for @usagePercentUsed.
  ///
  /// In en, this message translates to:
  /// **'{pct}% used'**
  String usagePercentUsed(int pct);

  /// No description provided for @usageAlmostFull.
  ///
  /// In en, this message translates to:
  /// **'Almost full!'**
  String get usageAlmostFull;

  /// No description provided for @usageUpgradeHintFree.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to keep asking questions'**
  String get usageUpgradeHintFree;

  /// No description provided for @usageUpgradeHintPaid.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for more questions'**
  String get usageUpgradeHintPaid;

  /// No description provided for @usageUpgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade plan'**
  String get usageUpgradeButton;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'FREE'**
  String get planFree;

  /// No description provided for @planStandard.
  ///
  /// In en, this message translates to:
  /// **'STANDARD'**
  String get planStandard;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get planPro;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to keep learning'**
  String get authLoginSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authRememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get authRememberMe;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authCreateAccount;

  /// No description provided for @authSignInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authSignInWithGoogle;

  /// No description provided for @authSignInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authSignInWithApple;

  /// No description provided for @authAppleIosNote.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in works best on iOS devices'**
  String get authAppleIosNote;

  /// No description provided for @authAppleNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in is not supported on this device'**
  String get authAppleNotSupported;

  /// No description provided for @authGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in cancelled'**
  String get authGoogleCancelled;

  /// No description provided for @authAppleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in cancelled'**
  String get authAppleCancelled;

  /// No description provided for @authNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not configured. Please contact the developer.'**
  String get authNotConfigured;

  /// No description provided for @authFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get authFeatureComingSoon;

  /// No description provided for @authOrDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOrDivider;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A friendly AI tutor for your kid'**
  String get registerSubtitle;

  /// No description provided for @registerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get registerName;

  /// No description provided for @registerNameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get registerNameHint;

  /// No description provided for @registerConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get registerConfirmPassword;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password again'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerPasswordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password requirements:'**
  String get registerPasswordRequirements;

  /// No description provided for @registerReqLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get registerReqLength;

  /// No description provided for @registerReqLetter.
  ///
  /// In en, this message translates to:
  /// **'Contains a letter'**
  String get registerReqLetter;

  /// No description provided for @registerReqNumber.
  ///
  /// In en, this message translates to:
  /// **'Contains a number'**
  String get registerReqNumber;

  /// No description provided for @registerAcceptPrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the'**
  String get registerAcceptPrefix;

  /// No description provided for @registerTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get registerTerms;

  /// No description provided for @registerAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get registerAnd;

  /// No description provided for @registerPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get registerPrivacy;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHaveAccount;

  /// No description provided for @registerGoLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get registerGoLogin;

  /// No description provided for @registerAcceptTermsError.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Terms of Service and Privacy Policy first'**
  String get registerAcceptTermsError;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get onboardingPrevious;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Snap & Solve'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Desc.
  ///
  /// In en, this message translates to:
  /// **'Snap any problem and your AI tutor explains it step by step'**
  String get onboarding1Desc;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Understand, not just answers'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Desc.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step guidance and practice help kids truly get it'**
  String get onboarding2Desc;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Smart mistake review'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Desc.
  ///
  /// In en, this message translates to:
  /// **'Spaced review turns weak spots into strengths'**
  String get onboarding3Desc;

  /// No description provided for @adultAckTitle.
  ///
  /// In en, this message translates to:
  /// **'Parent / Teacher Confirmation'**
  String get adultAckTitle;

  /// No description provided for @adultAckBody.
  ///
  /// In en, this message translates to:
  /// **'AuraLearn is designed for K-12 students. Accounts are created and managed by a parent or teacher (18+).'**
  String get adultAckBody;

  /// No description provided for @adultAckCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I am 18 or older, creating and managing this account as a parent/teacher, and I agree to the'**
  String get adultAckCheckbox;

  /// No description provided for @adultAckPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get adultAckPrivacy;

  /// No description provided for @adultAckStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get adultAckStart;

  /// No description provided for @cameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Snap a Problem'**
  String get cameraTitle;

  /// No description provided for @cameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make sure the problem is clear (up to {max} photos)'**
  String cameraSubtitle(int max);

  /// No description provided for @cameraTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get cameraTakePhoto;

  /// No description provided for @cameraFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get cameraFromGallery;

  /// No description provided for @cameraUseText.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get cameraUseText;

  /// No description provided for @cameraNextWithCount.
  ///
  /// In en, this message translates to:
  /// **'Next ({count}/{max})'**
  String cameraNextWithCount(int count, int max);

  /// No description provided for @cameraContinueWithCount.
  ///
  /// In en, this message translates to:
  /// **'Continue ({count} selected)'**
  String cameraContinueWithCount(int count);

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'{name} access needed'**
  String cameraPermissionNeeded(String name);

  /// No description provided for @cameraPermissionRationale.
  ///
  /// In en, this message translates to:
  /// **'Please allow {name} access in system settings to snap problems.'**
  String cameraPermissionRationale(String name);

  /// No description provided for @cameraPermissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get cameraPermissionCamera;

  /// No description provided for @cameraPermissionGallery.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get cameraPermissionGallery;

  /// No description provided for @cameraImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image too large — please pick one under {max}MB.'**
  String cameraImageTooLarge(int max);

  /// No description provided for @cameraImagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the image. Please try again.'**
  String get cameraImagePickFailed;

  /// No description provided for @cameraImageReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the image. Please retake it.'**
  String get cameraImageReadFailed;

  /// No description provided for @cameraRemoveImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get cameraRemoveImage;

  /// No description provided for @cropTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Questions'**
  String get cropTitle;

  /// No description provided for @cropSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get cropSubmit;

  /// No description provided for @cropDragToMove.
  ///
  /// In en, this message translates to:
  /// **'Drag to move'**
  String get cropDragToMove;

  /// No description provided for @cropNextImage.
  ///
  /// In en, this message translates to:
  /// **'Next Image'**
  String get cropNextImage;

  /// No description provided for @cropSubmitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Submit Question'**
  String get cropSubmitQuestion;

  /// No description provided for @cropInstruction.
  ///
  /// In en, this message translates to:
  /// **'Drag the corners to select the question area'**
  String get cropInstruction;

  /// No description provided for @cropInstructionSub.
  ///
  /// In en, this message translates to:
  /// **'Make sure the entire question is within the blue area'**
  String get cropInstructionSub;

  /// No description provided for @cropReset.
  ///
  /// In en, this message translates to:
  /// **'Reset crop area'**
  String get cropReset;

  /// No description provided for @cropErrorUncropped.
  ///
  /// In en, this message translates to:
  /// **'Please crop image {n} before submitting.'**
  String cropErrorUncropped(int n);

  /// No description provided for @cropProcessFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process images. Please try again.'**
  String get cropProcessFailed;

  /// No description provided for @questionTitle.
  ///
  /// In en, this message translates to:
  /// **'Solve'**
  String get questionTitle;

  /// No description provided for @questionInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question…'**
  String get questionInputHint;

  /// No description provided for @questionEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question, or tap the camera to snap a problem.'**
  String get questionEmptyHint;

  /// No description provided for @questionTryThese.
  ///
  /// In en, this message translates to:
  /// **'Try one of these:'**
  String get questionTryThese;

  /// No description provided for @questionSample1.
  ///
  /// In en, this message translates to:
  /// **'A cage has 35 heads and 94 legs — how many chickens and rabbits?'**
  String get questionSample1;

  /// No description provided for @questionSample2.
  ///
  /// In en, this message translates to:
  /// **'Solve the equation: 2x + 5 = 17'**
  String get questionSample2;

  /// No description provided for @questionSample3.
  ///
  /// In en, this message translates to:
  /// **'What is the chemical formula of water and which elements is it made of?'**
  String get questionSample3;

  /// No description provided for @questionRecognizing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing the problem…'**
  String get questionRecognizing;

  /// No description provided for @questionRecognized.
  ///
  /// In en, this message translates to:
  /// **'Recognized problem'**
  String get questionRecognized;

  /// No description provided for @questionNoTextRecognized.
  ///
  /// In en, this message translates to:
  /// **'(No problem text recognized)'**
  String get questionNoTextRecognized;

  /// No description provided for @questionSolving.
  ///
  /// In en, this message translates to:
  /// **'Solving…'**
  String get questionSolving;

  /// No description provided for @questionSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get questionSteps;

  /// No description provided for @questionConclusion.
  ///
  /// In en, this message translates to:
  /// **'Conclusion'**
  String get questionConclusion;

  /// No description provided for @questionSolvedBy.
  ///
  /// In en, this message translates to:
  /// **'Solved by {model}'**
  String questionSolvedBy(String model);

  /// No description provided for @questionNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No answer yet'**
  String get questionNoAnswer;

  /// No description provided for @questionNoConclusion.
  ///
  /// In en, this message translates to:
  /// **'(No conclusion)'**
  String get questionNoConclusion;

  /// No description provided for @questionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The answer was interrupted — the connection seems lost.'**
  String get questionInterrupted;

  /// No description provided for @questionSolveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t solve it. Please try again.'**
  String get questionSolveFailed;

  /// No description provided for @questionRetrySolve.
  ///
  /// In en, this message translates to:
  /// **'Solve again'**
  String get questionRetrySolve;

  /// No description provided for @questionRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get questionRetake;

  /// No description provided for @questionAddToErrorBook.
  ///
  /// In en, this message translates to:
  /// **'Save to Mistakes'**
  String get questionAddToErrorBook;

  /// No description provided for @questionAddedToErrorBook.
  ///
  /// In en, this message translates to:
  /// **'Saved to Mistakes'**
  String get questionAddedToErrorBook;

  /// No description provided for @questionAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again later.'**
  String get questionAddFailed;

  /// No description provided for @questionQuotaUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Today\'s free quota is used up ({quota}/day)'**
  String questionQuotaUsedUp(int quota);

  /// No description provided for @questionQuotaUpgradeHint.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock more solves'**
  String get questionQuotaUpgradeHint;

  /// No description provided for @questionUpgradeNow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade now'**
  String get questionUpgradeNow;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search problems, answers…'**
  String get historySearchHint;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No solved problems yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI tutor teaches step by step\nRecords are saved locally'**
  String get historyEmptySubtitle;

  /// No description provided for @historyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching records'**
  String get historyNoResults;

  /// No description provided for @historyClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get historyClearFilters;

  /// No description provided for @historyFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyFilterAll;

  /// No description provided for @historyTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get historyTags;

  /// No description provided for @historyEditTags.
  ///
  /// In en, this message translates to:
  /// **'Edit tags'**
  String get historyEditTags;

  /// No description provided for @historyTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tags, separated by commas'**
  String get historyTagsHint;

  /// No description provided for @historyTagsTapToDelete.
  ///
  /// In en, this message translates to:
  /// **'Tap an existing tag to remove it'**
  String get historyTagsTapToDelete;

  /// No description provided for @historyNoQuestionText.
  ///
  /// In en, this message translates to:
  /// **'(No problem text)'**
  String get historyNoQuestionText;

  /// No description provided for @historyDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete this record'**
  String get historyDeleteItem;

  /// No description provided for @historyDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Problem Detail'**
  String get historyDetailTitle;

  /// No description provided for @historyDetailPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail view coming soon'**
  String get historyDetailPlaceholderTitle;

  /// No description provided for @historyDetailPlaceholderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A full step-by-step view of this problem is on the way.'**
  String get historyDetailPlaceholderSubtitle;

  /// No description provided for @subTitle.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get subTitle;

  /// No description provided for @subFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subFree;

  /// No description provided for @subStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get subStandard;

  /// No description provided for @subPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get subPro;

  /// No description provided for @subDailyQuota.
  ///
  /// In en, this message translates to:
  /// **'{quota} questions per day'**
  String subDailyQuota(int quota);

  /// No description provided for @subUpgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get subUpgradeToPro;

  /// No description provided for @subRestorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get subRestorePurchase;

  /// No description provided for @subProActive.
  ///
  /// In en, this message translates to:
  /// **'Pro active — enjoy unlimited questions'**
  String get subProActive;

  /// No description provided for @subValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String subValidUntil(String date);

  /// No description provided for @subProFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited questions, no daily cap'**
  String get subProFeature1;

  /// No description provided for @subProFeature2.
  ///
  /// In en, this message translates to:
  /// **'Faster solving responses'**
  String get subProFeature2;

  /// No description provided for @subProFeature3.
  ///
  /// In en, this message translates to:
  /// **'Manage your subscription anytime'**
  String get subProFeature3;

  /// No description provided for @subFreeFeature1.
  ///
  /// In en, this message translates to:
  /// **'Basic question solving'**
  String get subFreeFeature1;

  /// No description provided for @subFreeFeature2.
  ///
  /// In en, this message translates to:
  /// **'Text-based answers'**
  String get subFreeFeature2;

  /// No description provided for @subFreeFeature3.
  ///
  /// In en, this message translates to:
  /// **'Community support'**
  String get subFreeFeature3;

  /// No description provided for @subStandardFeature1.
  ///
  /// In en, this message translates to:
  /// **'Advanced question solving'**
  String get subStandardFeature1;

  /// No description provided for @subStandardFeature2.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step solutions'**
  String get subStandardFeature2;

  /// No description provided for @subStandardFeature3.
  ///
  /// In en, this message translates to:
  /// **'Image recognition'**
  String get subStandardFeature3;

  /// No description provided for @subStandardFeature4.
  ///
  /// In en, this message translates to:
  /// **'History tracking'**
  String get subStandardFeature4;

  /// No description provided for @subStandardFeature5.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get subStandardFeature5;

  /// No description provided for @subGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see plans'**
  String get subGuestTitle;

  /// No description provided for @subGuestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock more daily questions'**
  String get subGuestSubtitle;

  /// No description provided for @subGuestCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Register'**
  String get subGuestCta;

  /// No description provided for @subUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t load subscription info'**
  String get subUnavailableTitle;

  /// No description provided for @subUnavailableOffline.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get subUnavailableOffline;

  /// No description provided for @subUnavailableNoAuth.
  ///
  /// In en, this message translates to:
  /// **'Sign in to access subscription services'**
  String get subUnavailableNoAuth;

  /// No description provided for @subUnavailableStore.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases aren\'t supported on this device'**
  String get subUnavailableStore;

  /// No description provided for @subProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing purchase…'**
  String get subProcessing;

  /// No description provided for @subPurchasePending.
  ///
  /// In en, this message translates to:
  /// **'Purchase pending — check back soon'**
  String get subPurchasePending;

  /// No description provided for @subPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get subPurchaseFailed;

  /// No description provided for @subUpgraded.
  ///
  /// In en, this message translates to:
  /// **'You\'re now on Pro'**
  String get subUpgraded;

  /// No description provided for @subNoRestorable.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore'**
  String get subNoRestorable;

  /// No description provided for @subRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get subRestoreFailed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get profileTitle;

  /// No description provided for @profileLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your profile'**
  String get profileLoginPrompt;

  /// No description provided for @profileLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync subscription, usage and settings'**
  String get profileLoginSubtitle;

  /// No description provided for @loginOrRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign in / Register'**
  String get loginOrRegister;

  /// No description provided for @profileAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountInfo;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelp;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileLogoutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileLogoutAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsModelMode.
  ///
  /// In en, this message translates to:
  /// **'Answer mode'**
  String get settingsModelMode;

  /// No description provided for @settingsModeSubscription.
  ///
  /// In en, this message translates to:
  /// **'AuraLearn subscription'**
  String get settingsModeSubscription;

  /// No description provided for @settingsModeSubscriptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Uses the app\'s own model service; daily limits apply.'**
  String get settingsModeSubscriptionDesc;

  /// No description provided for @settingsModeByok.
  ///
  /// In en, this message translates to:
  /// **'Bring your own key'**
  String get settingsModeByok;

  /// No description provided for @settingsModeByokDesc.
  ///
  /// In en, this message translates to:
  /// **'Calls the model vendor directly from this device with your own API key.'**
  String get settingsModeByokDesc;

  /// No description provided for @settingsByokProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsByokProvider;

  /// No description provided for @settingsByokApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get settingsByokApiKey;

  /// No description provided for @settingsByokApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your vendor API key'**
  String get settingsByokApiKeyHint;

  /// No description provided for @settingsByokApiKeyStored.
  ///
  /// In en, this message translates to:
  /// **'A key is saved for this provider'**
  String get settingsByokApiKeyStored;

  /// No description provided for @settingsByokBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get settingsByokBaseUrl;

  /// No description provided for @settingsByokModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsByokModel;

  /// No description provided for @settingsByokModelHint.
  ///
  /// In en, this message translates to:
  /// **'Model ID, e.g. gpt-5.6-luna'**
  String get settingsByokModelHint;

  /// No description provided for @settingsByokReasoningEffort.
  ///
  /// In en, this message translates to:
  /// **'Reasoning effort (optional)'**
  String get settingsByokReasoningEffort;

  /// No description provided for @settingsByokNoVision.
  ///
  /// In en, this message translates to:
  /// **'This provider\'s official API does not support photos — photo solving is unavailable; text questions still work.'**
  String get settingsByokNoVision;

  /// No description provided for @settingsByokTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get settingsByokTest;

  /// No description provided for @settingsByokTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connection OK'**
  String get settingsByokTestOk;

  /// No description provided for @settingsByokTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String settingsByokTestFailed(String error);

  /// No description provided for @settingsByokSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get settingsByokSaved;

  /// No description provided for @settingsByokSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsByokSave;

  /// No description provided for @settingsByokMissing.
  ///
  /// In en, this message translates to:
  /// **'Fill in base URL, model and API key first.'**
  String get settingsByokMissing;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacy;

  /// No description provided for @aboutTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get aboutTerms;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Review'**
  String get reviewTitle;

  /// No description provided for @reviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get reviewQuestion;

  /// No description provided for @reviewAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get reviewAnswer;

  /// No description provided for @reviewTapToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to see the answer'**
  String get reviewTapToFlip;

  /// No description provided for @reviewAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get reviewAgain;

  /// No description provided for @reviewHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get reviewHard;

  /// No description provided for @reviewGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewGood;

  /// No description provided for @reviewEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get reviewEasy;

  /// No description provided for @reviewTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Review tomorrow'**
  String get reviewTomorrow;

  /// No description provided for @reviewInDays.
  ///
  /// In en, this message translates to:
  /// **'Review in {days} days'**
  String reviewInDays(int days);

  /// No description provided for @reviewDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get reviewDue;

  /// No description provided for @reviewNoneToday.
  ///
  /// In en, this message translates to:
  /// **'No cards to review today — go solve a few problems!'**
  String get reviewNoneToday;

  /// No description provided for @reviewDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Review complete 🎉'**
  String get reviewDoneTitle;

  /// No description provided for @reviewDoneSummary.
  ///
  /// In en, this message translates to:
  /// **'You reviewed {reviewed} cards'**
  String reviewDoneSummary(int reviewed);

  /// No description provided for @reviewViewErrorBook.
  ///
  /// In en, this message translates to:
  /// **'Open Mistakes'**
  String get reviewViewErrorBook;

  /// No description provided for @errorBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get errorBookTitle;

  /// No description provided for @errorBookEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your mistake book is empty'**
  String get errorBookEmpty;

  /// No description provided for @errorBookEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Problems you get wrong show up here for easy review'**
  String get errorBookEmptySubtitle;

  /// No description provided for @errorBookDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this card from your mistake book?'**
  String get errorBookDeleteConfirm;

  /// No description provided for @docsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Materials'**
  String get docsTitle;

  /// No description provided for @docsImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get docsImport;

  /// No description provided for @docsImporting.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get docsImporting;

  /// No description provided for @docsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import textbooks, handouts or PDFs and ask questions about them'**
  String get docsImportSubtitle;

  /// No description provided for @docsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No materials yet'**
  String get docsEmpty;

  /// No description provided for @docsPages.
  ///
  /// In en, this message translates to:
  /// **'{pages} pages'**
  String docsPages(int pages);

  /// No description provided for @docsChars.
  ///
  /// In en, this message translates to:
  /// **'{chars} chars'**
  String docsChars(int chars);

  /// No description provided for @docsUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get docsUntitled;

  /// No description provided for @docsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Material not found'**
  String get docsNotFound;

  /// No description provided for @docsAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about this material…'**
  String get docsAskHint;

  /// No description provided for @docsAskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about this material — your AI tutor explains with its content'**
  String get docsAskSubtitle;

  /// No description provided for @docsNoText.
  ///
  /// In en, this message translates to:
  /// **'This material has no text to ask about'**
  String get docsNoText;

  /// No description provided for @docsImageOnly.
  ///
  /// In en, this message translates to:
  /// **'(Image material) Text can\'t be extracted from images. Please use Snap & Solve for image questions.'**
  String get docsImageOnly;

  /// No description provided for @docsQuotaUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Today\'s free quota is used up ({quota}/day) — upgrade to continue'**
  String docsQuotaUsedUp(int quota);

  /// No description provided for @docsAnswerInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The answer was cut off. Please try again.'**
  String get docsAnswerInterrupted;

  /// No description provided for @docsDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete this material'**
  String get docsDeleteItem;

  /// No description provided for @docsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this material? This cannot be undone.'**
  String get docsDeleteConfirm;

  /// No description provided for @docsTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get docsTypeImage;

  /// No description provided for @docsTypeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get docsTypeText;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
