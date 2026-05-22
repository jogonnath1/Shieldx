import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../data/models/complaint_model.dart';
import '../../data/services/complaint_service.dart';
import '../widgets/common/widgets.dart';

class EditComplaintScreen extends ConsumerStatefulWidget {
  final String complaintId;
  const EditComplaintScreen({super.key, required this.complaintId});

  @override
  ConsumerState<EditComplaintScreen> createState() => _EditComplaintScreenState();
}

class _EditComplaintScreenState extends ConsumerState<EditComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();

  String? _selectedCategory;
  DateTime? _incidentDate;
  bool _isLoading = true;
  bool _isSaving = false;
  ComplaintModel? _complaint;

  @override
  void initState() {
    super.initState();
    _loadComplaint();
  }

  Future<void> _loadComplaint() async {
    final service = ComplaintService();
    final c = await service.getComplaint(widget.complaintId);
    if (!mounted) return;
    if (c == null || c.status != 'submitted') {
      // Not editable — go back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This report can no longer be edited.')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/my-complaints');
        }
      }
      return;
    }
    _complaint = c;
    _descriptionCtrl.text = c.description ?? '';
    _locationCtrl.text = c.locationAddress ?? '';
    _firstNameCtrl.text = c.firstName ?? '';
    _lastNameCtrl.text = c.lastName ?? '';
    _phoneCtrl.text = c.phone ?? '';
    _nidCtrl.text = c.nid ?? '';
    _professionCtrl.text = c.profession ?? '';
    _presentAddressCtrl.text = c.presentAddress ?? '';
    _permanentAddressCtrl.text = c.permanentAddress ?? '';
    _selectedCategory = c.crimeCategory;
    _incidentDate = c.incidentDatetime?.toBangladeshTime();
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ComplaintService().updateComplaint(widget.complaintId, {
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'nid': _nidCtrl.text.trim(),
        'profession': _professionCtrl.text.trim(),
        'present_address': _presentAddressCtrl.text.trim(),
        'permanent_address': _permanentAddressCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'location_address': _locationCtrl.text.trim(),
        'crime_category': _selectedCategory,
        'incident_datetime': _incidentDate?.toUtcFromBangladesh().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report updated successfully!', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF00897B),
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/my-complaints');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? DateTime.now().toBangladeshTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().toBangladeshTime(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_incidentDate ?? DateTime.now().toBangladeshTime()),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppColors.primary),
          ),
          child: child!,
        ),
      );
      if (time != null) {
        setState(() {
          _incidentDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _nidCtrl.dispose();
    _professionCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Report', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my-complaints');
            }
          },
        ),
        actions: [
          if (!_isLoading)
            TextButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.save_rounded, color: AppColors.primary),
              label: Text('Save', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Notice banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You can edit this report while its status is "Submitted". Once an officer reviews it, editing will be locked.',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _sectionLabel(context, 'Crime Details'),
                      const SizedBox(height: 12),

                      // Category dropdown
                      GlassCard(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Crime Category',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: InputBorder.none,
                          ),
                          dropdownColor: const Color(0xFF1A1D2E),
                          items: AppConstants.crimeCategories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                          validator: (v) => v == null ? 'Select a category' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      GlassCard(
                        child: CustomTextField(
                          label: 'Description',
                          controller: _descriptionCtrl,
                          maxLines: 5,
                          prefixIcon: Icons.description_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Incident date
                      GlassCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_outlined, color: AppColors.textHint),
                          title: Text('Incident Date & Time', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textHint)),
                          subtitle: Text(
                            _incidentDate != null
                                ? DateFormat('dd MMMM yyyy, hh:mm a').format(_incidentDate!)
                                : 'Tap to select',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                          ),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location
                      GlassCard(
                        child: CustomTextField(
                          label: 'Incident Location',
                          controller: _locationCtrl,
                          prefixIcon: Icons.place_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_complaint?.isAnonymous == false) ...[
                        _sectionLabel(context, 'Personal Information'),
                        const SizedBox(height: 12),

                        Row(children: [
                          Expanded(child: GlassCard(child: CustomTextField(label: 'First Name', controller: _firstNameCtrl))),
                          const SizedBox(width: 12),
                          Expanded(child: GlassCard(child: CustomTextField(label: 'Last Name', controller: _lastNameCtrl))),
                        ]),
                        const SizedBox(height: 12),
                        GlassCard(child: CustomTextField(label: 'Phone', controller: _phoneCtrl, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone)),
                        const SizedBox(height: 12),
                        GlassCard(child: CustomTextField(label: 'NID / Passport', controller: _nidCtrl, prefixIcon: Icons.badge_outlined)),
                        const SizedBox(height: 12),
                        GlassCard(child: CustomTextField(label: 'Profession', controller: _professionCtrl, prefixIcon: Icons.work_outline_rounded)),
                        const SizedBox(height: 12),
                        GlassCard(child: CustomTextField(label: 'Present Address', controller: _presentAddressCtrl, prefixIcon: Icons.home_outlined, maxLines: 2)),
                        const SizedBox(height: 12),
                        GlassCard(child: CustomTextField(label: 'Permanent Address', controller: _permanentAddressCtrl, prefixIcon: Icons.location_city_outlined, maxLines: 2)),
                        const SizedBox(height: 24),
                      ],

                      GradientButton(
                        label: 'Save Changes',
                        icon: Icons.save_rounded,
                        isLoading: _isSaving,
                        onTap: _isSaving ? null : _save,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700));
  }
}
