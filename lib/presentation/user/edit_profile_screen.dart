import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _nidCtrl;
  late final TextEditingController _professionCtrl;
  late final TextEditingController _presentAddressCtrl;
  late final TextEditingController _permanentAddressCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(authNotifierProvider).valueOrNull;
    _nameCtrl = TextEditingController(text: p?.name);
    _phoneCtrl = TextEditingController(text: p?.phone);
    _nidCtrl = TextEditingController(text: p?.nid);
    _professionCtrl = TextEditingController(text: p?.profession);
    _presentAddressCtrl = TextEditingController(text: p?.presentAddress);
    _permanentAddressCtrl = TextEditingController(text: p?.permanentAddress);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nidCtrl.dispose();
    _professionCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final profile = ref.read(authNotifierProvider).valueOrNull!;
      final service = AuthService();
      await service.updateProfile(profile.id, {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'nid': _nidCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'present_address': _presentAddressCtrl.text.trim(),
        'permanent_address': _permanentAddressCtrl.text.trim(),
      });
      await ref.read(authNotifierProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(v.trim())) {
                      return 'Only alphabet letters and spaces are allowed';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final val = v.trim();
                    if (!val.startsWith('+8801')) return 'Must start with Bangladesh country code (+8801)';
                    final digits = val.substring(1);
                    if (digits.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(digits)) {
                      return 'Only numeric numbers are allowed after +';
                    }
                    if (val.length != 14) return 'Phone number must be exactly 14 characters (e.g., +8801610635446)';
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'NID Number',
                  controller: _nidCtrl,
                  prefixIcon: Icons.credit_card_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                      return 'Only numeric numbers are allowed';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Profession',
                  controller: _professionCtrl,
                  prefixIcon: Icons.work_outline,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Present Address',
                  controller: _presentAddressCtrl,
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Permanent Address',
                  controller: _permanentAddressCtrl,
                  prefixIcon: Icons.home_outlined,
                  maxLines: 2,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Save Changes',
                  onTap: _isLoading ? null : _save,
                  isLoading: _isLoading,
                  icon: Icons.save_rounded,
                ).animate().fadeIn(delay: 350.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
