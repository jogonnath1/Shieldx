import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/profile_model.dart';
import '../data/services/auth_service.dart';
import '../core/services/preferences_service.dart';
import 'activity_log_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => Supabase.instance.client.auth.currentUser,
    error: (_, __) => null,
  );
});

final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final service = ref.read(authServiceProvider);
  return await service.getCurrentProfile();
});

class AuthNotifier extends StateNotifier<AsyncValue<ProfileModel?>> {
  final AuthService _service;
  final Ref _ref;

  AuthNotifier(this._service, this._ref) : super(const AsyncValue.loading()) {
    _init();
    
    // Listen to Supabase auth state changes to stay in sync automatically
    _service.authStateChanges.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        if (state.valueOrNull == null && !state.isLoading) {
          refresh();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> _init() async {
    try {
      // 1. Try to fetch the active session profile
      var profile = await _service.getCurrentProfile();
      
      // 2. If no active session, check for saved credentials
      if (profile == null) {
        final prefs = _ref.read(preferencesServiceProvider);
        final email = prefs.getSavedEmail();
        final password = prefs.getSavedPassword();
        
        if (email != null && password != null) {
          // Perform background sign in
          await _service.signIn(email: email, password: password);
          profile = await _service.getCurrentProfile();
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
      await _service.signIn(email: email, password: password);
      final profile = await _service.getCurrentProfile();
      state = AsyncValue.data(profile);
      if (profile != null) {
        await _ref.read(activityLogServiceProvider).logEvent(
          actionType: 'login',
          profile: profile,
        );
      }
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      await _ref.read(activityLogServiceProvider).logEvent(
        actionType: 'suspicious_login',
        fallbackEmail: email,
        details: {'reason': e.toString()},
      );
      rethrow; // let the UI show the real error
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
      
      // If Supabase auto-logins after signup, fetch the profile
      if (_service.isLoggedIn) {
        final profile = await _service.getCurrentProfile();
        state = AsyncValue.data(profile);
        if (profile != null) {
          await _ref.read(activityLogServiceProvider).logEvent(
            actionType: 'login',
            profile: profile,
            details: {'info': 'Signed up and logged in'},
          );
        }
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

  /// Deletes the incomplete registration from Supabase auth + profiles.
  /// Safe — the DB function only deletes if phone and nid are both null.
  /// The service layer always calls auth.signOut() so the local JWT is cleared.
  Future<bool> deleteIncompleteRegistration() async {
    try {
      final deleted = await _service.deleteIncompleteRegistration();
      // Always clear local state and credentials regardless of RPC success,
      // because the service already signed out the local session.
      state = const AsyncValue.data(null);
      final prefs = _ref.read(preferencesServiceProvider);
      await prefs.clearCredentials();
      return deleted;
    } catch (e) {
      // Even on exception, clear local state so user isn't stuck
      state = const AsyncValue.data(null);
      return false;
    }
  }



  Future<void> signOut() async {
    final profile = state.valueOrNull;
    if (profile != null) {
      await _ref.read(activityLogServiceProvider).logEvent(
        actionType: 'logout',
        profile: profile,
      );
    }
    await _service.signOut();
    state = const AsyncValue.data(null);
    final prefs = _ref.read(preferencesServiceProvider);
    await prefs.clearLastRoute();
    await prefs.clearCredentials();
  }

  Future<void> refresh() async {
    try {
      final profile = await _service.getCurrentProfile();
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
