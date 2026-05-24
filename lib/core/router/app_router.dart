import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../services/preferences_service.dart';
import '../../presentation/auth/splash_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../../presentation/user/home_screen.dart';
import '../../presentation/user/submit_complaint_screen.dart';
import '../../presentation/user/my_complaints_screen.dart';
import '../../presentation/user/complaint_detail_screen.dart';
import '../../presentation/user/profile_screen.dart';
import '../../presentation/user/edit_profile_screen.dart';
import '../../presentation/user/change_password_screen.dart';
import '../../presentation/user/change_email_screen.dart';
import '../../presentation/user/security_logs_screen.dart';
import '../../presentation/user/police_stations_screen.dart';
import '../../presentation/user/chat_screen.dart';
import '../../presentation/user/edit_complaint_screen.dart';
import '../../presentation/user/recycle_bin_screen.dart';
import '../../presentation/admin/admin_shell.dart';
import '../../presentation/admin/admin_dashboard_screen.dart';
import '../../presentation/admin/admin_complaints_screen.dart';
import '../../presentation/admin/admin_complaint_detail_screen.dart';
import '../../presentation/admin/admin_users_screen.dart';
import '../../presentation/admin/admin_officers_screen.dart';
import '../../presentation/admin/admin_profile_screen.dart';
import '../../presentation/admin/admin_stations_screen.dart';
import '../../presentation/admin/admin_recycle_bin_screen.dart';
import '../../presentation/common/notifications_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/navigation_trigger_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _adminShellKey = GlobalKey<NavigatorState>();

/// A ChangeNotifier that listens to auth state changes and notifies GoRouter
/// to re-run its redirect function. This avoids recreating the entire GoRouter
/// instance (which causes infinite loops) while still reacting to auth changes.
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<dynamic>>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);
  final prefsService = ref.read(preferencesServiceProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isLoading = authState.isLoading;
      final profile = authState.valueOrNull;
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      final location = state.matchedLocation;

      final authRoutes = ['/login', '/register', '/forgot-password', '/splash'];
      final isOnAuthRoute = authRoutes.contains(location);

      // Still loading — go to splash
      if (isLoading) {
        return isOnAuthRoute ? null : '/splash';
      }

      // Not logged in — redirect to login if not already on an auth route
      if (!isLoggedIn) {
        return isOnAuthRoute ? null : '/login';
      }

      // Logged in but profile is incomplete — lock to /register
      final phone = profile?.phone;
      final nid = profile?.nid;
      final isProfileIncomplete = phone == null || phone.trim().isEmpty ||
          nid == null || nid.trim().isEmpty;

      if (isProfileIncomplete) {
        // Only redirect if NOT already on /register
        return location == '/register' ? null : '/register';
      }

      // Profile complete — if on an auth route, redirect to home/admin
      if (isOnAuthRoute) {
        final isAdmin = profile?.role == 'admin';

        // Try to restore last visited route (skip auth routes to avoid loops)
        final lastRoute = prefsService.getLastRoute();
        if (lastRoute != null &&
            lastRoute.isNotEmpty &&
            !authRoutes.contains(lastRoute)) {
          final isRouteAdmin = lastRoute.startsWith('/admin');
          if (isAdmin == isRouteAdmin) {
            return lastRoute;
          }
        }

        return isAdmin ? '/admin/dashboard' : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // User routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/police-stations',
        builder: (context, state) => const PoliceStationsScreen(),
      ),
      GoRoute(
        path: '/submit-complaint',
        builder: (context, state) {
          final isAnon = state.uri.queryParameters['anonymous'] == 'true';
          final station = state.uri.queryParameters['station'];
          return SubmitComplaintScreen(
            initialAnonymous: isAnon,
            initialPoliceStation: station,
          );
        },
      ),
      GoRoute(
        path: '/my-complaints',
        builder: (context, state) => const MyComplaintsScreen(),
      ),
      GoRoute(
        path: '/complaint/:id',
        builder: (context, state) => ComplaintDetailScreen(
          complaintId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/complaint/:id/edit',
        builder: (context, state) => EditComplaintScreen(
          complaintId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/security-logs',
        builder: (context, state) => const SecurityLogsScreen(),
      ),
      GoRoute(
        path: '/recycle-bin',
        builder: (context, state) => const RecycleBinScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/change-email',
        builder: (context, state) => const ChangeEmailScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat/:complaintId',
        builder: (context, state) => ChatScreen(
          complaintId: state.pathParameters['complaintId']!,
        ),
      ),
      // Admin shell (with bottom nav bar)
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/complaints',
            builder: (context, state) => const AdminComplaintsScreen(),
          ),
          GoRoute(
            path: '/admin/stations',
            builder: (context, state) => const AdminStationsScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const AdminUsersScreen(),
          ),
          GoRoute(
            path: '/admin/officers',
            builder: (context, state) => const AdminOfficersScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (context, state) => const AdminProfileScreen(),
          ),
        ],
      ),
      // Admin detail routes — outside shell so they're fullscreen
      GoRoute(
        path: '/admin/complaints/:id',
        builder: (context, state) => AdminComplaintDetailScreen(
          complaintId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/recycle-bin',
        builder: (context, state) => const AdminRecycleBinScreen(),
      ),
    ],
  );

  router.routerDelegate.addListener(() {
    final currentConfig = router.routerDelegate.currentConfiguration;
    final location = currentConfig.last.matchedLocation;
    prefsService.saveLastRoute(location);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationTriggerProvider.notifier).trigger(location);
    });
  });

  return router;
});
