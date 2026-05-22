import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/connectivity_provider.dart';
import 'providers/activity_log_provider.dart';
import 'providers/auth_provider.dart';
import 'data/models/profile_model.dart';
import 'presentation/widgets/common/no_internet_screen.dart';

class ShieldXApp extends ConsumerStatefulWidget {
  const ShieldXApp({super.key});

  @override
  ConsumerState<ShieldXApp> createState() => _ShieldXAppState();
}

class _ShieldXAppState extends ConsumerState<ShieldXApp> with WidgetsBindingObserver {
  late final StreamSubscription<AuthState> _authSubscription;
  late String _sessionId;
  late DateTime _sessionStartTime;
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionId = const Uuid().v4();
    _sessionStartTime = DateTime.now();
    _lastHeartbeatTime = DateTime.now();

    // Log the initial app open event
    _logAppOpen();

    // Start a periodic background timer to track active usage every 60 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _sendHeartbeat();
    });

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ref.read(routerProvider).go('/change-password');
      }
    });
  }

  @override
  void dispose() {
    _logAppClose();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Starting a new session
      _sessionId = const Uuid().v4();
      _sessionStartTime = DateTime.now();
      _lastHeartbeatTime = DateTime.now();
      _logAppOpen();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _logAppClose();
    }
  }

  void _sendHeartbeat() {
    final profile = ref.read(authNotifierProvider).valueOrNull;
    if (profile == null) {
      // User is not logged in, reset tracking time so we start fresh upon login
      _lastHeartbeatTime = null;
      return;
    }

    final now = DateTime.now();
    if (_lastHeartbeatTime == null) {
      _lastHeartbeatTime = now;
      return;
    }

    final durationSeconds = now.difference(_lastHeartbeatTime!).inSeconds;
    if (durationSeconds <= 0) return;

    _lastHeartbeatTime = now;

    ref.read(activityLogServiceProvider).logEvent(
          actionType: 'app_heartbeat',
          profile: profile,
          sessionId: _sessionId,
          durationSeconds: durationSeconds,
        );
  }

  void _handleProfileTransition(ProfileModel? previous, ProfileModel? next) {
    if (previous == null && next != null) {
      // User authenticated! Log app_open for this user
      ref.read(activityLogServiceProvider).logEvent(
            actionType: 'app_open',
            profile: next,
            sessionId: _sessionId,
          );
      _lastHeartbeatTime = DateTime.now();
    } else if (previous != null && next == null) {
      // User logged out
      _lastHeartbeatTime = null;
    }
  }

  void _logAppOpen() {
    final profile = ref.read(authNotifierProvider).valueOrNull;
    ref.read(activityLogServiceProvider).logEvent(
          actionType: 'app_open',
          profile: profile,
          sessionId: _sessionId,
        );
  }

  void _logAppClose() {
    final profile = ref.read(authNotifierProvider).valueOrNull;
    final int durationSeconds;
    if (profile != null && _lastHeartbeatTime != null) {
      durationSeconds = DateTime.now().difference(_lastHeartbeatTime!).inSeconds;
    } else {
      durationSeconds = DateTime.now().difference(_sessionStartTime).inSeconds;
    }

    ref.read(activityLogServiceProvider).logEvent(
          actionType: 'app_close',
          profile: profile,
          sessionId: _sessionId,
          durationSeconds: durationSeconds > 0 ? durationSeconds : 0,
        );
    _lastHeartbeatTime = null;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth notifier transitions to correctly log app_open upon sign-in / recovery
    ref.listen<AsyncValue<ProfileModel?>>(authNotifierProvider, (previous, next) {
      final prevProfile = previous?.valueOrNull;
      final nextProfile = next.valueOrNull;
      if (prevProfile != nextProfile) {
        _handleProfileTransition(prevProfile, nextProfile);
      }
    });

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ShieldX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, _) {
            final isOnline = ref.watch(connectivityProvider);
            if (!isOnline) {
              return const NoInternetScreen();
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
