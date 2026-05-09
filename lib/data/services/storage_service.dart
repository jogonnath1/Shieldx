import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  String _ext(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '.jpg';
  }

  Future<String> uploadEvidence(File file, String complaintId) async {
    final ext = _ext(file.path);
    final fileName = '$complaintId/${_uuid.v4()}$ext';
    await _client.storage.from('evidence').upload(fileName, file);
    return _client.storage.from('evidence').getPublicUrl(fileName);
  }

  Future<String> uploadAvatar(File file, String userId) async {
    final ext = _ext(file.path);
    final fileName = '$userId/avatar$ext';
    await _client.storage
        .from('avatars')
        .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('avatars').getPublicUrl(fileName);
  }

  Future<void> deleteFile(String bucket, String filePath) async {
    await _client.storage.from(bucket).remove([filePath]);
  }
}
