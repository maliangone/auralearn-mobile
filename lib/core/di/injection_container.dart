import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../database/app_database.dart';
import '../database/connection.dart';
import '../i18n/locale_cubit.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/logging_interceptor.dart';
import '../network/streaming/solve_client.dart';
import '../storage/local_storage.dart';
import '../storage/secure_token_store.dart';
import '../utils/logger.dart';
import '../llm/model_config.dart';
import '../llm/solve_service.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/oauth_data_source.dart';
import '../../features/auth/data/datasources/mock_auth_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/oauth_login_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/question/data/datasources/question_remote_data_source.dart';
import '../../features/question/data/datasources/question_local_data_source.dart';
import '../../features/question/data/repositories/question_repository_impl.dart';
import '../../features/question/domain/repositories/question_repository.dart';
import '../../features/question/domain/usecases/submit_question_usecase.dart';
import '../../features/question/domain/usecases/upload_images_usecase.dart';
import '../../features/question/presentation/bloc/question_bloc.dart';

import '../../features/history/data/datasources/history_local_data_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/get_history_usecase.dart';
import '../../features/history/domain/usecases/delete_history_item_usecase.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';

import '../../features/flashcards/data/datasources/flashcard_local_data_source.dart';
import '../../features/flashcards/data/repositories/flashcard_repository_impl.dart';
import '../../features/flashcards/domain/repositories/flashcard_repository.dart';
import '../../features/flashcards/domain/usecases/get_due_cards_usecase.dart';
import '../../features/flashcards/domain/usecases/review_card_usecase.dart';
import '../../features/flashcards/domain/usecases/get_all_flashcards_usecase.dart';
import '../../features/flashcards/domain/usecases/delete_flashcard_usecase.dart';
import '../../features/flashcards/domain/usecases/create_flashcard_from_history_usecase.dart';
import '../../features/flashcards/presentation/bloc/review_bloc.dart';
import '../../features/flashcards/presentation/bloc/error_book_bloc.dart';

import '../../features/subscription/data/datasources/subscription_remote_data_source.dart';
import '../../features/subscription/data/datasources/subscription_local_data_source.dart';
import '../../features/subscription/data/datasources/mock_subscription_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/get_subscription_status_usecase.dart';
import '../../features/subscription/domain/usecases/purchase_subscription_usecase.dart';
import '../../features/subscription/data/datasources/billing_remote_data_source.dart';
import '../../features/subscription/data/datasources/purchase_service.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';

import '../../features/documents/data/datasources/document_local_data_source.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
import '../../features/documents/domain/usecases/get_documents_usecase.dart';
import '../../features/documents/domain/usecases/delete_document_usecase.dart';
import '../../features/documents/domain/usecases/import_document_usecase.dart';
import '../../features/documents/presentation/bloc/documents_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  AppLogger.info('Setting up dependencies...');

  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Local-first authoritative SQLite store (Drift). Opened async then
  // registered as a ready singleton so downstream lazy resolution is sync.
  final db = await openAppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  // Secure token store (Keychain / EncryptedSharedPreferences) for sensitive
  // auth tokens, plus a one-time migration of legacy plaintext tokens.
  getIt.registerLazySingleton<SecureTokenStore>(() => SecureTokenStore.create());
  await getIt<SecureTokenStore>().migrateFromSharedPreferences(sharedPreferences);

  // Core dependencies
  getIt.registerLazySingleton<LocalStorage>(() => LocalStorage(getIt()));

  // LLM model config (subscription-proxy vs BYOK-direct mode) — prefs + secure
  // key storage.
  getIt.registerLazySingleton<ModelConfigStore>(
    () => ModelConfigStore(getIt<LocalStorage>(), getIt<SecureTokenStore>()),
  );

  // App locale (zh/en) — persisted device-level setting.
  getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(getIt<LocalStorage>()));

  // Network dependencies
  getIt.registerLazySingleton<Dio>(() => _createDio());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

  // Auth dependencies
  _setupAuthDependencies();

  // Question dependencies
  _setupQuestionDependencies();

  // History dependencies
  _setupHistoryDependencies();

  // Flashcards / 错题本 dependencies (local-first; depends on AppDatabase).
  _setupFlashcardDependencies();

  // Subscription dependencies
  _setupSubscriptionDependencies();

  // Document import (Phase C) — local-first, context-stuffing Q&A.
  _setupDocumentDependencies();

  AppLogger.info('Dependencies setup completed');
}

Dio _createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: 30000, // 30 seconds in milliseconds
    receiveTimeout: 30000, // 30 seconds in milliseconds
    sendTimeout: 30000, // 30 seconds in milliseconds
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  if (AppConfig.isDebug) {
    dio.interceptors.add(LoggingInterceptor());
  }

  dio.interceptors.add(AuthInterceptor(getIt<SecureTokenStore>()));

  return dio;
}

