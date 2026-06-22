import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();
  String _ext(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '.jpg';
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<String> uploadEvidence(File file, String complaintId) async {
    final ext = _ext(file.path);
    final fileName = '$complaintId/${_uuid.v4()}$ext';
    await _client.storage.from('evidence').upload(fileName, file);
    return _client.storage.from('evidence').getPublicUrl(fileName);
  }

  Future<String> uploadEvidenceBytes({
    required Uint8List bytes,
    required String fileName,
    required String complaintId,
  }) async {
    final ext = _ext(fileName);
    final pathName = '$complaintId/${_uuid.v4()}$ext';
    await _client.storage.from('evidence').uploadBinary(
          pathName,
          bytes,
          fileOptions: FileOptions(
            contentType: _getMimeType(ext),
          ),
        );
    return _client.storage.from('evidence').getPublicUrl(pathName);
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final ext = _ext(file.path);
    final fileName =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
    await _client.storage
        .from('avatars')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('avatars').getPublicUrl(fileName);
  }

  Future<String> uploadAvatarBytes({
    required Uint8List bytes,
    required String userId,
    required String fileName,
  }) async {
    final ext = _ext(fileName);
    final pathName =
        '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
    await _client.storage.from('avatars').uploadBinary(
          pathName,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _getMimeType(ext),
          ),
        );
    return _client.storage.from('avatars').getPublicUrl(pathName);
  }

  Future<void> deleteFile(String bucket, String filePath) async {
    await _client.storage.from(bucket).remove([filePath]);
  }
}
