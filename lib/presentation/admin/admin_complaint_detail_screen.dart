import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/complaint_service.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/status_history_model.dart';
import '../../data/models/officer_model.dart';
import 'package:shieldx/data/models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/officer_provider.dart';
import '../../providers/complaint_provider.dart';
import '../widgets/common/widgets.dart';

class AdminComplaintDetailScreen extends ConsumerStatefulWidget {
  final String complaintId;
  const AdminComplaintDetailScreen({super.key, required this.complaintId});

  @override
  ConsumerState<AdminComplaintDetailScreen> createState() =>
      _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState
    extends ConsumerState<AdminComplaintDetailScreen>
    with SingleTickerProviderStateMixin {
  ComplaintModel? _complaint;
  List<StatusHistoryModel> _history = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  late TabController _tabCtrl;

  String? _selectedStatus;
  String? _selectedOfficerId;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cs = ComplaintService();
    final c = await cs.getComplaint(widget.complaintId);
    final h = await cs.getStatusHistory(widget.complaintId);
    if (mounted) {
      setState(() {
        _complaint = c;
        _history = h;
        _selectedStatus = c?.status;
        _selectedOfficerId = c?.assignedOfficerId;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;
    setState(() => _isUpdating = true);
    try {
      final profile = ref.read(authNotifierProvider).valueOrNull!;
      await ComplaintService().updateComplaintStatus(
        complaintId: widget.complaintId,
        status: _selectedStatus!,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        assignedOfficerId: _selectedOfficerId,
        changedBy: profile.id,
      );
      _noteCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Status updated!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case #${_complaint?.caseId ?? '...'}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin/complaints');
            }
          },
        ),
        actions: [
          if (_complaint != null)
            ref.watch(unreadMessagesCountProvider(_complaint!.id)).when(
                  data: (count) => IconButton(
                    icon: Badge(
                      label: Text('$count'),
                      isLabelVisible: count > 0,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.chat_bubble_outline_rounded),
                    ),
                    onPressed: () => context.push('/chat/${_complaint!.id}'),
                  ),
                  loading: () => IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: () => context.push('/chat/${_complaint!.id}'),
                  ),
                  error: (_, __) => IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    onPressed: () => context.push('/chat/${_complaint!.id}'),
                  ),
                ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Manage'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _complaint == null
                ? const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Not Found',
                    subtitle: 'This complaint could not be loaded.')
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _DetailsTab(complaint: _complaint!),
                      _ManageTab(
                        complaint: _complaint!,
                        officers: ref.watch(activeOfficersProvider).valueOrNull ?? [],
                        selectedStatus: _selectedStatus,
                        selectedOfficerId: _selectedOfficerId,
                        noteCtrl: _noteCtrl,
                        isUpdating: _isUpdating,
                        onStatusChanged: (v) =>
                            setState(() => _selectedStatus = v),
                        onOfficerChanged: (v) =>
                            setState(() => _selectedOfficerId = v),
                        onUpdate: _updateStatus,
                      ),
                      _TimelineTab(history: _history),
                    ],
                  ),
      ),
    );
  }
}