void _setupAuthDependencies() {
  // Data sources
  if (!AppConfig.enableMockMode) {
    getIt.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(getIt<ApiClient>()),
    );
  }

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(getIt<LocalStorage>(), getIt<SecureTokenStore>()),
  );

  // OAuth data source (always available for real OAuth)
  getIt.registerLazySingleton<OAuthDataSource>(
    () => OAuthDataSourceImpl(),
  );

  // Mock data source for debug mode
  if (AppConfig.enableMockMode) {
    getIt.registerLazySingleton<MockAuthDataSource>(
      () => MockAuthDataSource(),
    );
  }

  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource:
          AppConfig.enableMockMode ? null : getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      oauthDataSource: getIt<OAuthDataSource>(),
      mockDataSource:
          AppConfig.enableMockMode ? getIt<MockAuthDataSource>() : null,
    ),
  );

  // Use cases
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<CheckAuthStatusUseCase>(
    () => CheckAuthStatusUseCase(getIt<AuthRepository>()),
  );

  // OAuth use cases
  getIt.registerLazySingleton<GoogleSignInUseCase>(
    () => GoogleSignInUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<AppleSignInUseCase>(
    () => AppleSignInUseCase(getIt<AuthRepository>()),
  );

  // Bloc
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      registerUseCase: getIt<RegisterUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      checkAuthStatusUseCase: getIt<CheckAuthStatusUseCase>(),
      googleSignInUseCase: getIt<GoogleSignInUseCase>(),
      appleSignInUseCase: getIt<AppleSignInUseCase>(),
      purchases: getIt<PurchaseService>(),
    ),
  );
}

