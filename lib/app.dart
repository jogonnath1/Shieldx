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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionId = const Uuid().v4();
    _sessionStartTime = DateTime.now();

    // Log the initial app open event
    _logAppOpen();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ref.read(routerProvider).go('/change-password');
      }
    });
  }

  @override
  void dispose() {
    _logAppClose();
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
      _logAppOpen();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _logAppClose();
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
    final durationSeconds = DateTime.now().difference(_sessionStartTime).inSeconds;
    final profile = ref.read(authNotifierProvider).valueOrNull;
    ref.read(activityLogServiceProvider).logEvent(
          actionType: 'app_close',
          profile: profile,
          sessionId: _sessionId,
          durationSeconds: durationSeconds,
        );
  }

  @override
  Widget build(BuildContext context) {
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
