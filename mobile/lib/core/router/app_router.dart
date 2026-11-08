import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/profile/presentation/profile_wizard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/opportunities/presentation/discover_screen.dart';
import '../../features/opportunities/presentation/explorer_screen.dart';
import '../../features/opportunities/presentation/opportunity_details_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/applications/presentation/applications_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/eligibility/presentation/eligibility_report_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/navigation/presentation/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/profile/wizard',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileWizardScreen(),
      ),
      GoRoute(
        path: '/opportunities/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OpportunityDetailsScreen(opportunityId: id);
        },
      ),
      GoRoute(
        path: '/eligibility/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EligibilityReportScreen(opportunityId: id);
        },
      ),
      GoRoute(
        path: '/alerts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Bottom Navigation Shell with 5 core tabs:
      // 1. Home (/discover)
      // 2. Explore (/explorer)
      // 3. Saved (/saved)
      // 4. Applications (/applications)
      // 5. Profile (/profile)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/explorer',
            builder: (context, state) => const ExplorerScreen(),
          ),
          GoRoute(
            path: '/saved',
            builder: (context, state) => const SavedScreen(),
          ),
          GoRoute(
            path: '/applications',
            builder: (context, state) => const ApplicationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
