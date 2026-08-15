// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'AuraLearn';

  @override
  String get navHome => '首页';

  @override
  String get navHistory => '历史';

  @override
  String get navMember => '会员';

  @override
  String get navProfile => '我的';

  @override
  String get commonRetry => '重试';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonDelete => '删除';

  @override
  String get commonBack => '返回';

  @override
  String get commonNext => '下一步';

  @override
  String get commonSubmit => '提交';

  @override
  String get commonGotIt => '知道了';

  @override
  String get commonLoading => '加载中…';

  @override
  String get commonErrorTitle => '出错了';

  @override
  String commonErrorWithMessage(String message) {
    return '加载失败：$message';
  }

  @override
  String get commonGoSettings => '去设置';

  @override
  String get commonClear => '清除';

  @override
  String get timeJustNow => '刚刚';

  @override
  String timeMinutesAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String timeHoursAgo(int n) {
    return '$n 小时前';
  }

  @override
  String get timeYesterday => '昨天';

  @override
  String timeDaysAgo(int n) {
    return '$n 天前';
  }

  @override
  String timeTodayAt(String time) {
    return '今天 $time';
  }

  @override
  String get subjectGeneral => '综合';

  @override
  String get greetingMorning => '早上好';

  @override
  String get greetingAfternoon => '下午好';

  @override
  String get greetingEvening => '晚上好';

  @override
  String get greetingDefaultName => '同学';

  @override
  String get homeGreetingSubtitle => '有题目不会做？拍一张就懂了';

  @override
  String get homeHeroTitle => '拍照解题';

  @override
  String get homeHeroSubtitle => '拍下题目，立刻获得讲解';

  @override
  String get homeTextQuestion => '文字提问';

  @override
  String get homeHistory => '历史记录';

  @override
  String get homeStudy => '学习';

  @override
  String get homeReview => '今日复习';

  @override
  String get homeErrorBook => '错题本';

  @override
  String get homeMyDocuments => '我的资料';

  @override
  String get homeRecent => '最近解题';

  @override
  String get homeEmptyRecentTitle => '还没有解题记录';

  @override
  String get homeEmptyRecentSubtitle => '拍下第一道题，马上获得分步讲解';

  @override
  String get homeGoSolve => '去拍照解题';

  @override
  String get viewAll => '查看全部';

  @override
  String get usageTitle => '本月用量';

  @override
  String usageQuestions(int used, int limit) {
    return '$used / $limit 题';
  }

  @override
  String usagePercentUsed(int pct) {
    return '已用 $pct%';
  }

  @override
  String get usageAlmostFull => '快用完啦';

  @override
  String get usageUpgradeHintFree => '升级以继续提问';

  @override
  String get usageUpgradeHintPaid => '升级可获得更多提问次数';

  @override
  String get usageUpgradeButton => '升级套餐';

  @override
  String get planFree => '免费版';

  @override
  String get planStandard => '标准版';

  @override
  String get planPro => 'Pro';

  @override
  String get authWelcomeBack => '欢迎回来';

  @override
  String get authLoginSubtitle => '登录以继续学习';

  @override
  String get authEmail => '邮箱';

  @override
  String get authEmailHint => '输入你的邮箱';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '输入你的密码';

  @override
  String get authRememberMe => '记住我';

  @override
  String get authForgotPassword => '忘记密码？';

  @override
  String get authSignIn => '登 录';

  @override
  String get authNoAccount => '还没有账号？';

  @override
  String get authCreateAccount => '注册';

  @override
  String get authSignInWithGoogle => '使用 Google 登录';

  @override
  String get authSignInWithApple => '使用 Apple 登录';

  @override
  String get authAppleIosNote => 'Apple 登录在 iOS 设备上体验最佳';

  @override
  String get authAppleNotSupported => '当前设备不支持 Apple 登录';

  @override
  String get authGoogleCancelled => '已取消 Google 登录';

  @override
  String get authAppleCancelled => '已取消 Apple 登录';

  @override
  String get authNotConfigured => '未配置登录，请联系开发者';

  @override
  String get authFeatureComingSoon => '该功能即将上线';

  @override
  String get authOrDivider => '或';

  @override
  String get authShowPassword => '显示密码';

  @override
  String get authHidePassword => '隐藏密码';

  @override
  String get registerTitle => '创建账号';

  @override
  String get registerSubtitle => '给孩子一个会讲故事的 AI 家教';

  @override
  String get registerName => '昵称';

  @override
  String get registerNameHint => '怎么称呼你？';

  @override
  String get registerConfirmPassword => '确认密码';

  @override
  String get registerConfirmPasswordHint => '再输入一次密码';

  @override
  String get registerPasswordRequirements => '密码要求：';

  @override
  String get registerReqLength => '至少 8 个字符';

  @override
  String get registerReqLetter => '包含字母';

  @override
  String get registerReqNumber => '包含数字';

  @override
  String get registerAcceptPrefix => '我已阅读并同意';

  @override
  String get registerTerms => '《服务条款》';

  @override
  String get registerAnd => '和';

  @override
  String get registerPrivacy => '《隐私政策》';

  @override
  String get registerButton => '注册';

  @override
  String get registerHaveAccount => '已有账号？';

  @override
  String get registerGoLogin => '去登录';

  @override
  String get registerAcceptTermsError => '请先同意服务条款和隐私政策';

  @override
  String get onboardingSkip => '跳过';

  @override
  String get onboardingPrevious => '上一步';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingGetStarted => '开始使用';

  @override
  String get onboarding1Title => '拍照解题';

  @override
  String get onboarding1Desc => '拍下任何题目，AI 家教会一步步讲清楚';

  @override
  String get onboarding2Title => '真正理解，不只是答案';

  @override
  String get onboarding2Desc => '分步讲解、举一反三，帮孩子弄懂每一道题';

  @override
  String get onboarding3Title => '错题自动复习';

  @override
  String get onboarding3Desc => '智能安排复习节奏，薄弱点越练越强';

  @override
  String get adultAckTitle => '家长 / 老师确认';

  @override
  String get adultAckBody => '本应用面向 K-12 学生，账号由家长或老师（已满 18 岁）创建并管理。';

  @override
  String get adultAckCheckbox => '我已年满 18 岁，作为家长/老师创建并管理此账号，并同意';

  @override
  String get adultAckPrivacy => '《隐私政策》';

  @override
  String get adultAckStart => '开始使用';

  @override
  String get cameraTitle => '拍题';

  @override
  String cameraSubtitle(int max) {
    return '拍下题目，确保清晰可见（最多 $max 张）';
  }

  @override
  String get cameraTakePhoto => '拍照';

  @override
  String get cameraFromGallery => '从相册选择';

  @override
  String get cameraUseText => '改用文字输入';

  @override
  String cameraNextWithCount(int count, int max) {
    return '下一步 ($count/$max)';
  }

  @override
  String cameraContinueWithCount(int count) {
    return '继续（已选 $count 张）';
  }

  @override
  String cameraPermissionNeeded(String name) {
    return '需要$name权限';
  }

  @override
  String cameraPermissionRationale(String name) {
    return '请在系统设置中允许访问$name，以便拍题。';
  }

  @override
  String get cameraPermissionCamera => '相机';

  @override
  String get cameraPermissionGallery => '相册';

  @override
  String cameraImageTooLarge(int max) {
    return '图片过大，请选择小于 ${max}MB 的图片。';
  }

  @override
  String get cameraImagePickFailed => '获取图片失败，请重试。';

  @override
  String get cameraImageReadFailed => '无法读取图片，请重新拍摄。';

  @override
  String get cameraRemoveImage => '删除图片';

  @override
  String get cropTitle => '框选题目';

  @override
  String get cropSubmit => '提交';

  @override
  String get cropDragToMove => '拖动调整选区';

  @override
  String get cropNextImage => '下一张';

  @override
  String get cropSubmitQuestion => '提交问题';

  @override
  String get cropInstruction => '拖动四角，框出题目区域';

  @override
  String get cropInstructionSub => '确保整道题都在蓝色框内';

  @override
  String get cropReset => '重置选区';

  @override
  String cropErrorUncropped(int n) {
    return '请先框选第 $n 张图片再提交。';
  }

  @override
  String get cropProcessFailed => '处理图片失败，请重试。';

  @override
  String get questionTitle => '解题';

  @override
  String get questionInputHint => '输入你的问题…';

  @override
  String get questionEmptyHint => '输入你的问题，或点击相机拍下题目。';

  @override
  String get questionTryThese => '试试这些：';

  @override
  String get questionSample1 => '鸡兔同笼，共有 35 个头，94 条腿，各有多少只？';

  @override
  String get questionSample2 => '求解方程：2x + 5 = 17';

  @override
  String get questionSample3 => '水的化学式是什么？由什么元素组成？';

  @override
  String get questionRecognizing => '正在识别题目…';

  @override
  String get questionRecognized => '识别到的题目';

  @override
  String get questionNoTextRecognized => '（未识别到题目文本）';

  @override
  String get questionSolving => '正在解答…';

  @override
  String get questionSteps => '解题步骤';

  @override
  String get questionConclusion => '结论';

  @override
  String questionSolvedBy(String model) {
    return '由 $model 解答';
  }

  @override
  String get questionNoAnswer => '暂无解答';

  @override
  String get questionNoConclusion => '（无结论）';

  @override
  String get questionInterrupted => '解答中断了，连接似乎断开。';

  @override
  String get questionSolveFailed => '解答失败，请重试。';

  @override
  String get questionRetrySolve => '重新解答';

  @override
  String get questionRetake => '重新拍摄';

  @override
  String get questionAddToErrorBook => '加入错题本';

  @override
  String get questionAddedToErrorBook => '已加入错题本';

  @override
  String get questionAddFailed => '加入失败，请稍后再试';

  @override
  String questionQuotaUsedUp(int quota) {
    return '今日免费额度已用完（$quota/天）';
  }

  @override
  String get questionQuotaUpgradeHint => '升级解锁更多解题次数';

  @override
  String get questionUpgradeNow => '立即升级';

  @override
  String get historyTitle => '历史';

  @override
  String get historySearchHint => '搜索题目、解答…';

  @override
  String get historyEmptyTitle => '还没有解题记录';

  @override
  String get historyEmptySubtitle => 'AI 家教会一步步教你\n记录会自动保存在本地';

  @override
  String get historyNoResults => '没有匹配的记录';

  @override
  String get historyClearFilters => '清除筛选';

  @override
  String get historyFilterAll => '全部';

  @override
  String get historyTags => '标签';

  @override
  String get historyEditTags => '编辑标签';

  @override
  String get historyTagsHint => '输入标签，逗号分隔';

  @override
  String get historyTagsTapToDelete => '点击已有标签可删除';

  @override
  String get historyNoQuestionText => '（无题目文字）';

  @override
  String get historyDeleteItem => '删除此记录';

  @override
  String get historyDetailTitle => '题目详情';

  @override
  String get historyDetailPlaceholderTitle => '详情页建设中';

  @override
  String get historyDetailPlaceholderSubtitle => '这道题的一步一步详解正在开发中，敬请期待';

  @override
  String get subTitle => '会员';

  @override
  String get subFree => '免费版';

  @override
  String get subStandard => '标准版';

  @override
  String get subPro => 'Pro 会员';

  @override
  String subDailyQuota(int quota) {
    return '每天 $quota 题';
  }

  @override
  String get subUpgradeToPro => '升级 Pro';

  @override
  String get subRestorePurchase => '恢复购买';

  @override
  String get subProActive => '已开通，畅享无限提问';

  @override
  String subValidUntil(String date) {
    return '有效期至 $date';
  }

  @override
  String get subProFeature1 => '无限提问，不再受每日上限';

  @override
  String get subProFeature2 => '更快的解题响应';

  @override
  String get subProFeature3 => '随时在设置中管理订阅';

  @override
  String get subFreeFeature1 => '基础解题';

  @override
  String get subFreeFeature2 => '文字提问';

  @override
  String get subFreeFeature3 => '社区支持';

  @override
  String get subStandardFeature1 => '进阶解题';

  @override
  String get subStandardFeature2 => '分步讲解';

  @override
  String get subStandardFeature3 => '图片识别';

  @override
  String get subStandardFeature4 => '历史记录';

  @override
  String get subStandardFeature5 => '优先支持';

  @override
  String get subGuestTitle => '登录后查看会员套餐';

  @override
  String get subGuestSubtitle => '登录以解锁更多解题次数';

  @override
  String get subGuestCta => '登录 / 注册';

  @override
  String get subUnavailableTitle => '暂时无法获取订阅信息';

  @override
  String get subUnavailableOffline => '请检查网络后重试';

  @override
  String get subUnavailableNoAuth => '未登录，无法访问订阅服务';

  @override
  String get subUnavailableStore => '当前设备不支持内购';

  @override
  String get subProcessing => '正在处理购买…';

  @override
  String get subPurchasePending => '购买处理中，请稍后查看';

  @override
  String get subPurchaseFailed => '购买失败';

  @override
  String get subUpgraded => '已升级到 Pro 会员';

  @override
  String get subNoRestorable => '没有可恢复的购买';

  @override
  String get subRestoreFailed => '恢复失败';

  @override
  String get profileTitle => '我的';

  @override
  String get profileLoginPrompt => '登录后查看个人资料';

  @override
  String get profileLoginSubtitle => '登录以同步订阅、用量与设置';

  @override
  String get loginOrRegister => '登录 / 注册';

  @override
  String get profileAccountInfo => '账号信息';

  @override
  String get profileSettings => '设置';

  @override
  String get profileHelp => '帮助与支持';

  @override
  String get profileAbout => '关于';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileLogoutConfirm => '确定要退出登录吗？';

  @override
  String get profileLogoutAction => '退出';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsModelMode => '回答方式';

  @override
  String get settingsModeSubscription => 'AuraLearn 订阅';

  @override
  String get settingsModeSubscriptionDesc => '使用应用自带的模型服务，有每日次数限制。';

  @override
  String get settingsModeByok => '自带 Key';

  @override
  String get settingsModeByokDesc => '使用你自己的 API key，从本机直连模型厂商。';

  @override
  String get settingsByokProvider => '服务商';

  @override
  String get settingsByokApiKey => 'API key';

  @override
  String get settingsByokApiKeyHint => '粘贴你的厂商 API key';

  @override
  String get settingsByokApiKeyStored => '该服务商已保存 key';

  @override
  String get settingsByokBaseUrl => '接口地址';

  @override
  String get settingsByokModel => '模型';

  @override
  String get settingsByokModelHint => '模型 ID，如 gpt-5.6-luna';

  @override
  String get settingsByokReasoningEffort => '推理强度（可选）';

  @override
  String get settingsByokNoVision => '该服务商官方 API 不支持图片，拍照解题不可用；纯文字提问不受影响。';

  @override
  String get settingsByokTest => '测试连接';

  @override
  String get settingsByokTestOk => '连接成功';

  @override
  String settingsByokTestFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get settingsByokSaved => '已保存';

  @override
  String get settingsByokSave => '保存';

  @override
  String get settingsByokMissing => '请先填写接口地址、模型和 API key。';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String aboutVersion(String version) {
    return '版本 $version';
  }

  @override
  String get aboutPrivacy => '隐私政策';

  @override
  String get aboutTerms => '服务条款';

  @override
  String get reviewTitle => '今日复习';

  @override
  String get reviewQuestion => '题目';

  @override
  String get reviewAnswer => '答案';

  @override
  String get reviewTapToFlip => '点击卡片查看答案';

  @override
  String get reviewAgain => '不会';

  @override
  String get reviewHard => '模糊';

  @override
  String get reviewGood => '会';

  @override
  String get reviewEasy => '简单';

  @override
  String get reviewTomorrow => '明天复习';

  @override
  String reviewInDays(int days) {
    return '$days 天后复习';
  }

  @override
  String get reviewDue => '待复习';

  @override
  String get reviewNoneToday => '今天没有要复习的卡片，去做几道题吧';

  @override
  String get reviewDoneTitle => '复习完成 🎉';

  @override
  String reviewDoneSummary(int reviewed) {
    return '本次复习了 $reviewed 张卡片';
  }

  @override
  String get reviewViewErrorBook => '查看错题本';

  @override
  String get errorBookTitle => '错题本';

  @override
  String get errorBookEmpty => '错题本还是空的';

  @override
  String get errorBookEmptySubtitle => '做错的题会出现在这里，方便随时复习';

  @override
  String get errorBookDeleteConfirm => '确定要从错题本删除这张卡片吗？';

  @override
  String get docsTitle => '我的资料';

  @override
  String get docsImport => '导入资料';

  @override
  String get docsImporting => '导入中…';

  @override
  String get docsImportSubtitle => '导入课本、讲义或 PDF，向它提问';

  @override
  String get docsEmpty => '还没有导入资料';

  @override
  String docsPages(int pages) {
    return '$pages 页';
  }

  @override
  String docsChars(int chars) {
    return '$chars 字';
  }

  @override
  String get docsUntitled => '未命名资料';

  @override
  String get docsNotFound => '未找到该资料';

  @override
  String get docsAskHint => '针对这份资料提问…';

  @override
  String get docsAskSubtitle => '针对这份资料提问，AI 家教会结合资料内容一步步讲解';

  @override
  String get docsNoText => '这份资料没有可提问的文本内容';

  @override
  String get docsImageOnly => '（图片资料）此资料为图片，无法提取文字。请通过拍照解题流程对图片提问。';

  @override
  String docsQuotaUsedUp(int quota) {
    return '今日免费额度已用完（每天 $quota 题），升级后可继续';
  }

  @override
  String get docsAnswerInterrupted => '回答中断，请重试';

  @override
  String get docsDeleteItem => '删除此资料';

  @override
  String get docsDeleteConfirm => '确定删除这份资料吗？删除后无法恢复。';

  @override
  String get docsTypeImage => '图片';

  @override
  String get docsTypeText => '文本';
}
