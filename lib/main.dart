import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/utils/logger.dart';

import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';
import 'features/question/presentation/bloc/question_bloc.dart';
import 'features/history/presentation/bloc/history_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize dependency injection
  await setupDependencies();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  AppLogger.info('AuraLearn app starting...');
  
  runApp(const AuraLearnApp());
}

class AuraLearnApp extends StatelessWidget {
  const AuraLearnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider<SubscriptionBloc>(
          create: (context) => getIt<SubscriptionBloc>(),
        ),
        BlocProvider<QuestionBloc>(
          create: (context) => getIt<QuestionBloc>(),
        ),
        BlocProvider<HistoryBloc>(
          create: (context) => getIt<HistoryBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.0), // Disable user text scaling
            ),
            child: child!,
          );
        },
      ),
    );
  }
} 