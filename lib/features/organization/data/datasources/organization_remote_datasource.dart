import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/supabase_config.dart';
import '../../../../core/utils/invite_code_utils.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/create_organization_input.dart';
import '../../domain/models/join_organization_input.dart';
import '../../domain/models/organization_membership_result.dart';

class OrganizationRemoteDatasource {
  OrganizationRemoteDatasource({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  static const String _organizationLogosBucket = 'organization-logos';
  static const Set<String> _allowedLogoExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  final SupabaseClient _client;

  Future<List<MasterOption>> fetchOrganizationTypes() async {
    final response = await _client
        .from('organization_types')
        .select('code, label')
        .eq('is_active', true)
        .order('sort_order', ascending: true);

    return (response as List<dynamic>)
        .map((json) => MasterOption.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<OrganizationMembershipResult> createOrganizationWithOwner(
    CreateOrganizationInput input,
  ) async {
    final ownerPositionCode = await _resolveOwnerPositionCode();

    try {
      final response = await _client.rpc(
        'create_organization_with_owner',
        params: {
          'p_name': input.name,
          'p_type_code': input.typeCode,
          'p_position_code': ownerPositionCode,
          'p_division_code': null,
          'p_weekly_capacity_hours': 0,
          'p_availability_status': 'available',
        },
      );

      final row = _extractSingleRow(response);
      return OrganizationMembershipResult(
        organizationId: row['organization_id'] as String,
        memberId: row['member_id'] as String,
        inviteCode: row['invite_code'] as String?,
        role: 'owner',
      );
    } on PostgrestException catch (error) {
      if (!ErrorMapper.isMissingRpc(
        error,
        'create_organization_with_owner',
      )) {
        rethrow;
      }
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppError('User belum login.');
    }

    final inviteCode = await _generateUniqueInviteCode(input.name);
    final organization = await _client
        .from('organizations')
        .insert({
          'name': input.name,
          'type_code': input.typeCode,
          'invite_code': inviteCode,
          'created_by': user.id,
        })
        .select('id, invite_code')
        .single();

    final member = await _client
        .from('members')
        .insert({
          'profile_id': user.id,
          'organization_id': organization['id'],
          'role': 'owner',
          'position_code': ownerPositionCode,
          'division_code': null,
          'weekly_capacity_hours': 0,
          'availability_status': 'available',
          'status': 'active',
        })
        .select('id')
        .single();

    return OrganizationMembershipResult(
      organizationId: organization['id'] as String,
      memberId: member['id'] as String,
      inviteCode: organization['invite_code'] as String?,
      role: 'owner',
    );
  }

  Future<OrganizationMembershipResult> joinOrganizationByInviteCode(
    JoinOrganizationInput input,
  ) async {
    final normalizedInviteCode = InviteCodeUtils.normalize(input.inviteCode);
    if (!InviteCodeUtils.isValid(normalizedInviteCode)) {
      throw const AppError(
        'Format kode organisasi tidak valid. Contoh: HMTI-2026-ABC1',
      );
    }

    try {
      final response = await _client.rpc(
        'join_organization_by_invite_code',
        params: {
          'p_invite_code': normalizedInviteCode,
          'p_position_code': null,
          'p_division_code': null,
          'p_weekly_capacity_hours': 0,
          'p_availability_status': 'available',
        },
      );

      final row = _extractSingleRow(response);
      return OrganizationMembershipResult(
        organizationId: row['organization_id'] as String,
        memberId: row['member_id'] as String,
        role: row['role'] as String?,
      );
    } on PostgrestException catch (error) {
      if (!ErrorMapper.isMissingRpc(
        error,
        'join_organization_by_invite_code',
      )) {
        rethrow;
      }
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AppError('User belum login.');
    }

    final organization = await _client
        .from('organizations')
        .select('id')
        .eq('invite_code', normalizedInviteCode)
        .eq('is_active', true)
        .maybeSingle();

    if (organization == null) {
      throw const AppError(
        'Kode organisasi tidak ditemukan atau join organization belum siap di server ini.',
      );
    }

    final existingMember = await _client
        .from('members')
        .select('id, role')
        .eq('profile_id', user.id)
        .eq('organization_id', organization['id'])
        .maybeSingle();

    if (existingMember != null) {
      await _client.from('members').update({
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existingMember['id']);

      return OrganizationMembershipResult(
        organizationId: organization['id'] as String,
        memberId: existingMember['id'] as String,
        role: existingMember['role'] as String?,
      );
    }

    final member = await _client
        .from('members')
        .insert({
          'profile_id': user.id,
          'organization_id': organization['id'],
          'role': 'member',
          'weekly_capacity_hours': 0,
          'availability_status': 'available',
          'status': 'active',
        })
        .select('id, role')
        .single();

    return OrganizationMembershipResult(
      organizationId: organization['id'] as String,
      memberId: member['id'] as String,
      role: member['role'] as String?,
    );
  }

  Future<String> uploadOrganizationLogo({
    required String organizationId,
    String? existingLogoPath,
    required XFile imageFile,
  }) async {
    final normalizedExistingLogoPath = _normalizeStoragePath(existingLogoPath);
    final extension = _resolveLogoExtension(imageFile);
    final uploadedAt = DateTime.now();
    final newLogoPath =
        '$organizationId/logo_${uploadedAt.millisecondsSinceEpoch}.$extension';
    final bytes = await _readImageBytes(imageFile);

    if (bytes.isEmpty) {
      throw const AppError('File gambar tidak valid.');
    }

    try {
      await _client.storage.from(_organizationLogosBucket).uploadBinary(
            newLogoPath,
            bytes,
            fileOptions: FileOptions(
              contentType: _mimeTypeForExtension(extension),
            ),
          );
    } catch (error) {
      throw AppError(
        'Gagal mengunggah logo organisasi.',
        cause: error,
      );
    }

    try {
      await _client
          .from('organizations')
          .update({
            'logo_path': newLogoPath,
            'updated_at': uploadedAt.toUtc().toIso8601String(),
          })
          .eq('id', organizationId)
          .select('id')
          .single();
    } catch (error) {
      await _deleteOrganizationLogoBestEffort(newLogoPath);
      rethrow;
    }

    if (normalizedExistingLogoPath != null &&
        normalizedExistingLogoPath != newLogoPath) {
      await _deleteOrganizationLogoBestEffort(normalizedExistingLogoPath);
    }

    return newLogoPath;
  }

  Future<String> _resolveOwnerPositionCode() async {
    final byCode = await _client
        .from('position_templates')
        .select('code')
        .eq('code', 'ketua_umum')
        .eq('is_active', true)
        .maybeSingle();

    if (byCode != null) {
      return byCode['code'] as String;
    }

    final byLabel = await _client
        .from('position_templates')
        .select('code')
        .ilike('label', 'Ketua Umum')
        .eq('is_active', true)
        .maybeSingle();

    if (byLabel != null) {
      return byLabel['code'] as String;
    }

    throw const AppError(
      'Master jabatan Ketua Umum tidak ditemukan di database.',
    );
  }

  Future<String> _generateUniqueInviteCode(String organizationName) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final inviteCode = await _client.rpc(
        'generate_invite_code',
        params: {'org_name': organizationName},
      ) as String;

      final existing = await _client
          .from('organizations')
          .select('id')
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (existing == null) {
        return inviteCode;
      }
    }

    throw const AppError(
      'Gagal membuat kode organisasi unik. Silakan coba lagi.',
    );
  }

  Map<String, dynamic> _extractSingleRow(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map<String, dynamic>) {
        return first;
      }
      return Map<String, dynamic>.from(first as Map);
    }

    throw const AppError('Response server tidak valid.');
  }

  String _resolveLogoExtension(XFile imageFile) {
    final fileName =
        imageFile.name.trim().isNotEmpty ? imageFile.name : imageFile.path;
    final extension = _extractFileExtension(fileName) ?? 'png';

    if (!_allowedLogoExtensions.contains(extension)) {
      throw const AppError(
        'Format gambar tidak didukung. Gunakan JPG, JPEG, PNG, atau WEBP.',
      );
    }

    return extension;
  }

  String? _extractFileExtension(String fileName) {
    final normalizedName = fileName.split('/').last.split('\\').last;
    final separatorIndex = normalizedName.lastIndexOf('.');

    if (separatorIndex < 0 || separatorIndex == normalizedName.length - 1) {
      return null;
    }

    return normalizedName.substring(separatorIndex + 1).toLowerCase();
  }

  String? _normalizeStoragePath(String? path) {
    final normalized = path?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String _mimeTypeForExtension(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/png';
    }
  }

  Future<void> _deleteOrganizationLogoBestEffort(String path) async {
    try {
      await _client.storage.from(_organizationLogosBucket).remove([path]);
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  Future<Uint8List> _readImageBytes(XFile imageFile) async {
    try {
      return await imageFile.readAsBytes();
    } catch (error) {
      throw AppError(
        'Gagal membaca file gambar.',
        cause: error,
      );
    }
  }
}
