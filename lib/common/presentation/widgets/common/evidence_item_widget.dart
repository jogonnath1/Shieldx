import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EvidenceItemWidget extends StatefulWidget {
  final String originalUrl;
  final int index;
  
  const EvidenceItemWidget({
    super.key, 
    required this.originalUrl,
    required this.index,
  });

  @override
  State<EvidenceItemWidget> createState() => _EvidenceItemWidgetState();
}

class _EvidenceItemWidgetState extends State<EvidenceItemWidget> {
  String? _validUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchValidUrl();
  }

  Future<void> _fetchValidUrl() async {
    final url = widget.originalUrl;
    if (url.contains('/object/public/')) {
      try {
        final uri = Uri.parse(url);
        final segments = uri.pathSegments;
        final pubIdx = segments.indexOf('public');
        if (pubIdx != -1 && pubIdx + 2 < segments.length) {
          final bucket = segments[pubIdx + 1];
          final path = segments.sublist(pubIdx + 2).join('/');
          final signedUrl = await Supabase.instance.client.storage
              .from(bucket)
              .createSignedUrl(path, 60 * 60); // 1 hour expiry
          if (mounted) {
            setState(() {
              _validUrl = signedUrl;
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        // Fallback below
      }
    }
    if (mounted) {
      setState(() {
        _validUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final url = _validUrl!;
    final isImage = url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.gif') ||
        url.toLowerCase().contains('.webp');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.broken_image_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Could not load image preview. Please click the link below to view it.',
                            style: TextStyle(color: Colors.red[300], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open evidence link.')));
                }
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attachment_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attachment ${widget.index + 1}',
                      style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, color: AppColors.primary, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
