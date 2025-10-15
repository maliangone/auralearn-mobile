import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../network/logging_interceptor.dart';
import '../storage/local_storage.dart';
import '../utils/logger.dart';

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

import '../../features/history/data/datasources/history_remote_data_source.dart';
import '../../features/history/data/datasources/history_local_data_source.dart';
import '../../features/history/data/repositories/history_repository_impl.dart';
import '../../features/history/domain/repositories/history_repository.dart';
import '../../features/history/domain/usecases/get_history_usecase.dart';
import '../../features/history/domain/usecases/delete_history_item_usecase.dart';
import '../../features/history/presentation/bloc/history_bloc.dart';

import '../../features/subscription/data/datasources/subscription_remote_data_source.dart';
import '../../features/subscription/data/datasources/subscription_local_data_source.dart';
import '../../features/subscription/data/datasources/mock_subscription_data_source.dart';
import '../../features/subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/subscription/domain/repositories/subscription_repository.dart';
import '../../features/subscription/domain/usecases/get_subscription_status_usecase.dart';
import '../../features/subscription/domain/usecases/purchase_subscription_usecase.dart';
import '../../features/subscription/presentation/bloc/subscription_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  AppLogger.info('Setting up dependencies...');

  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Core dependencies
  getIt.registerLazySingleton<LocalStorage>(() => LocalStorage(getIt()));

  // Network dependencies
  getIt.registerLazySingleton<Dio>(() => _createDio());
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(getIt<Dio>()));

  // Auth dependencies
  _setupAuthDependencies();

  // Question dependencies
  _setupQuestionDependencies();

  // History dependencies
  _setupHistoryDependencies();

  // Subscription dependencies
  _setupSubscriptionDependencies();

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

  dio.interceptors.add(AuthInterceptor(getIt<LocalStorage>()));

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
    () => AuthLocalDataSourceImpl(getIt<LocalStorage>()),
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
    ),
  );
}

void _setupQuestionDependencies() {
  // Data sources
  getIt.registerLazySingleton<QuestionRemoteDataSource>(
    () => QuestionRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<QuestionLocalDataSource>(
    () => QuestionLocalDataSourceImpl(),
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

  // Bloc
  getIt.registerFactory<QuestionBloc>(
    () => QuestionBloc(
      submitQuestionUseCase: getIt<SubmitQuestionUseCase>(),
    ),
  );
}

void _setupHistoryDependencies() {
  // Data sources
  getIt.registerLazySingleton<HistoryRemoteDataSource>(
    () => HistoryRemoteDataSourceImpl(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<HistoryLocalDataSource>(
    () => HistoryLocalDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      remoteDataSource: getIt<HistoryRemoteDataSource>(),
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

  // Bloc
  getIt.registerFactory<SubscriptionBloc>(
    () => SubscriptionBloc(
      getSubscriptionStatusUseCase: getIt<GetSubscriptionStatusUseCase>(),
      purchaseSubscriptionUseCase: getIt<PurchaseSubscriptionUseCase>(),
    ),
  );
}
