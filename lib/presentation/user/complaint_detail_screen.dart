import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_extensions.dart';
import '../../data/services/complaint_service.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/status_history_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../widgets/common/widgets.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  ConsumerState<ComplaintDetailScreen> createState() =>
      _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState
    extends ConsumerState<ComplaintDetailScreen> {
  ComplaintModel? _complaint;
  List<StatusHistoryModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ComplaintService();
    ComplaintModel? c;
    List<StatusHistoryModel> h = [];

    final isOnline = ref.read(connectivityProvider);
    if (isOnline) {
      try {
        c = await service.getComplaint(widget.complaintId);
        h = await service.getStatusHistory(widget.complaintId);
      } catch (e) {
        debugPrint('Error loading online details: $e');
      }
    }

    if (mounted) {
      setState(() {
        _complaint = c;
        _history = h;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadAsync = _complaint != null
        ? ref.watch(unreadMessagesCountProvider(_complaint!.id))
        : const AsyncValue<int>.data(0);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Case #${_complaint?.caseId ?? '...'}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/my-complaints'),
        ),
        actions: [
          if (_complaint != null && _complaint!.status == 'submitted')
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
              tooltip: 'Edit Report',
              onPressed: () => context.push('/complaint/${_complaint!.id}/edit'),
            ),
          if (_complaint != null)
            IconButton(
              icon: Badge(
                label: Text('$unreadCount'),
                isLabelVisible: unreadCount > 0,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              onPressed: () => context.push('/chat/${_complaint!.id}'),
            ),
        ],
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
                    subtitle: 'This report could not be loaded.')
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Card
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _complaint!.crimeCategory ?? 'Complaint',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  StatusBadge(status: _complaint!.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Submitted on ${_complaint!.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(_complaint!.createdAt!.toBangladeshTime()) : 'Unknown'}',
                                style: GoogleFonts.inter(
                                    color: AppColors.textHint, fontSize: 12),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 16),

                        // Description
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text(_complaint!.description ?? 'No description',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                      height: 1.6)),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),

                        // Details
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Details',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              if (_complaint!.locationAddress != null)
                                InfoTile(
                                  icon: Icons.place_outlined,
                                  label: 'Location',
                                  value: _complaint!.locationAddress!,
                                ),
                              if (_complaint!.incidentDatetime != null)
                                InfoTile(
                                  icon: Icons.event_outlined,
                                  label: 'Incident Date & Time',
                                  value: DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(_complaint!.incidentDatetime!.toBangladeshTime()),
                                ),
                              InfoTile(
                                icon: Icons.person_outline,
                                label: 'Complainant',
                                value: _complaint!.fullName,
                              ),
                              if (_complaint!.phone != null && !_complaint!.isAnonymous)
                                InfoTile(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value: _complaint!.phone!,
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),

                        // Status Timeline
                        if (_history.isNotEmpty) ...[
                          Text('Status Timeline',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          ...List.generate(_history.length, (i) {
                            final h = _history[i];
                            return _TimelineItem(
                              history: h,
                              isLast: i == _history.length - 1,
                            ).animate().fadeIn(delay: (300 + i * 80).ms);
                          }),
                        ],

                        const SizedBox(height: 24),
                        GradientButton(
                          label: unreadCount > 0
                              ? 'Open Chat ($unreadCount New)'
                              : 'Open Chat',
                          icon: Icons.chat_rounded,
                          onTap: () =>
                              context.push('/chat/${_complaint!.id}'),
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final StatusHistoryModel history;
  final bool isLast;

  const _TimelineItem({required this.history, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(history.status ?? '');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: AppColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.statusLabel(history.status ?? ''),
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: color)),
                if (history.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(history.note!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ),
                const SizedBox(height: 4),
                Text(
                  history.changedAt != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(history.changedAt!.toBangladeshTime())
                      : '',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
