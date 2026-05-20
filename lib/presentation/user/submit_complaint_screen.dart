import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/complaint_classifier.dart';
import '../../data/services/complaint_service.dart';
import '../../providers/location_cache_provider.dart';
import '../widgets/common/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Police station names for the dropdown ──────────────────────────────────
const List<String> smpPoliceStations = [
  'Kotwali Model Police Station',
  'Jalalabad Police Station',
  'Moglabazar Police Station',
  'South Surma Police Station',
  'Shahporan Police Station',
  'Airport Police Station',
];



class SubmitComplaintScreen extends ConsumerStatefulWidget {
  final bool initialAnonymous;
  final String? initialPoliceStation;
  const SubmitComplaintScreen({
    super.key,
    this.initialAnonymous = false,
    this.initialPoliceStation,
  });

  @override
  ConsumerState<SubmitComplaintScreen> createState() =>
      _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState
    extends ConsumerState<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _professionCtrl = TextEditingController();
  final _presentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedPoliceStation;
  DateTime? _incidentDate;
  final List<XFile> _evidenceFiles = [];
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  late bool _isAnonymous;
  int _currentStep = 0;
  ClassificationResult? _aiSuggestion;

  @override
  void initState() {
    super.initState();
    _isAnonymous = widget.initialAnonymous;

    // If navigated from Station Map, use that station immediately — no GPS needed
    if (widget.initialPoliceStation != null &&
        widget.initialPoliceStation!.isNotEmpty) {
      _selectedPoliceStation = widget.initialPoliceStation;
    } else {
      // Otherwise detect via GPS
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _detectPoliceStation());
    }
  }

  /// Detects the police station using GPS and sets [_selectedPoliceStation].
  /// Uses [resolveStationFromGps] directly — no provider timing issues.
  Future<void> _detectPoliceStation() async {
    if (!mounted) return;

    // Fast-path: provider already has the result (pre-warmed from HomeScreen)
    final cached = ref.read(detectedStationProvider).valueOrNull;
    if (cached != null && cached.isNotEmpty) {
      setState(() => _selectedPoliceStation = cached);
      return;
    }

    // Direct GPS call — always works regardless of provider state
    setState(() => _isDetectingLocation = true);
    try {
      final station = await resolveStationFromGps();
      if (station != null && station.isNotEmpty && mounted) {
        setState(() => _selectedPoliceStation = station);
        // Cache result in provider so retry is instant
        ref.invalidate(detectedStationProvider);
      }
    } catch (_) {
      // User can select manually
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _nidCtrl.dispose();
    _professionCtrl.dispose();
    _presentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String text) {
    final result = ComplaintClassifier.classify(text);
    setState(() => _aiSuggestion = result);
    // Auto-fill category if not already chosen
    if (result != null && _selectedCategory == null) {
      setState(() => _selectedCategory = result.category);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _evidenceFiles.addAll(picked);
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        ),
      );
      if (time != null) {
        setState(() {
          _incidentDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Please select a crime category');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final service = ComplaintService();
      await service.submitComplaint({
        'user_id': userId,
        'first_name': _isAnonymous ? null : _firstNameCtrl.text.trim(),
        'last_name': _isAnonymous ? null : _lastNameCtrl.text.trim(),
        'phone': _isAnonymous ? null : _phoneCtrl.text.trim(),
        'nid': _isAnonymous ? null : _nidCtrl.text.trim(),
        'profession': _isAnonymous ? null : _professionCtrl.text.trim(),
        'present_address': _isAnonymous ? null : _presentAddressCtrl.text.trim(),
        'permanent_address': _isAnonymous ? null : _permanentAddressCtrl.text.trim(),
        'crime_category': _selectedCategory,
        'description': _descriptionCtrl.text.trim(),
        'location_address': _locationCtrl.text.trim(),
        'incident_datetime': _incidentDate?.toIso8601String(),
        'police_station': _selectedPoliceStation,
        'evidence_urls': [],
        'is_anonymous': _isAnonymous,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/my-complaints');
    } catch (e) {
      _showError('Failed to submit: $e');
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
      appBar: AppBar(
        title: const Text('Submit Crime Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: LoadingOverlay(
          isLoading: _isLoading,
          child: Form(
            key: _formKey,
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep++);
                } else {
                  _submit();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                } else {
                  context.go('/home');
                }
              },
              controlsBuilder: (ctx, details) => Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        label: _currentStep == 2 ? 'Submit Report' : 'Continue',
                        onTap: details.onStepContinue,
                        icon: _currentStep == 2
                            ? Icons.send_rounded
                            : Icons.arrow_forward_rounded,
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              steps: [
                Step(
                  title: Text('Personal Info',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: _PersonalInfoStep(
                    firstNameCtrl: _firstNameCtrl,
                    lastNameCtrl: _lastNameCtrl,
                    phoneCtrl: _phoneCtrl,
                    nidCtrl: _nidCtrl,
                    professionCtrl: _professionCtrl,
                    presentAddressCtrl: _presentAddressCtrl,
                    permanentAddressCtrl: _permanentAddressCtrl,
                    isAnonymous: _isAnonymous,
                    onAnonymousChanged: (v) => setState(() => _isAnonymous = v),
                  ),
                ),
                Step(
                  title: Text('Incident Details',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: _IncidentStep(
                    selectedCategory: _selectedCategory,
                    onCategoryChanged: (v) =>
                        setState(() => _selectedCategory = v),
                    descriptionCtrl: _descriptionCtrl,
                    locationCtrl: _locationCtrl,
                    incidentDate: _incidentDate,
                    onPickDate: _pickDate,
                    aiSuggestion: _aiSuggestion,
                    onDescriptionChanged: _onDescriptionChanged,
                    selectedPoliceStation: _selectedPoliceStation,
                    onPoliceStationChanged: (v) =>
                        setState(() => _selectedPoliceStation = v),
                    isDetectingLocation: _isDetectingLocation,
                    onRetryDetect: () {
                      setState(() => _selectedPoliceStation = null);
                      _detectPoliceStation();
                    },
                  ),
                ),
                Step(
                  title: Text('Evidence',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  isActive: _currentStep >= 2,
                  content: _EvidenceStep(
                    files: _evidenceFiles,
                    onPickImage: _pickImage,
                    onRemove: (i) =>
                        setState(() => _evidenceFiles.removeAt(i)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonalInfoStep extends StatelessWidget {
  final TextEditingController firstNameCtrl, lastNameCtrl, phoneCtrl,
      nidCtrl, professionCtrl, presentAddressCtrl, permanentAddressCtrl;
  final bool isAnonymous;
  final ValueChanged<bool> onAnonymousChanged;

  const _PersonalInfoStep({
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
        // Anonymous Toggle Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAnonymous
                  ? [const Color(0xFF7B1FA2).withOpacity(0.15), const Color(0xFF1565C0).withOpacity(0.15)]
                  : [AppColors.surfaceLight, AppColors.surfaceLight],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAnonymous ? AppColors.primary.withOpacity(0.5) : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAnonymous
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.cardBorder.withOpacity(0.3),
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
                        color: isAnonymous ? AppColors.primary : AppColors.textPrimary,
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
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Last Name',
                  controller: lastNameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Phone Number',
            controller: phoneCtrl,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'NID Number',
            controller: nidCtrl,
            prefixIcon: Icons.credit_card_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Profession',
            controller: professionCtrl,
            prefixIcon: Icons.work_outline,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Present Address',
            controller: presentAddressCtrl,
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Permanent Address',
            controller: permanentAddressCtrl,
            prefixIcon: Icons.home_outlined,
            maxLines: 2,
          ),
        ] else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
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

class _IncidentStep extends StatelessWidget {
  final String? selectedCategory;
  final void Function(String?) onCategoryChanged;
  final TextEditingController descriptionCtrl, locationCtrl;
  final DateTime? incidentDate;
  final VoidCallback onPickDate;
  final ClassificationResult? aiSuggestion;
  final ValueChanged<String> onDescriptionChanged;
  final String? selectedPoliceStation;
  final void Function(String?) onPoliceStationChanged;
  final bool isDetectingLocation;
  final VoidCallback onRetryDetect;

  const _IncidentStep({
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.descriptionCtrl,
    required this.locationCtrl,
    required this.incidentDate,
    required this.onPickDate,
    required this.aiSuggestion,
    required this.onDescriptionChanged,
    required this.selectedPoliceStation,
    required this.onPoliceStationChanged,
    required this.isDetectingLocation,
    required this.onRetryDetect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          dropdownColor: AppColors.card,
          decoration: const InputDecoration(
            labelText: 'Crime Category',
            prefixIcon: Icon(Icons.category_outlined,
                color: AppColors.textHint, size: 20),
          ),
          items: AppConstants.crimeCategories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onCategoryChanged,
          validator: (v) => v == null ? 'Select category' : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Description',
          controller: descriptionCtrl,
          prefixIcon: Icons.description_outlined,
          maxLines: 4,
          onChanged: onDescriptionChanged,
          validator: (v) =>
              v == null || v.isEmpty ? 'Description is required' : null,
        ),
        // AI Suggestion Chip
        if (aiSuggestion != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B1FA2).withOpacity(0.15),
                      const Color(0xFF1565C0).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'AI suggests: '),
                            TextSpan(
                              text: aiSuggestion!.category,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                            TextSpan(
                              text: '  •  ${aiSuggestion!.confidenceLabel}',
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onCategoryChanged(aiSuggestion!.category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Apply',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Incident Location',
          controller: locationCtrl,
          prefixIcon: Icons.place_outlined,
          maxLines: 2,
        ),
        const SizedBox(height: 16),
        // ── Police Station Field ─────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_police_outlined,
                    color: AppColors.textHint, size: 18),
                const SizedBox(width: 8),
                Text(
                  'That Incident Place is Under the Police Station',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedPoliceStation,
                  dropdownColor: AppColors.card,
                  decoration: InputDecoration(
                    prefixIcon: isDetectingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : const Icon(Icons.account_balance_outlined,
                            color: AppColors.textHint, size: 20),
                    hintText: isDetectingLocation
                        ? 'Detecting your location…'
                        : 'Select police station',
                    hintStyle: GoogleFonts.inter(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                    suffixIcon: selectedPoliceStation != null
                        ? const Icon(Icons.gps_fixed_rounded,
                            color: AppColors.primary, size: 18)
                        : IconButton(
                            tooltip: 'Detect location',
                            icon: const Icon(Icons.my_location_rounded,
                                color: AppColors.textHint, size: 18),
                            onPressed: onRetryDetect,
                          ),
                  ),
                  items: smpPoliceStations
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s,
                                style: GoogleFonts.inter(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: isDetectingLocation ? null : onPoliceStationChanged,
                ),
                if (selectedPoliceStation != null)
                  Positioned(
                    top: 6,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.gps_fixed_rounded,
                              color: AppColors.primary, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            'Auto-detected',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (!isDetectingLocation && selectedPoliceStation == null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      'Location access denied — please select manually.',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textHint, size: 20),
                const SizedBox(width: 12),
                Text(
                  incidentDate != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(incidentDate!)
                      : 'Select Incident Date & Time',
                  style: GoogleFonts.inter(
                    color: incidentDate != null
                        ? AppColors.textPrimary
                        : AppColors.textHint,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _EvidenceStep extends StatelessWidget {
  final List<XFile> files;
  final VoidCallback onPickImage;
  final void Function(int) onRemove;

  const _EvidenceStep({
    required this.files,
    required this.onPickImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Evidence Photos (Optional)',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 12),
        if (files.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: files.length,
            itemBuilder: (ctx, i) => Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.network(files[i].path,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity)
                      : Image.file(File(files[i].path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemove(i),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Icon(Icons.add_photo_alternate_outlined,
                    color: AppColors.primary, size: 36),
                const SizedBox(height: 8),
                Text('Tap to add photos',
                    style: GoogleFonts.inter(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