void _setupQuestionDependencies() {
  // Data sources
  getIt.registerLazySingleton<QuestionRemoteDataSource>(
    () => QuestionRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<QuestionLocalDataSource>(
    () => QuestionLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // Repository
  getIt.registerLazySingleton<QuestionRepository>(
    () => QuestionRepositoryImpl(
      remoteDataSource: getIt<QuestionRemoteDataSource>(),
      localDataSource: getIt<QuestionLocalDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<SubmitQuestionUseCase>(
    () => SubmitQuestionUseCase(getIt<QuestionRepository>()),
  );
  getIt.registerLazySingleton<UploadImagesUseCase>(
    () => UploadImagesUseCase(getIt<QuestionRepository>()),
  );

  // Streaming solve client.
  //
  // Registered as a *factory* (not a lazy singleton): QuestionBloc.close()
  // calls solveClient.close(), and QuestionBloc is itself a factory. A shared
  // singleton would be torn down by the first disposed bloc, leaving later
  // blocs with a closed HTTP client.
  getIt.registerFactory<SolveClient>(() => SolveClient());

  // Solve service — picks subscription-proxy vs BYOK-direct from the persisted
  // ModelConfig at each call. Factory like SolveClient: the owning bloc closes
  // the transport on dispose.
  getIt.registerFactory<SolveService>(
    () => SolveServiceFactory(
      getIt<ModelConfigStore>(),
      ProxySolveService(getIt<SolveClient>(), getIt<SecureTokenStore>()),
      DirectSolveService(getIt<ModelConfigStore>()),
    ),
  );

  // Bloc
  getIt.registerFactory<QuestionBloc>(
    () => QuestionBloc(
      submitQuestionUseCase: getIt<SubmitQuestionUseCase>(),
      solveService: getIt<SolveService>(),
      localDataSource: getIt<QuestionLocalDataSource>(),
    ),
  );
}

void _setupHistoryDependencies() {
  // Data sources — history is 100% local-first now; no remote datasource.
  getIt.registerLazySingleton<HistoryLocalDataSource>(
    () => HistoryLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // Repository (pure local-first; no remote sync channel).
  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      localDataSource: getIt<HistoryLocalDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetHistoryUseCase>(
    () => GetHistoryUseCase(getIt<HistoryRepository>()),
  );
  getIt.registerLazySingleton<DeleteHistoryItemUseCase>(
    () => DeleteHistoryItemUseCase(getIt<HistoryRepository>()),
  );

  // Bloc
  getIt.registerFactory<HistoryBloc>(
    () => HistoryBloc(
      getHistoryUseCase: getIt<GetHistoryUseCase>(),
      deleteHistoryItemUseCase: getIt<DeleteHistoryItemUseCase>(),
      repository: getIt<HistoryRepository>(),
    ),
  );
}

void _setupFlashcardDependencies() {
  // Data source — local-first authoritative store (Drift), no remote channel.
  getIt.registerLazySingleton<FlashcardLocalDataSource>(
    () => FlashcardLocalDataSourceImpl(getIt<AppDatabase>()),
  );

  // Repository
  getIt.registerLazySingleton<FlashcardRepository>(
    () => FlashcardRepositoryImpl(localDataSource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton<GetDueCardsUseCase>(
    () => GetDueCardsUseCase(getIt<FlashcardRepository>()),
  );
  getIt.registerLazySingleton<ReviewCardUseCase>(
    () => ReviewCardUseCase(getIt<FlashcardRepository>()),
  );
  getIt.registerLazySingleton<GetAllFlashcardsUseCase>(
    () => GetAllFlashcardsUseCase(getIt<FlashcardRepository>()),
  );
  getIt.registerLazySingleton<DeleteFlashcardUseCase>(
    () => DeleteFlashcardUseCase(getIt<FlashcardRepository>()),
  );
  getIt.registerLazySingleton<CreateFlashcardFromHistoryUseCase>(
    () => CreateFlashcardFromHistoryUseCase(getIt<FlashcardRepository>()),
  );

  // Blocs
  getIt.registerFactory<ReviewBloc>(
    () => ReviewBloc(
      getDueCardsUseCase: getIt<GetDueCardsUseCase>(),
      reviewCardUseCase: getIt<ReviewCardUseCase>(),
    ),
  );
  getIt.registerFactory<ErrorBookBloc>(
    () => ErrorBookBloc(
      getAllFlashcardsUseCase: getIt<GetAllFlashcardsUseCase>(),
      deleteFlashcardUseCase: getIt<DeleteFlashcardUseCase>(),
    ),
  );
}

void _setupSubscriptionDependencies() {
  // Data sources
  if (!AppConfig.enableMockMode) {
    getIt.registerLazySingleton<SubscriptionRemoteDataSource>(
      () => SubscriptionRemoteDataSourceImpl(getIt<ApiClient>()),
    );
  }

  getIt.registerLazySingleton<SubscriptionLocalDataSource>(
    () => SubscriptionLocalDataSourceImpl(getIt<LocalStorage>()),
  );

  // Mock data source for debug mode
  if (AppConfig.enableMockMode) {
    getIt.registerLazySingleton<MockSubscriptionDataSource>(
      () => MockSubscriptionDataSource(),
    );
  }

  // Repository - will be updated to use mock when needed
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      remoteDataSource: AppConfig.enableMockMode
          ? null
          : getIt<SubscriptionRemoteDataSource>(),
      localDataSource: getIt<SubscriptionLocalDataSource>(),
      mockDataSource:
          AppConfig.enableMockMode ? getIt<MockSubscriptionDataSource>() : null,
    ),
  );

  // Use cases
  getIt.registerLazySingleton<GetSubscriptionStatusUseCase>(
    () => GetSubscriptionStatusUseCase(getIt<SubscriptionRepository>()),
  );
  getIt.registerLazySingleton<PurchaseSubscriptionUseCase>(
    () => PurchaseSubscriptionUseCase(getIt<SubscriptionRepository>()),
  );

  // Phase 3 billing: RevenueCat-authoritative. The client talks to
  // /billing/sync + /billing/status; receipts never leave the store SDK.
  getIt.registerLazySingleton<BillingRemoteDataSource>(
    () => BillingRemoteDataSourceImpl(tokenStore: getIt<SecureTokenStore>()),
  );

  // RevenueCat store service (configured only when RC_* dart-defines exist).
  getIt.registerLazySingleton<PurchaseService>(() => PurchaseService());

  // Bloc (Phase 3: entitlement-authoritative, RevenueCat-driven).
  getIt.registerFactory<SubscriptionBloc>(
    () => SubscriptionBloc(
      billing: getIt<BillingRemoteDataSource>(),
      purchases: getIt<PurchaseService>(),
    ),
  );
}

void _setupDocumentDependencies() {
  // Local-first authoritative datasource (Drift) + repository.
  getIt.registerLazySingleton<DocumentLocalDataSource>(
    () => DocumentLocalDataSourceImpl(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(localDataSource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton<GetDocumentsUseCase>(
    () => GetDocumentsUseCase(getIt<DocumentRepository>()),
  );
  getIt.registerLazySingleton<DeleteDocumentUseCase>(
    () => DeleteDocumentUseCase(getIt<DocumentRepository>()),
  );
  getIt.registerLazySingleton<ImportDocumentUseCase>(
    () => ImportDocumentUseCase(repository: getIt<DocumentRepository>()),
  );

  // Bloc
  getIt.registerFactory<DocumentsBloc>(
    () => DocumentsBloc(
      getDocuments: getIt<GetDocumentsUseCase>(),
      importDocument: getIt<ImportDocumentUseCase>(),
      deleteDocument: getIt<DeleteDocumentUseCase>(),
    ),
  );
}
