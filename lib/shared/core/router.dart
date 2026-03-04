import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../ui/scaffold_with_nav.dart';

// Feature screens
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/inventory/presentation/inventory_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/graph/presentation/graph_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/admin/presentation/pitch_dashboard.dart';

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    // ── Auth & Splash (no nav bar) ──
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => const RegisterScreen(),
    ),

    // ── Main app (with nav bar) ──
    ShellRoute(
      builder: (_, __, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const InventoryScreen(),
          ),
        ),
        GoRoute(
          path: '/scan',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ScanScreen(),
          ),
        ),
        GoRoute(
          path: '/graph',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const GraphScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProfileScreen(),
          ),
        ),
      ],
    ),

    // ── Push routes (no nav bar shell) ──
    GoRoute(
      path: '/about',
      builder: (_, __) => const AboutScreen(),
    ),
    GoRoute(
      path: '/pitch',
      builder: (_, __) => const PitchDashboard(),
    ),
  ],
);

final routerProvider = Provider<GoRouter>((ref) => _router);
