import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/data/models/profile_model.dart';
import 'package:shieldx/common/data/services/auth_service.dart';
import 'package:shieldx/common/core/services/preferences_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Exposes the raw Supabase auth state stream for lower-level listeners.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Provides the currently authenticated Supabase [User], or null if signed out.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

/// Fetches the full [ProfileModel] for the currently authenticated user.
/// Use [authNotifierProvider] for reactive, real-time profile updates instead.
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.read(authServiceProvider);
  return await service.getCurrentProfile();
});

/// Manages the authenticated user's [ProfileModel] as reactive state.
///
/// On startup it runs [_init] which:
///   1. Tries to load an existing session from Supabase.
///   2. Falls back to auto-login using credentials saved in SharedPreferences.
///   3. Immediately signs out any blocked user and clears saved credentials.
///   4. Subscribes to real-time profile changes via Supabase Realtime.
class AuthNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthService _service;
  final Ref _ref;
  RealtimeChannel? _profileSubscription;
  AuthNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _init();
    // Listen to Supabase auth events to keep state in sync with session changes.
    _service.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (state.valueOrNull == null && !state.isLoading) {
          refresh();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _cancelProfileSubscription();
        state = const AsyncValue.data(null);
      }
    });
  }

  /// App startup sequence:
  /// Step 1 — try existing session.
  /// Step 2 — if no session, attempt auto-login with saved credentials.
  /// Step 3 — if user is blocked, sign them out immediately.
  /// Step 4 — subscribe to real-time profile updates.
  Future<void> _init() async {
    try {
      var profile = await _service.getCurrentProfile();
      if (profile == null) {
        final prefs = _ref.read(preferencesServiceProvider);
        final email = prefs.getSavedEmail();
        final password = prefs.getSavedPassword();
        if (email != null && password != null) {
          final isBlocked = await _service.isEmailBlocked(email);
          if (!isBlocked) {
            await _service.signIn(email: email, password: password);
            profile = await _service.getCurrentProfile();
          }
        }
      }
      if (profile != null) {
        if (profile.isBlocked) {
          await _service.signOut();
          profile = null;
          final prefs = _ref.read(preferencesServiceProvider);
          await prefs.clearCredentials();
        } else {
          _setupProfileSubscription(profile);
        }
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final isBlocked = await _service.isEmailBlocked(email);
      if (isBlocked) {
        throw Exception('blocked_by_admin');
      }
      await _service.signIn(email: email, password: password);
      final profile = await _service.getCurrentProfile();
      if (profile != null) {
        if (profile.isBlocked) {
          await _service.signOut();
          state = const AsyncValue.data(null);
          final prefs = _ref.read(preferencesServiceProvider);
          await prefs.clearCredentials();
          throw Exception('blocked_by_admin');
        }
        _setupProfileSubscription(profile);
      }
      state = AsyncValue.data(profile);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? nid,
    String? profession,
    String? presentAddress,
    String? permanentAddress,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        nid: nid,
        profession: profession,
        presentAddress: presentAddress,
        permanentAddress: permanentAddress,
      );
      if (_service.isLoggedIn) {
        final profile = await _service.getCurrentProfile();
        state = AsyncValue.data(profile);
      } else {
        state = const AsyncValue.data(null);
      }
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<Map<String, bool>> checkContactExists({
    required String email,
    required String phone,
  }) async {
    return await _service.checkContactExists(email: email, phone: phone);
  }

  Future<bool> checkNidExists(String nid) async {
    return await _service.checkNidExists(nid);
  }

  Future<void> sendPhoneOtp(String phone) async {
    try {
      await _service.sendPhoneOtp(phone);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyPhoneOtp(String phone, String token) async {
    try {
      await _service.verifyPhoneOtp(phone, token);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailOtp(String email) async {
    try {
      await _service.sendEmailOtp(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyEmailOtp(String email, String token) async {
    try {
      await _service.verifyEmailOtp(email, token);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileDetails({
    required String userId,
    required String name,
    required String phone,
    required String nid,
    required String profession,
    required String presentAddress,
    required String permanentAddress,
    String? password,
  }) async {
    try {
      if (password != null && password.isNotEmpty) {
        await _service.updatePassword(password);
      }
      await _service.updateProfile(userId, {
        'name': name,
        'phone': phone,
        'nid': nid,
        'profession': profession,
        'present_address': presentAddress,
        'permanent_address': permanentAddress,
      });
      await refresh();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveMockOtp(String phone, String otp) async {
    try {
      await _service.saveMockOtp(phone, otp);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyMockOtp(String phone, String otp) async {
    try {
      return await _service.verifyMockOtp(phone, otp);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteIncompleteRegistration() async {
    try {
      final deleted = await _service.deleteIncompleteRegistration();
      state = const AsyncValue.data(null);
      final prefs = _ref.read(preferencesServiceProvider);
      await prefs.clearCredentials();
      return deleted;
    } catch (e) {
      state = const AsyncValue.data(null);
      return false;
    }
  }

  Future<void> signOut() async {
    _cancelProfileSubscription();
    await _service.signOut();
    state = const AsyncValue.data(null);
    final prefs = _ref.read(preferencesServiceProvider);
    await prefs.clearLastRoute();
    await prefs.clearCredentials();
  }

  /// Subscribes to real-time Supabase Postgres changes on the user's profile row.
  /// Any server-side update (e.g., admin verifies or blocks the user) is
  /// immediately reflected in the UI without requiring a manual refresh.
  void _setupProfileSubscription(ProfileModel profile) {
    _cancelProfileSubscription();
    _profileSubscription =
        _service.subscribeToProfile(profile.id, (updatedProfile) {
      if (mounted) {
        state = AsyncValue.data(updatedProfile);
      }
    });
  }

  void _cancelProfileSubscription() {
    if (_profileSubscription != null) {
      _service.removeChannel(_profileSubscription!);
      _profileSubscription = null;
    }
  }

  @override
  void dispose() {
    _cancelProfileSubscription();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final profile = await _service.getCurrentProfile();
      if (profile != null && profile.isBlocked) {
        _cancelProfileSubscription();
        await _service.signOut();
        state = const AsyncValue.data(null);
        final prefs = _ref.read(preferencesServiceProvider);
        await prefs.clearCredentials();
        return;
      }
      if (profile != null) {
        _setupProfileSubscription(profile);
      }
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<ProfileModel?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider), ref);
});
