import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/injection_container.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/question/presentation/pages/question_page.dart';
import '../../features/question/presentation/pages/camera_page.dart';
import '../../features/question/presentation/pages/crop_page.dart';
import '../../features/history/presentation/pages/history_page.dart';
import '../../features/history/presentation/pages/history_detail_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/flashcards/presentation/bloc/review_bloc.dart';
import '../../features/flashcards/presentation/bloc/error_book_bloc.dart';
import '../../features/flashcards/presentation/pages/review_session_page.dart';
import '../../features/flashcards/presentation/pages/error_book_page.dart';
import '../../features/documents/domain/entities/document.dart';
import '../../features/documents/presentation/bloc/documents_bloc.dart';
import '../../features/documents/presentation/pages/documents_list_page.dart';
import '../../features/documents/presentation/pages/document_chat_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    // Phase A0: home is the camera-first home page.
    // Switch back to '/onboarding' once the auth/onboarding flow is wired.
    initialLocation: '/home',
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryPage(),
            routes: [
              GoRoute(
                path: 'detail/:id',
                name: 'history-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return HistoryDetailPage(historyId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/subscription',
            name: 'subscription',
            builder: (context, state) => const SubscriptionPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // Question flow routes (fullscreen)
      GoRoute(
        path: '/question',
        name: 'question',
        builder: (context, state) {
          // Crop page hands off { images: [...], hasImages: true } via extra.
          final initialData = state.extra as Map<String, dynamic>?;
          return QuestionPage(initialData: initialData);
        },
      ),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (context, state) => const CameraPage(),
      ),
      GoRoute(
        path: '/crop',
        name: 'crop',
        builder: (context, state) {
          final images = state.extra as List<String>?;
          return CropPage(imagePaths: images ?? []);
        },
      ),

      // Flashcards / 错题本 (fullscreen)
      GoRoute(
        path: '/flashcards/review',
        name: 'flashcard-review',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ReviewBloc>(),
          child: const ReviewSessionPage(),
        ),
      ),
      GoRoute(
        path: '/flashcards/errorbook',
        name: 'errorbook',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ErrorBookBloc>(),
          child: const ErrorBookPage(),
        ),
      ),

      // 我的资料 / document import (fullscreen, Phase C)
      GoRoute(
        path: '/documents',
        name: 'documents',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DocumentsBloc>(),
          child: const DocumentsListPage(),
        ),
      ),
      GoRoute(
        path: '/documents/ask',
        name: 'document-ask',
        builder: (context, state) {
          final doc = state.extra as Document;
          return DocumentChatPage(document: doc);
        },
      ),
    ],
    errorBuilder: (context, state) => ErrorPage(error: state.error.toString()),
  );
}

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_outlined),
            activeIcon: const Icon(Icons.history),
            label: l.navHistory,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.workspace_premium_outlined),
            activeIcon: const Icon(Icons.workspace_premium),
            label: l.navMember,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: l.navProfile,
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/history');
        break;
      case 2:
        context.go('/subscription');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

class ErrorPage extends StatelessWidget {
  final String error;

  const ErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
