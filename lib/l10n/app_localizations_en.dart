// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AuraLearn';

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navMember => 'Member';

  @override
  String get navProfile => 'Me';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonErrorTitle => 'Something went wrong';

  @override
  String commonErrorWithMessage(String message) {
    return 'Couldn\'t load: $message';
  }

  @override
  String get commonGoSettings => 'Open settings';

  @override
  String get commonClear => 'Clear';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String get timeYesterday => 'yesterday';

  @override
  String timeDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String timeTodayAt(String time) {
    return 'today $time';
  }

  @override
  String get subjectGeneral => 'General';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingDefaultName => 'buddy';

  @override
  String get homeGreetingSubtitle => 'Stuck on a problem? Snap it, get it.';

  @override
  String get homeHeroTitle => 'Snap & Solve';

  @override
  String get homeHeroSubtitle => 'Take a photo, get step-by-step help';

  @override
  String get homeTextQuestion => 'Type a question';

  @override
  String get homeHistory => 'History';

  @override
  String get homeStudy => 'Study';

  @override
  String get homeReview => 'Review';

  @override
  String get homeErrorBook => 'Mistakes';

  @override
  String get homeMyDocuments => 'Materials';

  @override
  String get homeRecent => 'Recent';

  @override
  String get homeEmptyRecentTitle => 'No solved problems yet';

  @override
  String get homeEmptyRecentSubtitle =>
      'Snap your first problem and get step-by-step help';

  @override
  String get homeGoSolve => 'Snap a problem';

  @override
  String get viewAll => 'View all';

  @override
  String get usageTitle => 'Monthly usage';

  @override
  String usageQuestions(int used, int limit) {
    return '$used / $limit questions';
  }

  @override
  String usagePercentUsed(int pct) {
    return '$pct% used';
  }

  @override
  String get usageAlmostFull => 'Almost full!';

  @override
  String get usageUpgradeHintFree => 'Upgrade to keep asking questions';

  @override
  String get usageUpgradeHintPaid => 'Upgrade for more questions';

  @override
  String get usageUpgradeButton => 'Upgrade plan';

  @override
  String get planFree => 'FREE';

  @override
  String get planStandard => 'STANDARD';

  @override
  String get planPro => 'PRO';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Sign in to keep learning';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authRememberMe => 'Remember me';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authCreateAccount => 'Sign up';

  @override
  String get authSignInWithGoogle => 'Continue with Google';

  @override
  String get authSignInWithApple => 'Continue with Apple';

  @override
  String get authAppleIosNote => 'Apple sign-in works best on iOS devices';

  @override
  String get authAppleNotSupported =>
      'Apple sign-in is not supported on this device';

  @override
  String get authGoogleCancelled => 'Google sign-in cancelled';

  @override
  String get authAppleCancelled => 'Apple sign-in cancelled';

  @override
  String get authNotConfigured =>
      'Sign-in is not configured. Please contact the developer.';

  @override
  String get authFeatureComingSoon => 'Coming soon';

  @override
  String get authOrDivider => 'or';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerSubtitle => 'A friendly AI tutor for your kid';

  @override
  String get registerName => 'Name';

  @override
  String get registerNameHint => 'What should we call you?';

  @override
  String get registerConfirmPassword => 'Confirm Password';

  @override
  String get registerConfirmPasswordHint => 'Enter your password again';

  @override
  String get registerPasswordRequirements => 'Password requirements:';

  @override
  String get registerReqLength => 'At least 8 characters';

  @override
  String get registerReqLetter => 'Contains a letter';

  @override
  String get registerReqNumber => 'Contains a number';

  @override
  String get registerAcceptPrefix => 'I have read and agree to the';

  @override
  String get registerTerms => 'Terms of Service';

  @override
  String get registerAnd => 'and';

  @override
  String get registerPrivacy => 'Privacy Policy';

  @override
  String get registerButton => 'Sign Up';

  @override
  String get registerHaveAccount => 'Already have an account?';

  @override
  String get registerGoLogin => 'Sign in';

  @override
  String get registerAcceptTermsError =>
      'Please accept the Terms of Service and Privacy Policy first';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboarding1Title => 'Snap & Solve';

  @override
  String get onboarding1Desc =>
      'Snap any problem and your AI tutor explains it step by step';

  @override
  String get onboarding2Title => 'Understand, not just answers';

  @override
  String get onboarding2Desc =>
      'Step-by-step guidance and practice help kids truly get it';

  @override
  String get onboarding3Title => 'Smart mistake review';

  @override
  String get onboarding3Desc => 'Spaced review turns weak spots into strengths';

  @override
  String get adultAckTitle => 'Parent / Teacher Confirmation';

  @override
  String get adultAckBody =>
      'AuraLearn is designed for K-12 students. Accounts are created and managed by a parent or teacher (18+).';

  @override
  String get adultAckCheckbox =>
      'I am 18 or older, creating and managing this account as a parent/teacher, and I agree to the';

  @override
  String get adultAckPrivacy => 'Privacy Policy';

  @override
  String get adultAckStart => 'Get Started';

  @override
  String get cameraTitle => 'Snap a Problem';

  @override
  String cameraSubtitle(int max) {
    return 'Make sure the problem is clear (up to $max photos)';
  }

  @override
  String get cameraTakePhoto => 'Take photo';

  @override
  String get cameraFromGallery => 'Choose from gallery';

  @override
  String get cameraUseText => 'Type instead';

  @override
  String cameraNextWithCount(int count, int max) {
    return 'Next ($count/$max)';
  }

  @override
  String cameraContinueWithCount(int count) {
    return 'Continue ($count selected)';
  }

  @override
  String cameraPermissionNeeded(String name) {
    return '$name access needed';
  }

  @override
  String cameraPermissionRationale(String name) {
    return 'Please allow $name access in system settings to snap problems.';
  }

  @override
  String get cameraPermissionCamera => 'Camera';

  @override
  String get cameraPermissionGallery => 'Photos';

  @override
  String cameraImageTooLarge(int max) {
    return 'Image too large — please pick one under ${max}MB.';
  }

  @override
  String get cameraImagePickFailed =>
      'Couldn\'t get the image. Please try again.';

  @override
  String get cameraImageReadFailed =>
      'Couldn\'t read the image. Please retake it.';

  @override
  String get cameraRemoveImage => 'Remove image';

  @override
  String get cropTitle => 'Crop Questions';

  @override
  String get cropSubmit => 'Submit';

  @override
  String get cropDragToMove => 'Drag to move';

  @override
  String get cropNextImage => 'Next Image';

  @override
  String get cropSubmitQuestion => 'Submit Question';

  @override
  String get cropInstruction => 'Drag the corners to select the question area';

  @override
  String get cropInstructionSub =>
      'Make sure the entire question is within the blue area';

  @override
  String get cropReset => 'Reset crop area';

  @override
  String cropErrorUncropped(int n) {
    return 'Please crop image $n before submitting.';
  }

  @override
  String get cropProcessFailed => 'Failed to process images. Please try again.';

  @override
  String get questionTitle => 'Solve';

  @override
  String get questionInputHint => 'Type your question…';

  @override
  String get questionEmptyHint =>
      'Type your question, or tap the camera to snap a problem.';

  @override
  String get questionTryThese => 'Try one of these:';

  @override
  String get questionSample1 =>
      'A cage has 35 heads and 94 legs — how many chickens and rabbits?';

  @override
  String get questionSample2 => 'Solve the equation: 2x + 5 = 17';

  @override
  String get questionSample3 =>
      'What is the chemical formula of water and which elements is it made of?';

  @override
  String get questionRecognizing => 'Recognizing the problem…';

  @override
  String get questionRecognized => 'Recognized problem';

  @override
  String get questionNoTextRecognized => '(No problem text recognized)';

  @override
  String get questionSolving => 'Solving…';

  @override
  String get questionSteps => 'Steps';

  @override
  String get questionConclusion => 'Conclusion';

  @override
  String questionSolvedBy(String model) {
    return 'Solved by $model';
  }

  @override
  String get questionNoAnswer => 'No answer yet';

  @override
  String get questionNoConclusion => '(No conclusion)';

  @override
  String get questionInterrupted =>
      'The answer was interrupted — the connection seems lost.';

  @override
  String get questionSolveFailed => 'Couldn\'t solve it. Please try again.';

  @override
  String get questionRetrySolve => 'Solve again';

  @override
  String get questionRetake => 'Retake';

  @override
  String get questionAddToErrorBook => 'Save to Mistakes';

  @override
  String get questionAddedToErrorBook => 'Saved to Mistakes';

  @override
  String get questionAddFailed => 'Couldn\'t save. Please try again later.';

  @override
  String questionQuotaUsedUp(int quota) {
    return 'Today\'s free quota is used up ($quota/day)';
  }

  @override
  String get questionQuotaUpgradeHint => 'Upgrade to unlock more solves';

  @override
  String get questionUpgradeNow => 'Upgrade now';

  @override
  String get historyTitle => 'History';

  @override
  String get historySearchHint => 'Search problems, answers…';

  @override
  String get historyEmptyTitle => 'No solved problems yet';

  @override
  String get historyEmptySubtitle =>
      'Your AI tutor teaches step by step\nRecords are saved locally';

  @override
  String get historyNoResults => 'No matching records';

  @override
  String get historyClearFilters => 'Clear filters';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyTags => 'Tags';

  @override
  String get historyEditTags => 'Edit tags';

  @override
  String get historyTagsHint => 'Enter tags, separated by commas';

  @override
  String get historyTagsTapToDelete => 'Tap an existing tag to remove it';

  @override
  String get historyNoQuestionText => '(No problem text)';

  @override
  String get historyDeleteItem => 'Delete this record';

  @override
  String get historyDetailTitle => 'Problem Detail';

  @override
  String get historyDetailPlaceholderTitle => 'Detail view coming soon';

  @override
  String get historyDetailPlaceholderSubtitle =>
      'A full step-by-step view of this problem is on the way.';

  @override
  String get subTitle => 'Member';

  @override
  String get subFree => 'Free';

  @override
  String get subStandard => 'Standard';

  @override
  String get subPro => 'Pro';

  @override
  String subDailyQuota(int quota) {
    return '$quota questions per day';
  }

  @override
  String get subUpgradeToPro => 'Upgrade to Pro';

  @override
  String get subRestorePurchase => 'Restore purchase';

  @override
  String get subProActive => 'Pro active — enjoy unlimited questions';

  @override
  String subValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get subProFeature1 => 'Unlimited questions, no daily cap';

  @override
  String get subProFeature2 => 'Faster solving responses';

  @override
  String get subProFeature3 => 'Manage your subscription anytime';

  @override
  String get subFreeFeature1 => 'Basic question solving';

  @override
  String get subFreeFeature2 => 'Text-based answers';

  @override
  String get subFreeFeature3 => 'Community support';

  @override
  String get subStandardFeature1 => 'Advanced question solving';

  @override
  String get subStandardFeature2 => 'Step-by-step solutions';

  @override
  String get subStandardFeature3 => 'Image recognition';

  @override
  String get subStandardFeature4 => 'History tracking';

  @override
  String get subStandardFeature5 => 'Priority support';

  @override
  String get subGuestTitle => 'Sign in to see plans';

  @override
  String get subGuestSubtitle => 'Sign in to unlock more daily questions';

  @override
  String get subGuestCta => 'Sign in / Register';

  @override
  String get subUnavailableTitle => 'Can\'t load subscription info';

  @override
  String get subUnavailableOffline => 'Check your connection and try again';

  @override
  String get subUnavailableNoAuth => 'Sign in to access subscription services';

  @override
  String get subUnavailableStore =>
      'In-app purchases aren\'t supported on this device';

  @override
  String get subProcessing => 'Processing purchase…';

  @override
  String get subPurchasePending => 'Purchase pending — check back soon';

  @override
  String get subPurchaseFailed => 'Purchase failed';

  @override
  String get subUpgraded => 'You\'re now on Pro';

  @override
  String get subNoRestorable => 'No purchases to restore';

  @override
  String get subRestoreFailed => 'Restore failed';

  @override
  String get profileTitle => 'Me';

  @override
  String get profileLoginPrompt => 'Sign in to view your profile';

  @override
  String get profileLoginSubtitle =>
      'Sign in to sync subscription, usage and settings';

  @override
  String get loginOrRegister => 'Sign in / Register';

  @override
  String get profileAccountInfo => 'Account';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileHelp => 'Help & Support';

  @override
  String get profileAbout => 'About';

  @override
  String get profileLogout => 'Sign out';

  @override
  String get profileLogoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get profileLogoutAction => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsModelMode => 'Answer mode';

  @override
  String get settingsModeSubscription => 'AuraLearn subscription';

  @override
  String get settingsModeSubscriptionDesc =>
      'Uses the app\'s own model service; daily limits apply.';

  @override
  String get settingsModeByok => 'Bring your own key';

  @override
  String get settingsModeByokDesc =>
      'Calls the model vendor directly from this device with your own API key.';

  @override
  String get settingsByokProvider => 'Provider';

  @override
  String get settingsByokApiKey => 'API key';

  @override
  String get settingsByokApiKeyHint => 'Paste your vendor API key';

  @override
  String get settingsByokApiKeyStored => 'A key is saved for this provider';

  @override
  String get settingsByokBaseUrl => 'Base URL';

  @override
  String get settingsByokModel => 'Model';

  @override
  String get settingsByokModelHint => 'Model ID, e.g. gpt-5.6-luna';

  @override
  String get settingsByokReasoningEffort => 'Reasoning effort (optional)';

  @override
  String get settingsByokNoVision =>
      'This provider\'s official API does not support photos — photo solving is unavailable; text questions still work.';

  @override
  String get settingsByokTest => 'Test connection';

  @override
  String get settingsByokTestOk => 'Connection OK';

  @override
  String settingsByokTestFailed(String error) {
    return 'Connection failed: $error';
  }

  @override
  String get settingsByokSaved => 'Saved';

  @override
  String get settingsByokMissing =>
      'Fill in base URL, model and API key first.';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutPrivacy => 'Privacy Policy';

  @override
  String get aboutTerms => 'Terms of Service';

  @override
  String get reviewTitle => 'Today\'s Review';

  @override
  String get reviewQuestion => 'Question';

  @override
  String get reviewAnswer => 'Answer';

  @override
  String get reviewTapToFlip => 'Tap the card to see the answer';

  @override
  String get reviewAgain => 'Again';

  @override
  String get reviewHard => 'Hard';

  @override
  String get reviewGood => 'Good';

  @override
  String get reviewEasy => 'Easy';

  @override
  String get reviewTomorrow => 'Review tomorrow';

  @override
  String reviewInDays(int days) {
    return 'Review in $days days';
  }

  @override
  String get reviewDue => 'Due';

  @override
  String get reviewNoneToday =>
      'No cards to review today — go solve a few problems!';

  @override
  String get reviewDoneTitle => 'Review complete 🎉';

  @override
  String reviewDoneSummary(int reviewed) {
    return 'You reviewed $reviewed cards';
  }

  @override
  String get reviewViewErrorBook => 'Open Mistakes';

  @override
  String get errorBookTitle => 'Mistakes';

  @override
  String get errorBookEmpty => 'Your mistake book is empty';

  @override
  String get errorBookEmptySubtitle =>
      'Problems you get wrong show up here for easy review';

  @override
  String get errorBookDeleteConfirm =>
      'Delete this card from your mistake book?';

  @override
  String get docsTitle => 'My Materials';

  @override
  String get docsImport => 'Import';

  @override
  String get docsImporting => 'Importing…';

  @override
  String get docsImportSubtitle =>
      'Import textbooks, handouts or PDFs and ask questions about them';

  @override
  String get docsEmpty => 'No materials yet';

  @override
  String docsPages(int pages) {
    return '$pages pages';
  }

  @override
  String docsChars(int chars) {
    return '$chars chars';
  }

  @override
  String get docsUntitled => 'Untitled';

  @override
  String get docsNotFound => 'Material not found';

  @override
  String get docsAskHint => 'Ask about this material…';

  @override
  String get docsAskSubtitle =>
      'Ask about this material — your AI tutor explains with its content';

  @override
  String get docsNoText => 'This material has no text to ask about';

  @override
  String get docsImageOnly =>
      '(Image material) Text can\'t be extracted from images. Please use Snap & Solve for image questions.';

  @override
  String docsQuotaUsedUp(int quota) {
    return 'Today\'s free quota is used up ($quota/day) — upgrade to continue';
  }

  @override
  String get docsAnswerInterrupted =>
      'The answer was cut off. Please try again.';

  @override
  String get docsDeleteItem => 'Delete this material';

  @override
  String get docsDeleteConfirm =>
      'Delete this material? This cannot be undone.';

  @override
  String get docsTypeImage => 'Image';

  @override
  String get docsTypeText => 'Text';
}
