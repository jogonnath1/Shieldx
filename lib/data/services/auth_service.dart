import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'phone': phone},
    );
    return response;
  }

  Future<void> sendPhoneOtp(String phone) async {
    await _client.auth.signInWithOtp(phone: phone);
  }

  Future<AuthResponse> verifyPhoneOtp(String phone, String token) async {
    return await _client.auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
  }

  Future<UserResponse> completeRegistrationWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return await _client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      ),
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.shieldx://login-callback/',
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    try {
      final data = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return null;
      // Inject email from auth using a modifiable map copy
      final modifiableData = Map<String, dynamic>.from(data);
      modifiableData['email'] = user.email;
      return ProfileModel.fromMap(modifiableData);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client
        .from(AppConstants.profilesTable)
        .update(data)
        .eq('id', userId);
  }
}
