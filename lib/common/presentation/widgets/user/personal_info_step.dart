import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';

class PersonalInfoStep extends StatelessWidget {
  final TextEditingController firstNameCtrl,
      lastNameCtrl,
      phoneCtrl,
      nidCtrl,
      professionCtrl,
      presentAddressCtrl,
      permanentAddressCtrl;
  final bool isAnonymous;
  final ValueChanged<bool> onAnonymousChanged;
  const PersonalInfoStep({
    super.key,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.phoneCtrl,
    required this.nidCtrl,
    required this.professionCtrl,
    required this.presentAddressCtrl,
    required this.permanentAddressCtrl,
    required this.isAnonymous,
    required this.onAnonymousChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAnonymous
                  ? [
                      const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                      const Color(0xFF1565C0).withValues(alpha: 0.15)
                    ]
                  : [AppColors.surfaceLight, AppColors.surfaceLight],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAnonymous
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAnonymous
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.cardBorder.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAnonymous ? Icons.person_off_rounded : Icons.person_rounded,
                  color: isAnonymous ? AppColors.primary : AppColors.textHint,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Anonymously',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isAnonymous
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Your personal details will be hidden from admins',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isAnonymous,
                onChanged: onAnonymousChanged,
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),
        if (!isAnonymous) ...[
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'First Name',
                  controller: firstNameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(v.trim())) {
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
                  controller: lastNameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(v.trim())) {
                      return 'Only alphabet letters are allowed';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Phone Number',
            controller: phoneCtrl,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Phone number is required';
              }
              final val = v.trim();
              if (!val.startsWith('+8801')) {
                return 'Must start with Bangladesh country code (+8801)';
              }
              final digits = val.substring(1);
              if (digits.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(digits)) {
                return 'Only numeric numbers are allowed after +';
              }
              if (val.length != 14) {
                return 'Phone number must be exactly 14 characters (e.g., +8801610635446)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'NID Number',
            controller: nidCtrl,
            prefixIcon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'NID number is required';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) {
                return 'Only numeric numbers are allowed';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Profession',
            controller: professionCtrl,
            prefixIcon: Icons.work_outline,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Profession is required' : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Present Address',
            controller: presentAddressCtrl,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Present Address is required'
                : null,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Permanent Address',
            controller: permanentAddressCtrl,
            prefixIcon: Icons.home_outlined,
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Permanent Address is required'
                : null,
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your identity is protected. Only the crime details will be visible to admins.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
