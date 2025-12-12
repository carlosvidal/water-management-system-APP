import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:water_readings_app/core/providers/auth_provider.dart';
import 'package:water_readings_app/features/auth/login_screen.dart';
import 'package:water_readings_app/features/onboarding/onboarding_screen.dart';
import 'package:water_readings_app/shared/widgets/loading_screen.dart';
import 'package:water_readings_app/features/condominium/condominium_list_screen.dart';
import 'package:water_readings_app/features/condominium/condominium_detail_screen.dart';
import 'package:water_readings_app/features/dashboard/dashboard_screen.dart';
import 'package:water_readings_app/features/readings/readings_overview_screen.dart';
import 'package:water_readings_app/features/readings/readings_list_screen.dart';
import 'package:water_readings_app/features/readings/camera_reading_screen.dart';
import 'package:water_readings_app/features/users/users_list_screen.dart';
import 'package:water_readings_app/shared/constants/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AquaFlowApp(),
    ),
  );
}

class AquaFlowApp extends ConsumerStatefulWidget {
  const AquaFlowApp({super.key});

  @override
  ConsumerState<AquaFlowApp> createState() => _AquaFlowAppState();
}

class _AquaFlowAppState extends ConsumerState<AquaFlowApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter(ref);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes and refresh router
    ref.listen(authProvider, (previous, next) {
      if (previous?.status != next.status) {
        // Auth state changed
        _router.refresh();
      }
    });

    return MaterialApp.router(
      title: 'AquaFlow',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final authNotifier = ref.read(authProvider.notifier);
        final currentPath = state.fullPath;

        // Router navigation logic

        // If app is loading, show splash
        if (authState.isLoading) {
          // Redirecting to splash (loading)
          return '/splash';
        }

        // If user is authenticated
        if (authState.isAuthenticated) {
          // Redirect to main app if trying to access auth pages
          if (currentPath == '/login' || currentPath == '/onboarding' || currentPath == '/splash') {
            // Authenticated user accessing auth page, redirecting to dashboard
            return '/dashboard';
          }

          // Route guards: Check if user has permission for specific routes
          if (currentPath != null && currentPath.contains('/users')) {
            // Users management requires SUPER_ADMIN or ADMIN role
            if (!authNotifier.isSuperAdmin && !authNotifier.isAdmin) {
              return '/dashboard';
            }
          }

          // Authenticated user, no redirect needed
          return null; // No redirect needed
        }

        // If user is not authenticated
        if (!authState.isAuthenticated) {
          // Redirect splash to login when not authenticated
          if (currentPath == '/splash') {
            // Unauthenticated user on splash, redirecting to login
            return '/login';
          }
          // Allow access to auth pages
          if (currentPath == '/login' || currentPath == '/onboarding') {
            // Unauthenticated user accessing auth page, allowing
            return null;
          }
          // Redirect to login for protected pages
          // Unauthenticated user accessing protected page, redirecting to login
          return '/login';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const LoadingScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/condominiums',
          builder: (context, state) => const CondominiumListScreen(),
        ),
        GoRoute(
          path: '/readings',
          builder: (context, state) => const ReadingsOverviewScreen(),
        ),
        GoRoute(
          path: '/condominium/:id',
          builder: (context, state) {
            final condominiumId = state.pathParameters['id']!;
            return CondominiumDetailScreen(condominiumId: condominiumId);
          },
        ),
        GoRoute(
          path: '/period/:periodId/readings',
          builder: (context, state) {
            final periodId = state.pathParameters['periodId']!;
            return ReadingsListScreen(periodId: periodId);
          },
        ),
        GoRoute(
          path: '/reading/camera/:unitId/:periodId',
          builder: (context, state) {
            final unitId = state.pathParameters['unitId']!;
            final periodId = state.pathParameters['periodId']!;
            return CameraReadingScreen(
              unitId: unitId,
              periodId: periodId,
            );
          },
        ),
        GoRoute(
          path: '/condominium/:id/users',
          builder: (context, state) {
            final condominiumId = state.pathParameters['id']!;
            return UsersListScreen(condominiumId: condominiumId);
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'Unknown error',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Auth state listener to handle redirects
class AuthStateListener extends ConsumerWidget {
  final Widget child;

  const AuthStateListener({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      // Handle auth state changes here if needed
      if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        // User was logged out
        context.go('/login');
      }
    });

    return child;
  }
}