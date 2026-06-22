import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shieldx/common/core/constants/app_colors.dart';

class EvidenceStep extends StatelessWidget {
  final List<XFile> files;
  final Map<String, Uint8List> webBytes;
  final bool isAnonymous;
  final VoidCallback onPickImage;
  final void Function(int) onRemove;
  const EvidenceStep({
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