class _DetailsTab extends ConsumerWidget {
  final ComplaintModel complaint;
  const _DetailsTab({required this.complaint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadMessagesCountProvider(complaint.id));
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    final profilesAsync = ref.watch(allProfilesStreamProvider);
    final profiles = profilesAsync.valueOrNull ?? [];
    final matchedProfile = complaint.userId != null
        ? profiles.cast<ProfileModel?>().firstWhere((p) => p?.id == complaint.userId, orElse: () => null)
        : null;
    final isVerified = matchedProfile?.isVerified ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(complaint.crimeCategory ?? 'Unknown',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    StatusBadge(status: complaint.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (complaint.description != null)
                  Text(complaint.description!,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.6)),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Complainant Info',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (complaint.isAnonymous)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_off_rounded, color: Colors.orange, size: 13),
                            const SizedBox(width: 5),
                            Text('Anonymous',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                InfoTile(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: complaint.isAnonymous ? 'Anonymous User' : complaint.fullName,
                  trailing: (!complaint.isAnonymous && matchedProfile != null)
                      ? Icon(
                          isVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
                          color: isVerified ? const Color(0xFF2196F3) : const Color(0xFFFFB300),
                          size: 16,
                        )
                      : null,
                ),
                if (!complaint.isAnonymous) ...[
                  if (complaint.phone != null)
                    InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: complaint.phone!),
                  if (complaint.nid != null)
                    InfoTile(icon: Icons.credit_card_outlined, label: 'NID', value: complaint.nid!),
                  if (complaint.profession != null)
                    InfoTile(icon: Icons.work_outline, label: 'Profession', value: complaint.profession!),
                  if (complaint.presentAddress != null)
                    InfoTile(icon: Icons.location_on_outlined, label: 'Present Address', value: complaint.presentAddress!),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Incident Info',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (complaint.locationAddress != null)
                  InfoTile(icon: Icons.place_outlined, label: 'Location', value: complaint.locationAddress!),
                if (complaint.incidentDatetime != null)
                  InfoTile(
                      icon: Icons.event_outlined,
                      label: 'Incident Date',
                      value: DateFormat('dd MMM yyyy, hh:mm a').format(complaint.incidentDatetime!.toBangladeshTime())),
                InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Filed On',
                    value: complaint.createdAt != null
                        ? complaint.createdAt!.formatBDT('dd MMM yyyy, hh:mm a')
                        : 'Unknown'),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),
          GradientButton(
            label: unreadCount > 0 ? 'Open Chat ($unreadCount New)' : 'Open Chat',
            icon: Icons.chat_rounded,
            onTap: () => context.push('/chat/${complaint.id}'),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }
}

class _ManageTab extends StatelessWidget {
  final ComplaintModel complaint;
  final List<OfficerModel> officers;
  final String? selectedStatus;
  final String? selectedOfficerId;
  final TextEditingController noteCtrl;
  final bool isUpdating;
  final void Function(String?) onStatusChanged;
  final void Function(String?) onOfficerChanged;
  final VoidCallback onUpdate;

  const _ManageTab({
    required this.complaint,
    required this.officers,
    required this.selectedStatus,
    required this.selectedOfficerId,
    required this.noteCtrl,
    required this.isUpdating,
    required this.onStatusChanged,
    required this.onOfficerChanged,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Update Status',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: AppConstants.complaintStatuses
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(AppConstants.statusLabel(s))))
                      .toList(),
                  onChanged: onStatusChanged,
                ),
                const SizedBox(height: 12),
                if (officers.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedOfficerId,
                    dropdownColor: AppColors.card,
                    decoration: const InputDecoration(labelText: 'Assign Officer'),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Unassigned')),
                      ...officers.map((o) => DropdownMenuItem(
                          value: o.id, child: Text(o.name ?? 'Officer')))
                    ],
                    onChanged: onOfficerChanged,
                  ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Note (Optional)',
                  controller: noteCtrl,
                  prefixIcon: Icons.note_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: 'Update Status',
                  icon: Icons.update_rounded,
                  onTap: isUpdating ? null : onUpdate,
                  isLoading: isUpdating,
                ),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final List<StatusHistoryModel> history;
  const _TimelineTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No History',
        subtitle: 'No status changes recorded yet.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final h = history[i];
        final color = AppColors.statusColor(h.status ?? '');
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                if (i < history.length - 1)
                  Container(width: 2, height: 60, color: AppColors.cardBorder),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppConstants.statusLabel(h.status ?? ''),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: color)),
                      if (h.note != null) ...[
                        const SizedBox(height: 4),
                        Text(h.note!,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        h.changedAt != null
                            ? h.changedAt!.formatBDT('dd MMM yyyy, hh:mm a')
                            : '',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: (i * 60).ms);
      },
    );
  }
}
