import 'package:flutter/material.dart';
import 'package:shieldx/common/core/utils/app_snackbar.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/services/preferences_service.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/providers/connectivity_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _nidFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  String? _emailDbError;
  String? _nidDbError;
  String? _phoneDbError;
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isPhoneVerified = false;
  bool _isEmailVerified = false;
  // ignore: unused_field — stored for debug logging during phone OTP demo flow
  String? _mockOtpCode;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.email != null) {
        setState(() {
          _emailCtrl.text = user.email!;
          _isEmailVerified = true;
        });
      }
    });
    _emailCtrl.addListener(() {
      if (_emailDbError != null) {
        setState(() => _emailDbError = null);
        _formKey.currentState?.validate();
      }
    });
    _nidCtrl.addListener(() {
      if (_nidDbError != null) {
        setState(() => _nidDbError = null);
        _formKey.currentState?.validate();
      }
    });
    _phoneCtrl.addListener(() {
      if (_phoneDbError != null) {
        setState(() => _phoneDbError = null);
        _formKey.currentState?.validate();
      }
    });
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _checkEmailUniqueness();
      }
    });
    _nidFocusNode.addListener(() {
      if (!_nidFocusNode.hasFocus) {
        _checkNidUniqueness();
      }
    });
    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _checkPhoneUniqueness();
      }
    });
  }

  Future<void> _checkEmailUniqueness() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) return;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null &&
        currentUser.email?.toLowerCase() == email.toLowerCase()) {
      if (mounted && !_isEmailVerified) {
        setState(() => _isEmailVerified = true);
      }
      return;
    }
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final checks = await notifier.checkContactExists(email: email, phone: '');
      if (checks['email_exists'] == true) {
        setState(() {
          _emailDbError = 'This email address is already in use';
        });
        _formKey.currentState?.validate();
      }
    } catch (_) {}
  }

  Future<void> _checkNidUniqueness() async {
    final nid = _nidCtrl.text.trim();
    if (nid.isEmpty) return;
    if (!RegExp(r'^[0-9]+$').hasMatch(nid)) return;
    if (nid.length < 10) return;
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final exists = await notifier.checkNidExists(nid);
      if (exists) {
        setState(() {
          _nidDbError = 'This NID/Birth Certificate is already registered';
        });
        _formKey.currentState?.validate();
      }
    } catch (_) {}
  }

  Future<void> _checkPhoneUniqueness() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    if (!phone.startsWith('+')) return;
    final digits = phone.substring(1);
    if (digits.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(digits)) return;
    if (phone.length < 10) return;
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final checks = await notifier.checkContactExists(email: '', phone: phone);
      if (checks['phone_exists'] == true) {
        setState(() {
          _phoneDbError = 'This phone number is already registered';
        });
        _formKey.currentState?.validate();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _nidCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _professionCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _emailFocusNode.dispose();
    _nidFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEmailVerified) {
      _showError('Please verify your email address first');
      return;
    }
    if (!_isPhoneVerified) {
      _showError('Please verify your phone number first');
      return;
    }
    final isOnline =
        await ref.read(connectivityProvider.notifier).checkConnection();
    if (!isOnline) {
      _showError(
          'Active internet connection is required to create an account.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final nidExists = await notifier.checkNidExists(_nidCtrl.text.trim());
      if (nidExists) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('This NID/Birth Certificate is already registered.');
        return;
      }
      final checks = await notifier.checkContactExists(
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (checks['phone_exists'] == true) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('This phone number is already registered.');
        return;
      }
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await notifier.updateProfileDetails(
          userId: currentUser.id,
          name: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
              .trim(),
          phone: _phoneCtrl.text.trim(),
          nid: _nidCtrl.text.trim(),
          profession: _professionCtrl.text.trim(),
          presentAddress: _presentAddressCtrl.text.trim(),
          permanentAddress: _permanentAddressCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        await notifier.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          name: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'
              .trim(),
          phone: _phoneCtrl.text.trim(),
          nid: _nidCtrl.text.trim(),
          profession: _professionCtrl.text.trim(),
          presentAddress: _presentAddressCtrl.text.trim(),
          permanentAddress: _permanentAddressCtrl.text.trim(),
        );
      }
      if (!context.mounted) return;
      final prefs = ref.read(preferencesServiceProvider);
      await prefs.saveCredentials(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Account created successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      // ignore: use_build_context_synchronously
      context.go('/home');
    } catch (e) {
      _showError(e.toString().replaceAll('AuthException: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!context.mounted) return;
    AppSnackbar.error(context, msg);
  }

  void _showEmailDemoBypassDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[950],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.warning,
                  size: 36,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 18),
              Text(
                'Supabase Email OTP Blocked',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We detected that your local network or Supabase SMTP settings are preventing the email verification OTP from being dispatched.\n\nUse the demo verification code below to complete email validation:',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '123456',
                  style: GoogleFonts.spaceMono(
                    color: AppColors.warning,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isEmailVerified = true;
                    });
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('🎉 [Demo Mode] Email verified successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Text(
                    'Auto-Verify & Continue',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address first.');
      return;
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null &&
        currentUser.email?.toLowerCase() == email.toLowerCase()) {
      setState(() {
        _isEmailVerified = true;
        _emailCtrl.text = email;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Email already verified for this session!'),
          backgroundColor: AppColors.success,
        ),
      );
      return;
    }
    final isOnline =
        await ref.read(connectivityProvider.notifier).checkConnection();
    if (!isOnline) {
      _showError(
          'Active internet connection is required for email verification.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);
      final checks = await notifier.checkContactExists(
        email: email,
        phone: '',
      );
      if (checks['email_exists'] == true) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('This email address is already registered.');
        return;
      }
      await notifier.sendEmailOtp(email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to your email!'),
          backgroundColor: AppColors.success,
        ),
      );
      if (!context.mounted) return;
      final TextEditingController emailOtpCtrl = TextEditingController();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[950],
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primaryLight,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Email OTP Verification',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the OTP code sent to\n$email',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'OTP Code',
                  hint: '******',
                  controller: emailOtpCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey[800]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final code = emailOtpCtrl.text.trim();
                          if (code.length != 6 && code.length != 8) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('OTP must be 6 or 8 digits.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          if (!mounted) return;
                          setState(() => _isLoading = true);
                          try {
                            await notifier.verifyEmailOtp(email, code);
                            if (mounted) {
                              setState(() {
                                _isEmailVerified = true;
                                _isLoading = false;
                              });
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('🎉 Email verified successfully!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (err) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    err
                                        .toString()
                                        .replaceAll('AuthException: ', ''),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      final errorStr = e.toString();
      if (errorStr.contains('Failed to fetch') ||
          errorStr.contains('AuthRetryableFetchException')) {
        _showEmailDemoBypassDialog(email);
      } else {
        _showError(errorStr.replaceAll('AuthException: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1A1F2E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Cancel Registration?',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Going back will sign you out and cancel your email verification. You will need to verify again next time.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Stay',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Cancel Registration'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        setState(() => _isLoading = true);
                        final notifier =
                            ref.read(authNotifierProvider.notifier);
                        final deleted =
                            await notifier.deleteIncompleteRegistration();
                        if (!deleted) {
                          await notifier.signOut();
                        }
                        if (context.mounted) {
                          setState(() => _isLoading = false);
                          context.go('/login');
                        }
                      }
                    } else {
                      context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text('Create Account',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800))
                    .animate()
                    .fadeIn()
                    .slideX(begin: -0.2),
                const SizedBox(height: 6),
                Text('Join ShieldX to report crimes safely',
                        style: Theme.of(context).textTheme.bodyMedium)
                    .animate()
                    .fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'First Name',
                              hint: 'Jogonnath',
                              controller: _firstNameCtrl,
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'First name is required';
                                }
                                if (!RegExp(r'^[a-zA-Z\s\-]+$')
                                    .hasMatch(v.trim())) {
                                  return 'Only alphabet letters are allowed';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Last Name',
                              hint: 'Das Talukder',
                              controller: _lastNameCtrl,
                              prefixIcon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Last name is required';
                                }
                                if (!RegExp(r'^[a-zA-Z\s\-]+$')
                                    .hasMatch(v.trim())) {
                                  return 'Only alphabet letters are allowed';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _emailCtrl,
                        focusNode: _emailFocusNode,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isEmailVerified,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegExp =
                              RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(v.trim())) {
                            return 'Enter a valid email address (e.g., name@domain.com)';
                          }
                          if (_emailDbError != null) return _emailDbError;
                          return null;
                        },
                        suffix: _isEmailVerified
                            ? const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: Icon(Icons.check_circle,
                                    color: AppColors.success),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: TextButton(
                                  onPressed: _verifyEmail,
                                  child: Text(
                                    'Verify',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'NID Card or Birth Certificate',
                        hint: 'e.g. 19951234567890123',
                        controller: _nidCtrl,
                        focusNode: _nidFocusNode,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.badge_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'NID or Birth Certificate is required';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                            return 'Only numeric numbers are allowed';
                          }
                          if (v.trim().length < 10) {
                            return 'Must be at least 10 digits';
                          }
                          if (_nidDbError != null) return _nidDbError;
                          return null;
                        },
                      ).animate().fadeIn(delay: 225.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Profession',
                        hint: 'e.g. Engineer, Student, Businessman',
                        controller: _professionCtrl,
                        prefixIcon: Icons.work_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Profession is required'
                            : null,
                      ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Present Address',
                        hint: 'Your current resident address',
                        controller: _presentAddressCtrl,
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 2,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Present Address is required'
                            : null,
                      ).animate().fadeIn(delay: 235.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Permanent Address',
                        hint: 'Your permanent home address',
                        controller: _permanentAddressCtrl,
                        prefixIcon: Icons.home_outlined,
                        maxLines: 2,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Permanent Address is required'
                            : null,
                      ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Phone Number',
                        hint: '+8801XXXXXXXXX',
                        controller: _phoneCtrl,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isPhoneVerified,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (!v.startsWith('+')) {
                            return 'Must start with country code (e.g., +880)';
                          }
                          final digits = v.substring(1);
                          if (digits.isEmpty ||
                              !RegExp(r'^[0-9]+$').hasMatch(digits)) {
                            return 'Only numeric numbers are allowed after +';
                          }
                          if (v.length < 10) {
                            return 'Enter a valid phone number';
                          }
                          if (_phoneDbError != null) return _phoneDbError;
                          return null;
                        },
                        suffix: _isPhoneVerified
                            ? const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: Icon(Icons.check_circle,
                                    color: AppColors.success),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: TextButton(
                                  onPressed: () async {
                                    final nidVal = _nidCtrl.text.trim();
                                    if (nidVal.isEmpty) {
                                      _showError(
                                          'Please enter your NID / Birth Certificate number first.');
                                      return;
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(nidVal)) {
                                      _showError(
                                          'Only numeric numbers are allowed in NID Card or Birth Certificate.');
                                      return;
                                    }
                                    if (nidVal.length < 10) {
                                      _showError(
                                          'NID Card or Birth Certificate must be at least 10 digits.');
                                      return;
                                    }
                                    final isOnline = await ref
                                        .read(connectivityProvider.notifier)
                                        .checkConnection();
                                    if (!isOnline) {
                                      _showError(
                                          'Active internet connection is required for phone verification.');
                                      return;
                                    }
                                    final number = _phoneCtrl.text.trim();
                                    if (number.startsWith('+') &&
                                        number.length >= 10) {
                                      setState(() => _isLoading = true);
                                      try {
                                        final notifier = ref.read(
                                            authNotifierProvider.notifier);
                                        final nidExists = await notifier
                                            .checkNidExists(nidVal);
                                        if (nidExists) {
                                          if (!mounted) return;
                                          setState(() => _isLoading = false);
                                          _showError(
                                              'This NID/Birth Certificate is already registered.');
                                          return;
                                        }
                                        final checks =
                                            await notifier.checkContactExists(
                                          email: '',
                                          phone: number,
                                        );
                                        if (checks['phone_exists'] == true) {
                                          if (!mounted) return;
                                          setState(() => _isLoading = false);
                                          _showError(
                                              'This phone number is already registered.');
                                          return;
                                        }
                                        const mockOtp = "1111";
                                        _mockOtpCode = mockOtp;
                                        await notifier.saveMockOtp(
                                            number, mockOtp);
                                        if (!context.mounted) return;
                                        setState(() {
                                          _isOtpSent = true;
                                          _isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Verification code generated & saved to database!'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                        if (!context.mounted) return;
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[950],
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                    color: AppColors.primary
                                                        .withValues(
                                                            alpha: 0.3)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(
                                                            alpha: 0.15),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary
                                                          .withValues(
                                                              alpha: 0.1),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .phonelink_ring_rounded,
                                                      color: AppColors.primary,
                                                      size: 40,
                                                    ),
                                                  ).animate().scale(
                                                      duration: 400.ms,
                                                      curve:
                                                          Curves.easeOutBack),
                                                  const SizedBox(height: 18),
                                                  Text(
                                                    'ShieldX Demo Verification',
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Use the code below to complete your phone verification in this demo:',
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.inter(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 24,
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black26,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                          color: Colors.white
                                                              .withValues(
                                                                  alpha: 0.08)),
                                                    ),
                                                    child: Text(
                                                      mockOtp,
                                                      style:
                                                          GoogleFonts.spaceMono(
                                                        color:
                                                            AppColors.primary,
                                                        fontSize: 32,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 6,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppColors.primary,
                                                        foregroundColor:
                                                            Colors.white,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 14),
                                                      ),
                                                      onPressed: () {
                                                        _otpCtrl.text = mockOtp;
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text(
                                                        'Auto-Fill & Continue',
                                                        style:
                                                            GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        setState(() => _isLoading = false);
                                        _showError(e
                                            .toString()
                                            .replaceAll('AuthException: ', ''));
                                      }
                                    } else {
                                      _showError(
                                          'Enter a valid phone number starting with +');
                                    }
                                  },
                                  child: const Text('Verify'),
                                ),
                              ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                      if (_isOtpSent && !_isPhoneVerified) ...[
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Enter OTP',
                          hint: '123456',
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.message_outlined,
                          textInputAction: TextInputAction.next,
                          suffix: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: TextButton(
                              onPressed: () async {
                                final isOnline = await ref
                                    .read(connectivityProvider.notifier)
                                    .checkConnection();
                                if (!isOnline) {
                                  _showError(
                                      'Active internet connection is required for OTP verification.');
                                  return;
                                }
                                final enteredOtp = _otpCtrl.text.trim();
                                if (enteredOtp.isNotEmpty) {
                                  setState(() => _isLoading = true);
                                  try {
                                    final notifier =
                                        ref.read(authNotifierProvider.notifier);
                                    final isValid =
                                        await notifier.verifyMockOtp(
                                            _phoneCtrl.text.trim(), enteredOtp);
                                    if (!mounted) return;
                                    if (isValid) {
                                      if (!context.mounted) return;
                                      setState(() {
                                        _isPhoneVerified = true;
                                        _isLoading = false;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Phone verified successfully from database!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      setState(() => _isLoading = false);
                                      _showError(
                                          'Invalid OTP code. Please try again.');
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _isLoading = false);
                                    _showError('Verification error: $e');
                                  }
                                } else {
                                  _showError('Please enter the OTP');
                                }
                              },
                              child: const Text('Confirm'),
                            ),
                          ),
                        ).animate().fadeIn().slideY(begin: 0.2),
                      ],
                      if (_isPhoneVerified) ...[
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordCtrl,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: 14),
                        CustomTextField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          controller: _confirmCtrl,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _register(),
                          validator: (v) {
                            if (v != _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                        const SizedBox(height: 28),
                        GradientButton(
                          label: 'Create Account',
                          onTap: _isLoading ? null : _register,
                          isLoading: _isLoading,
                          icon: Icons.person_add_rounded,
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 14)),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text('Sign In',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
