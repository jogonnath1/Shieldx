import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/data/models/profile_model.dart';
import 'package:shieldx/common/core/constants/app_constants.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  Future<Map<String, bool>> checkContactExists({
    required String email,
    required String phone,
  }) async {
    try {
      final response = await _client.rpc(
        'check_contact_exists',
        params: {
          'email_to_check': email,
          'phone_to_check': phone,
        },
      );
      if (response is List && response.isNotEmpty) {
        final data = response.first as Map;
        return {
          'email_exists': data['email_exists'] as bool? ?? false,
          'phone_exists': data['phone_exists'] as bool? ?? false,
        };
      }
      if (response is Map) {
        return {
          'email_exists': response['email_exists'] as bool? ?? false,
          'phone_exists': response['phone_exists'] as bool? ?? false,
        };
      }
      return {'email_exists': false, 'phone_exists': false};
    } catch (e) {
      return {'email_exists': false, 'phone_exists': false};
    }
  }

  Future<bool> checkNidExists(String nid) async {
    if (nid.trim().isEmpty) return false;
    try {
      final response = await _client.rpc(
        'check_nid_exists',
        params: {'nid_to_check': nid.trim()},
      );
      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? nid,
    String? profession,
    String? presentAddress,
    String? permanentAddress,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'phone': phone,
        'nid': nid,
        'profession': profession,
        'present_address': presentAddress,
        'permanent_address': permanentAddress,
      },
    );
    if (response.user != null) {
      try {
        await _client.from(AppConstants.profilesTable).update({
          'name': name,
          'phone': phone,
          'nid': nid,
          'profession': profession,
          'present_address': presentAddress,
          'permanent_address': permanentAddress,
        }).eq('id', response.user!.id);
      } catch (_) {}
    }
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

  Future<void> sendEmailOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyEmailOtp(String email, String token) async {
    return await _client.auth.verifyOTP(
      type: OtpType.email,
      token: token,
      email: email,
    );
  }

  Future<void> sendPasswordResetOtp(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<AuthResponse> verifyPasswordResetOtp(
      String email, String token) async {
    return await _client.auth.verifyOTP(
      type: OtpType.recovery,
      token: token,
      email: email,
    );
  }

  Future<void> saveMockOtp(String phone, String otp) async {
    await _client.from('phone_verifications').upsert({
      'phone': phone,
      'otp': otp,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> verifyMockOtp(String phone, String otp) async {
    try {
      final res = await _client
          .from('phone_verifications')
          .select()
          .eq('phone', phone)
          .eq('otp', otp)
          .maybeSingle();
      return res != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteIncompleteRegistration() async {
    final user = currentUser;
    if (user == null) {
      return true;
    }
    try {
      final result = await _client.rpc(
        'delete_incomplete_registration',
        params: {'user_id_to_delete': user.id},
      );
      final deleted = result as bool? ?? false;
      try {
        await _client.auth.signOut();
      } catch (_) {}
      return deleted;
    } catch (e) {
      try {
        await _client.auth.signOut();
      } catch (_) {}
      return false;
    }
  }

  Future<bool> isEmailBlocked(String email) async {
    try {
      final response = await _client.rpc(
        'is_user_blocked',
        params: {'email_to_check': email.trim()},
      );
      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
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

  Future<UserResponse> updateEmail(String newEmail) async {
    return await _client.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  Future<AuthResponse> verifyEmailChangeOtp(String email, String token) async {
    return await _client.auth.verifyOTP(
      type: OtpType.emailChange,
      email: email,
      token: token,
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

  RealtimeChannel subscribeToProfile(
      String userId, void Function(ProfileModel) onUpdate) {
    return _client
        .channel('public:profiles:id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: AppConstants.profilesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final modifiableData = Map<String, dynamic>.from(newRecord);
            modifiableData['email'] = currentUser?.email;
            onUpdate(ProfileModel.fromMap(modifiableData));
          },
        )
        .subscribe();
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
