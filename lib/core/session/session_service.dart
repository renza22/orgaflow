import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_config.dart';
import '../../features/auth/domain/models/profile_model.dart';
import '../../features/organization/domain/models/member_model.dart';
import '../../features/organization/domain/models/organization_model.dart';
import 'session_context.dart';

class SessionService {
  SessionService({
    SupabaseClient? client,
  }) : _client = client ?? supabase;

  final SupabaseClient _client;

  SessionContext? _cachedContext;
  Future<SessionContext?>? _pendingRequest;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<void> clearCache() async {
    _cachedContext = null;
    _pendingRequest = null;
  }

  Future<SessionContext?> getCurrentContext({
    bool refresh = false,
  }) async {
    if (!refresh && _cachedContext != null) {
      return _cachedContext;
    }

    if (!refresh && _pendingRequest != null) {
      return _pendingRequest;
    }

    final request = _loadContext();
    _pendingRequest = request;

    try {
      final context = await request;
      _cachedContext = context;
      return context;
    } finally {
      _pendingRequest = null;
    }
  }

  Future<AppRouteTarget> resolveTarget({
    bool refresh = false,
  }) async {
    final context = await getCurrentContext(refresh: refresh);

    if (context == null) {
      return AppRouteTarget.auth;
    }

    if (!context.hasActiveMembership) {
      return AppRouteTarget.organization;
    }

    if (!context.onboardingCompleted) {
      return AppRouteTarget.onboarding;
    }

    return AppRouteTarget.dashboard;
  }

  Future<SessionContext?> _loadContext() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profileJson =
        await _client.from('profiles').select().eq('id', user.id).maybeSingle();

    final activeMembersJson = await _client
        .from('members')
        .select()
        .eq('profile_id', user.id)
        .eq('status', 'active')
        .order('updated_at', ascending: false);

    final profile =
        profileJson == null ? null : ProfileModel.fromJson(profileJson);
    final activeMembers = (activeMembersJson as List<dynamic>)
        .map((json) => MemberModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final activeMember = _pickActiveMember(activeMembers);

    OrganizationModel? organization;
    if (activeMember != null) {
      final organizationJson = await _client
          .from('organizations')
          .select()
          .eq('id', activeMember.organizationId)
          .maybeSingle();

      if (organizationJson != null) {
        organization = OrganizationModel.fromJson(organizationJson);
      }
    }

    return SessionContext(
      userId: user.id,
      profile: profile,
      activeMember: activeMember,
      organization: organization,
    );
  }

  MemberModel? _pickActiveMember(List<MemberModel> members) {
    if (members.isEmpty) {
      return null;
    }

    members.sort((left, right) {
      final roleCompare = _rolePriority(left.role).compareTo(
        _rolePriority(right.role),
      );

      if (roleCompare != 0) {
        return roleCompare;
      }

      final leftUpdated = left.updatedAt ?? left.joinedAt ?? DateTime(1970);
      final rightUpdated = right.updatedAt ?? right.joinedAt ?? DateTime(1970);
      return rightUpdated.compareTo(leftUpdated);
    });

    return members.first;
  }

  int _rolePriority(String role) {
    switch (role) {
      case 'owner':
        return 0;
      case 'admin':
        return 1;
      default:
        return 2;
    }
  }
}

final sessionService = SessionService();
