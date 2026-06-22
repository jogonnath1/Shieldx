import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/core/theme/app_theme.dart';
import 'package:shieldx/common/core/router/app_router.dart';
import 'package:shieldx/common/providers/connectivity_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/no_internet_screen.dart';

class ShieldXApp extends ConsumerStatefulWidget {
  const ShieldXApp({super.key});
  @override
  ConsumerState<ShieldXApp> createState() => _ShieldXAppState();
}

class _ShieldXAppState extends ConsumerState<ShieldXApp> {
  late final StreamSubscription<AuthState> _authSubscription;
  @override
  void initState() {
    super.initState();
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ref.read(routerProvider).go('/change-password');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
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
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
