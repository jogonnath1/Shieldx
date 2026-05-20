import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../widgets/common/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isPhoneVerified = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPhoneVerified) {
      _showError('Please verify your phone number first');
      return;
    }

    final isOnline = await ref.read(connectivityProvider.notifier).checkConnection();
    if (!isOnline) {
      _showError('Active internet connection is required to create an account.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(authNotifierProvider.notifier);

      // Prevent registration if email or phone is already registered
      final checks = await notifier.checkContactExists(
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );

      if (checks['email_exists'] == true) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('This email address is already in use.');
        return;
      }

      if (checks['phone_exists'] == true) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showError('This phone number is already registered.');
        return;
      }

      final ok = await notifier.completeRegistration(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Account created successfully!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('AuthException: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
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
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 16),
                Text('Create Account',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(fontWeight: FontWeight.w800)
                ).animate().fadeIn().slideX(begin: -0.2),
                const SizedBox(height: 6),
                Text('Join ShieldX to report crimes safely',
                    style: Theme.of(context).textTheme.bodyMedium
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Full Name',
                        hint: 'John Doe',
                        controller: _nameCtrl,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name is required' : null,
                      ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'Phone Number',
                        hint: '+8801XXXXXXXXX',
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        textInputAction: TextInputAction.next,
                        readOnly: _isPhoneVerified,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Phone number is required';
                          if (!v.startsWith('+')) return 'Must start with country code (e.g., +880)';
                          if (v.length < 10) return 'Enter a valid phone number';
                          return null;
                        },
                        suffix: _isPhoneVerified
                            ? const Padding(
                                padding: EdgeInsets.only(right: 12.0),
                                child: Icon(Icons.check_circle, color: AppColors.success),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: TextButton(
                                  onPressed: () async {
                                    final isOnline = await ref.read(connectivityProvider.notifier).checkConnection();
                                    if (!isOnline) {
                                      _showError('Active internet connection is required for phone verification.');
                                      return;
                                    }
                                    final number = _phoneCtrl.text.trim();
                                    if (number.startsWith('+') && number.length >= 10) {
                                      setState(() => _isLoading = true);
                                      try {
                                        final notifier = ref.read(authNotifierProvider.notifier);

                                        // Prevent phone OTP if phone number is already registered
                                        final checks = await notifier.checkContactExists(
                                          email: '',
                                          phone: number,
                                        );

                                        if (checks['phone_exists'] == true) {
                                          if (!mounted) return;
                                          setState(() => _isLoading = false);
                                          _showError('This phone number is already registered.');
                                          return;
                                        }

                                        await notifier.sendPhoneOtp(number);
                                        if (!mounted) return;
                                        setState(() {
                                          _isOtpSent = true;
                                          _isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('OTP sent to your phone!'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        setState(() => _isLoading = false);
                                        _showError(e.toString().replaceAll('AuthException: ', ''));
                                      }
                                    } else {
                                      _showError('Enter a valid phone number starting with +');
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
                                final isOnline = await ref.read(connectivityProvider.notifier).checkConnection();
                                if (!isOnline) {
                                  _showError('Active internet connection is required for OTP verification.');
                                  return;
                                }
                                if (_otpCtrl.text.trim().isNotEmpty) {
                                  setState(() => _isLoading = true);
                                  try {
                                    final notifier = ref.read(authNotifierProvider.notifier);
                                    await notifier.verifyPhoneOtp(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
                                    if (!mounted) return;
                                    setState(() {
                                      _isPhoneVerified = true;
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Phone verified! You can now set your password.'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() => _isLoading = false);
                                    _showError('Invalid OTP or verification failed.');
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
                            if (v == null || v.isEmpty) return 'Password is required';
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
                      ],
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Create Account',
                        onTap: _isLoading ? null : _register,
                        isLoading: _isLoading,
                        icon: Icons.person_add_rounded,
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
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
