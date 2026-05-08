import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';

class StorageAvatarUrlResolver {
  StorageAvatarUrlResolver({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  static const String bucketName = 'profile-avatars';

  final SupabaseClient _client;

  Future<String?> resolve(
    String? avatarPath, {
    int expiresInSeconds = 3600,
  }) async {
    final path = avatarPath?.trim();
    if (path == null || path.isEmpty) {
      return null;
    }

    try {
      return await _client.storage
          .from(bucketName)
          .createSignedUrl(path, expiresInSeconds);
    } catch (error) {
      debugPrint('Failed to create signed profile avatar URL: $error');
      return null;
    }
  }

  Future<Map<String, String>> resolveMany(
    Iterable<String?> avatarPaths, {
    int expiresInSeconds = 3600,
  }) async {
    final uniquePaths = avatarPaths
        .whereType<String>()
        .map((path) => path.trim())
        .where((path) => path.isNotEmpty)
        .toSet();

    final result = <String, String>{};
    for (final path in uniquePaths) {
      final signedUrl = await resolve(
        path,
        expiresInSeconds: expiresInSeconds,
      );
      if (signedUrl != null) {
        result[path] = signedUrl;
      }
    }

    return result;
  }
}
