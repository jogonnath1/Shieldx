import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shieldx/common/core/utils/app_snackbar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:shieldx/common/core/constants/app_constants.dart';
import 'package:shieldx/common/core/utils/complaint_classifier.dart';
import 'package:shieldx/common/core/utils/date_time_extensions.dart';
import 'package:shieldx/common/data/services/complaint_service.dart';
import 'package:shieldx/common/data/services/storage_service.dart';
import 'package:shieldx/common/providers/connectivity_provider.dart';
import 'package:shieldx/common/providers/complaint_provider.dart';
import 'package:shieldx/common/providers/location_cache_provider.dart';
import 'package:shieldx/common/providers/auth_provider.dart';
import 'package:shieldx/common/presentation/widgets/common/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shieldx/common/core/services/preferences_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shieldx/common/providers/gps_simulation_provider.dart';
import 'package:shieldx/common/data/models/police_station_model.dart';

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

class _SubmitComplaintScreenState extends ConsumerState<SubmitComplaintScreen> {
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
  final _otherCategoryCtrl = TextEditingController();
  String? _selectedCategory;
  String? _selectedPoliceStation;
  DateTime? _incidentDate;
  final List<XFile> _evidenceFiles = [];
  final Map<String, Uint8List> _webEvidenceBytes = {};
  bool _isLoading = false;
  bool _isDetectingLocation = false;
  late bool _isAnonymous;
  int _currentStep = 0;
  ClassificationResult? _aiSuggestion;
  double? _latitude;
  double? _longitude;
  String? _locationError;
  @override
  void initState() {
    super.initState();
    _isAnonymous = widget.initialAnonymous;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraft();
    });
  }

  void _loadDraft() {
    final prefs = ref.read(preferencesServiceProvider);
    final draft = prefs.getComplaintDraft();
    if (draft != null) {
      setState(() {
        _descriptionCtrl.text = draft['description'] as String? ?? '';
        _locationCtrl.text = draft['location_address'] as String? ?? '';
        _selectedCategory = draft['crime_category'] as String?;
        if (_selectedCategory != null &&
            !AppConstants.crimeCategories.contains(_selectedCategory)) {
          _otherCategoryCtrl.text = _selectedCategory!;
          _selectedCategory = 'Other';
        }
        _selectedPoliceStation = draft['police_station'] as String?;
        _isAnonymous = widget.initialAnonymous;
        _currentStep = draft['current_step'] as int? ?? 0;
        _latitude = (draft['latitude'] as num?)?.toDouble();
        _longitude = (draft['longitude'] as num?)?.toDouble();
        final dateStr = draft['incident_datetime'] as String?;
        if (dateStr != null) {
          final utcTime = DateTime.tryParse(dateStr);
          if (utcTime != null) {
            _incidentDate = utcTime.toBangladeshTime();
          }
        }
      });
      if (_descriptionCtrl.text.isNotEmpty) {
        _onDescriptionChanged(_descriptionCtrl.text);
      }
    } else {
      if (widget.initialPoliceStation != null &&
          widget.initialPoliceStation!.isNotEmpty) {
        setState(() {
          _selectedPoliceStation = widget.initialPoliceStation;
        });
      }
    }
    _autoFillFromProfile();
    // Always instantly auto-detect police station on entry based on the user's current live location,
    // unless they navigated here with a pre-selected station (e.g. from the station map).
    if (widget.initialPoliceStation == null ||
        widget.initialPoliceStation!.isEmpty) {
      _detectPoliceStation(
        forceFresh: true,
        updateIncidentLocation:
            false, // Never auto-fill incident location on entry! Let users type it manually.
      );
    }
    _attachControllerListeners();
  }

  Future<void> _autoFillFromProfile() async {
    try {
      await ref.read(authNotifierProvider.notifier).refresh();
      final profile = ref.read(authNotifierProvider).valueOrNull;
      if (profile != null && mounted) {
        setState(() {
          if (profile.name != null && profile.name!.isNotEmpty) {
            final parts = profile.name!.trim().split(' ');
            if (parts.length > 1) {
              _firstNameCtrl.text = parts.first;
              _lastNameCtrl.text = parts.sublist(1).join(' ');
            } else {
              _firstNameCtrl.text = profile.name!;
              _lastNameCtrl.text = '';
            }
          } else {
            _firstNameCtrl.text = '';
            _lastNameCtrl.text = '';
          }
          _phoneCtrl.text = profile.phone ?? '';
          _nidCtrl.text = profile.nid ?? '';
          _professionCtrl.text = profile.profession ?? '';
          _presentAddressCtrl.text = profile.presentAddress ?? '';
          _permanentAddressCtrl.text = profile.permanentAddress ?? '';
        });
        _saveDraft();
      }
    } catch (e) {
      debugPrint('Error auto-filling from profile: $e');
    }
  }

  void _attachControllerListeners() {
    final controllers = [
      _firstNameCtrl,
      _lastNameCtrl,
      _phoneCtrl,
      _nidCtrl,
      _professionCtrl,
      _presentAddressCtrl,
      _permanentAddressCtrl,
      _descriptionCtrl,
      _locationCtrl,
      _otherCategoryCtrl,
    ];
    for (final ctrl in controllers) {
      ctrl.addListener(_saveDraft);
    }
  }

  void _saveDraft() {
    if (!mounted) return;
    final draft = {
      'first_name': _firstNameCtrl.text,
      'last_name': _lastNameCtrl.text,
      'phone': _phoneCtrl.text,
      'nid': _nidCtrl.text,
      'profession': _professionCtrl.text,
      'present_address': _presentAddressCtrl.text,
      'permanent_address': _permanentAddressCtrl.text,
      'description': _descriptionCtrl.text,
      'location_address': _locationCtrl.text,
      'crime_category': _selectedCategory == 'Other'
          ? (_otherCategoryCtrl.text.trim().isNotEmpty
              ? _otherCategoryCtrl.text.trim()
              : 'Other')
          : _selectedCategory,
      'police_station': _selectedPoliceStation,
      'is_anonymous': _isAnonymous,
      'current_step': _currentStep,
      'incident_datetime':
          _incidentDate?.toUtcFromBangladesh().toIso8601String(),
      'latitude': _latitude,
      'longitude': _longitude,
    };
    ref.read(preferencesServiceProvider).saveComplaintDraft(draft);
  }

  Future<void> _detectPoliceStation(
      {bool forceFresh = false, bool updateIncidentLocation = false}) async {
    if (!mounted) return;
    setState(() {
      _isDetectingLocation = true;
      _locationError = null;
    });
    try {
      double? lat;
      double? lon;

      final sim = ref.read(gpsSimulationProvider);
      if (sim.isSimulationActive) {
        lat = sim.latitude;
        lon = sim.longitude;
      } else {
        // Robust and blazing-fast Geolocator query
        Position? pos;
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            _locationError = 'Location access denied by user/browser.';
          } else if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            // Try last known position first (extremely fast/instant)
            try {
              pos = await Geolocator.getLastKnownPosition()
                  .timeout(const Duration(seconds: 2));
            } catch (_) {
              pos = null;
            }

            // Fall back to current position if last known is not available
            pos ??= await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
              ),
            ).timeout(const Duration(
                seconds: 10)); // Increased timeout to 10s for web
          }
        } catch (_) {
          pos = null;
          _locationError ??=
              'Timeout getting location. Please select manually.';
        }

        if (pos != null) {
          lat = pos.latitude;
          lon = pos.longitude;
        } else {
          // Fallback to IP Geolocation if GPS/Browser location fails or times out
          try {
            final response = await http
                .get(Uri.parse('http://ip-api.com/json/'))
                .timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              lat = (data['lat'] as num?)?.toDouble();
              lon = (data['lon'] as num?)?.toDouble();
            }
          } catch (_) {}

          if (lat != null && lon != null) {
            _locationError =
                null; // Clear error since we got a fallback location
          } else {
            _locationError ??=
                'Could not detect location. Please select manually.';
          }
        }
      }

      if (lat != null && lon != null && mounted) {
        _latitude = lat;
        _longitude = lon;

        // Resolve thana and station
        final thana = resolveSmpThana(lat, lon);
        final stationName = thanaToStationName(thana);
        if (stationName != null) {
          // Combine both lists to search
          final allStations = [
            ...dummyPoliceStations,
            ...adminAllPoliceStations
          ];
          // Find the best match
          final match = allStations.where((s) {
            final sNameLower = s.name.toLowerCase();
            final stNameLower = stationName.toLowerCase();
            return sNameLower.contains(stNameLower) ||
                stNameLower.contains(sNameLower) ||
                s.thana == thana;
          }).firstOrNull;

          if (match != null) {
            setState(() {
              _selectedPoliceStation = '${match.name} (${match.division})';
              if (updateIncidentLocation && _locationCtrl.text.isEmpty) {
                _locationCtrl.text = "Detected Location: ($lat, $lon)";
              }
            });
          } else {
            setState(() {
              _locationError =
                  'Auto-detected station not in the list. Please select manually.';
            });
          }
        } else {
          setState(() {
            _locationError = 'Live location is outside SMP service area.';
          });
        }

        // Perform reverse geocoding with OSM Nominatim API for a super premium look!
        if (updateIncidentLocation) {
          try {
            final uri = Uri.parse(
                'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&zoom=18&addressdetails=1');
            final response = await http.get(uri, headers: {
              'User-Agent': 'com.shieldx.app'
            }).timeout(const Duration(seconds: 4));
            if (response.statusCode == 200 && mounted) {
              final data = jsonDecode(response.body);
              final displayName = data['display_name'] as String?;
              if (displayName != null && displayName.isNotEmpty) {
                setState(() {
                  _locationCtrl.text = displayName;
                });
              }
            }
          } catch (e) {
            debugPrint('Reverse geocoding error: $e');
          }
        }

        _saveDraft();
      }
    } catch (e) {
      debugPrint('Error in detect police station: $e');
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
    _otherCategoryCtrl.dispose();
    super.dispose();
  }

  void _onDescriptionChanged(String text) {
    final result = ComplaintClassifier.classify(text);
    setState(() => _aiSuggestion = result);
    if (result != null && _selectedCategory == null) {
      setState(() => _selectedCategory = result.category);
      _saveDraft();
    }
  }

  Future<void> _pickEvidenceFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (kIsWeb) {
            if (file.bytes != null && !_webEvidenceBytes.containsKey(file.name)) {
              final xfile = XFile.fromData(file.bytes!,
                  name: file.name, length: file.size);
              _evidenceFiles.add(xfile);
              _webEvidenceBytes[file.name] = file.bytes!;
            }
          } else {
            if (!_evidenceFiles.any((e) => e.name == file.name)) {
              _evidenceFiles.add(XFile(file.path!, name: file.name));
            }
          }
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final nowBDT = DateTime.now().toBangladeshTime();
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? nowBDT,
      firstDate: DateTime(2000),
      lastDate: nowBDT,
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
        initialTime: _incidentDate != null
            ? TimeOfDay.fromDateTime(_incidentDate!)
            : TimeOfDay.now(),
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
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        final now = DateTime.now().toBangladeshTime();
        if (selectedDateTime.isAfter(now)) {
          setState(() {
            _incidentDate = now;
          });
          _saveDraft();
          _showError('Future time is not allowed. Reverted to current time.');
          return;
        }
        setState(() {
          _incidentDate = selectedDateTime;
        });
        _saveDraft();
      }
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Please select a crime category');
      return;
    }
    if (_selectedPoliceStation == null ||
        _selectedPoliceStation!.trim().isEmpty) {
      _showError('Please select a police station');
      return;
    }
    if (_incidentDate == null) {
      _showError('Please select incident date & time');
      return;
    }
    if (_incidentDate!.isAfter(DateTime.now().toBangladeshTime())) {
      _showError('Incident date & time cannot be in the future.');
      return;
    }
    if (_isAnonymous && _evidenceFiles.isEmpty) {
      _showError(
          'Evidence files are required for anonymous reports. Please upload at least one evidence file.');
      return;
    }
    setState(() => _isLoading = true);
    final isOnline =
        await ref.read(connectivityProvider.notifier).checkConnection();
    if (!isOnline) {
      _showError(
          'No internet connection. Active internet connection is required to submit a report.');
      setState(() => _isLoading = false);
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final complaintId = const Uuid().v4();
    final List<String> uploadedUrls = [];
    final storage = StorageService();
    try {
      for (final file in _evidenceFiles) {
        if (kIsWeb) {
          final bytes = _webEvidenceBytes[file.name];
          if (bytes != null) {
            final url = await storage.uploadEvidenceBytes(
              bytes: bytes,
              fileName: file.name,
              complaintId: complaintId,
            );
            uploadedUrls.add(url);
          }
        } else {
          final fileObj = File(file.path);
          final url = await storage.uploadEvidence(fileObj, complaintId);
          uploadedUrls.add(url);
        }
      }
    } catch (uploadError) {
      _showError('Failed to upload evidence attachments: $uploadError');
      setState(() => _isLoading = false);
      return;
    }
    final complaintData = {
      'id': complaintId,
      'user_id': userId,
      'first_name': _isAnonymous ? null : _firstNameCtrl.text.trim(),
      'last_name': _isAnonymous ? null : _lastNameCtrl.text.trim(),
      'phone': _isAnonymous ? null : _phoneCtrl.text.trim(),
      'nid': _isAnonymous ? null : _nidCtrl.text.trim(),
      'profession': _isAnonymous ? null : _professionCtrl.text.trim(),
      'present_address': _isAnonymous ? null : _presentAddressCtrl.text.trim(),
      'permanent_address':
          _isAnonymous ? null : _permanentAddressCtrl.text.trim(),
      'crime_category': _selectedCategory == 'Other'
          ? (_otherCategoryCtrl.text.trim().isNotEmpty
              ? _otherCategoryCtrl.text.trim()
              : 'Other')
          : _selectedCategory,
      'description': _descriptionCtrl.text.trim(),
      'location_address': _locationCtrl.text.trim(),
      'incident_datetime':
          _incidentDate?.toUtcFromBangladesh().toIso8601String(),
      'police_station': _selectedPoliceStation,
      'evidence_urls': uploadedUrls,
      'is_anonymous': _isAnonymous,
      'latitude': _latitude,
      'longitude': _longitude,
    };
    try {
      final service = ComplaintService();
      await service.submitComplaint(complaintData);
      try {
        await ref.read(preferencesServiceProvider).clearComplaintDraft();
      } catch (_) {}
      if (userId != null) {
        ref.invalidate(userComplaintsStreamProvider(userId));
      }
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
    if (!mounted) return;
    AppSnackbar.error(context, msg);
  }

  Widget _buildCustomStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _buildStepItem(
            index: 0,
            label: 'Personal Info',
            icon: Icons.person_rounded,
          ),
          _buildStepConnector(0),
          _buildStepItem(
            index: 1,
            label: 'Incident Details',
            icon: Icons.description_rounded,
          ),
          _buildStepConnector(1),
          _buildStepItem(
            index: 2,
            label: 'Evidence',
            icon: Icons.cloud_upload_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isCompleted = _currentStep > index;
    final isActive = _currentStep == index;
    Color statusColor;
    if (isActive) {
      statusColor = AppColors.primary;
    } else if (isCompleted) {
      statusColor = AppColors.success;
    } else {
      statusColor = AppColors.textHint;
    }
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          if (index > _currentStep) {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            if (_currentStep == 1) {
              if (_selectedPoliceStation == null ||
                  _selectedPoliceStation!.trim().isEmpty) {
                _showError('Please select a police station');
                return;
              }
              if (_incidentDate == null) {
                _showError('Please select incident date & time');
                return;
              }
            }
          }
          setState(() {
            _currentStep = index;
          });
          _saveDraft();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : isCompleted
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : icon,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : isCompleted
                        ? AppColors.textPrimary
                        : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    return Container(
      width: 20,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.success
            : AppColors.cardBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _PersonalInfoStep(
          key: const ValueKey('personal_info'),
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          phoneCtrl: _phoneCtrl,
          nidCtrl: _nidCtrl,
          professionCtrl: _professionCtrl,
          presentAddressCtrl: _presentAddressCtrl,
          permanentAddressCtrl: _permanentAddressCtrl,
          isAnonymous: _isAnonymous,
          onAnonymousChanged: (v) {
            setState(() => _isAnonymous = v);
            _saveDraft();
          },
        );
      case 1:
        return _IncidentStep(
          key: const ValueKey('incident_details'),
          selectedCategory: _selectedCategory,
          onCategoryChanged: (v) {
            setState(() => _selectedCategory = v);
            _saveDraft();
          },
          otherCategoryCtrl: _otherCategoryCtrl,
          descriptionCtrl: _descriptionCtrl,
          locationCtrl: _locationCtrl,
          incidentDate: _incidentDate,
          onPickDate: _pickDate,
          aiSuggestion: _aiSuggestion,
          onDescriptionChanged: _onDescriptionChanged,
          selectedPoliceStation: _selectedPoliceStation,
          onPoliceStationChanged: (v) {
            setState(() => _selectedPoliceStation = v);
            _saveDraft();
          },
          isDetectingLocation: _isDetectingLocation,
          locationError: _locationError,
          onRetryDetect: () {
            setState(() {
              _selectedPoliceStation = null;
              _isDetectingLocation = true;
            });
            _saveDraft();
            _detectPoliceStation(
                forceFresh: true, updateIncidentLocation: false);
          },
        );
      case 2:
        return _EvidenceStep(
          key: const ValueKey('evidence'),
          files: _evidenceFiles,
          webBytes: _webEvidenceBytes,
          isAnonymous: _isAnonymous,
          onPickImage: _pickEvidenceFiles,
          onRemove: (i) {
            final removed = _evidenceFiles.removeAt(i);
            _webEvidenceBytes.remove(removed.name);
            setState(() {});
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavigationControls() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: GradientButton(
              label: _currentStep == 2 ? 'Submit Report' : 'Continue',
              isLoading: _isLoading,
              onTap: () {
                if (_currentStep < 2) {
                  FocusScope.of(context).unfocus();
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  if (_currentStep == 1) {
                    if (_selectedPoliceStation == null ||
                        _selectedPoliceStation!.trim().isEmpty) {
                      _showError('Please select a police station');
                      return;
                    }
                    if (_incidentDate == null) {
                      _showError('Please select incident date & time');
                      return;
                    }
                  }
                  setState(() => _currentStep++);
                  _saveDraft();
                } else {
                  _submit();
                }
              },
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
                onPressed: _isLoading
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        setState(() => _currentStep--);
                        _saveDraft();
                      },
                child: const Text('Back'),
              ),
            ),
          ],
        ],
      ),
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
            child: Column(
              children: [
                _buildCustomStepper(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.05),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _buildCurrentStepContent(),
                        ),
                        const SizedBox(height: 12),
                        _buildNavigationControls(),
                      ],
                    ),
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
  final TextEditingController firstNameCtrl,
      lastNameCtrl,
      phoneCtrl,
      nidCtrl,
      professionCtrl,
      presentAddressCtrl,
      permanentAddressCtrl;
  final bool isAnonymous;
  final ValueChanged<bool> onAnonymousChanged;
  const _PersonalInfoStep({
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

class _IncidentStep extends StatelessWidget {
  final String? selectedCategory;
  final void Function(String?) onCategoryChanged;
  final TextEditingController otherCategoryCtrl;
  final TextEditingController descriptionCtrl, locationCtrl;
  final DateTime? incidentDate;
  final VoidCallback onPickDate;
  final ClassificationResult? aiSuggestion;
  final ValueChanged<String> onDescriptionChanged;
  final String? selectedPoliceStation;
  final void Function(String?) onPoliceStationChanged;
  final bool isDetectingLocation;
  final VoidCallback onRetryDetect;
  final String? locationError;
  const _IncidentStep({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.otherCategoryCtrl,
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
    this.locationError,
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
        if (selectedCategory == 'Other') ...[
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Specify Category',
            controller: otherCategoryCtrl,
            prefixIcon: Icons.edit_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Please specify the crime category'
                : null,
          ),
        ],
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
        if (aiSuggestion != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                      const Color(0xFF1565C0).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
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
                                  fontSize: 11, color: AppColors.textHint),
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
                          color: AppColors.primary.withValues(alpha: 0.2),
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
          validator: (v) =>
              v == null || v.isEmpty ? 'Incident location is required' : null,
        ),
        const SizedBox(height: 16),
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
                DropdownButtonFormField<String?>(
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
                    suffixIcon: IconButton(
                      tooltip: 'Detect location',
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: selectedPoliceStation != null
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 18,
                      ),
                      onPressed: onRetryDetect,
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Select police station',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    ...(() {
                      final map = <String, PoliceStation>{};
                      for (final s in [
                        ...dummyPoliceStations,
                        ...adminAllPoliceStations
                      ]) {
                        final key = '${s.name} (${s.division})';
                        map.putIfAbsent(key, () => s);
                      }
                      return map.values.map((s) {
                        final displayName = '${s.name} (${s.division})';
                        return DropdownMenuItem<String?>(
                          value: displayName,
                          child: Text(displayName,
                              style: GoogleFonts.inter(fontSize: 13)),
                        );
                      });
                    })(),
                  ],
                  onChanged:
                      isDetectingLocation ? null : onPoliceStationChanged,
                  validator: (v) => v == null || v.isEmpty
                      ? 'Police station is required'
                      : null,
                ),
                if (selectedPoliceStation != null)
                  Positioned(
                    top: 6,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
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
                    Expanded(
                      child: Text(
                        locationError ??
                            'Location access denied — please select manually.',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textHint),
                      ),
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
  final Map<String, Uint8List> webBytes;
  final bool isAnonymous;
  final VoidCallback onPickImage;
  final void Function(int) onRemove;
  const _EvidenceStep({
    super.key,
    required this.files,
    required this.webBytes,
    required this.isAnonymous,
    required this.onPickImage,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAnonymous
              ? 'Upload Evidence Files (Required for Anonymous Reports)'
              : 'Upload Evidence Files (Optional)',
          style: GoogleFonts.inter(
            color: isAnonymous ? AppColors.error : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isAnonymous ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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
            itemBuilder: (ctx, i) {
              final file = files[i];
              final isImage = file.name.toLowerCase().endsWith('.jpg') ||
                  file.name.toLowerCase().endsWith('.jpeg') ||
                  file.name.toLowerCase().endsWith('.png');
              Widget? previewWidget;
              if (isImage) {
                if (kIsWeb) {
                  final bytes = webBytes[file.name];
                  if (bytes != null) {
                    previewWidget = Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  }
                } else {
                  previewWidget = Image.file(
                    File(file.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                }
              }
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: previewWidget ??
                        Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          width: double.infinity,
                          height: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.insert_drive_file_outlined,
                                  color: AppColors.primary, size: 28),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
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
              );
            },
          ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Icon(Icons.upload_file_outlined,
                    color: AppColors.primary, size: 36),
                const SizedBox(height: 8),
                Text('Tap to add files',
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
