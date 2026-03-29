import '../../features/auth/domain/models/profile_model.dart';
import '../../features/organization/domain/models/member_model.dart';
import '../../features/organization/domain/models/organization_model.dart';

enum AppRouteTarget {
  auth,
  organization,
  onboarding,
  dashboard,
}

extension AppRouteTargetX on AppRouteTarget {
  String get routeName {
    switch (this) {
      case AppRouteTarget.auth:
        return '/auth';
      case AppRouteTarget.organization:
        return '/organization';
      case AppRouteTarget.onboarding:
        return '/onboarding';
      case AppRouteTarget.dashboard:
        return '/dashboard';
    }
  }
}

class SessionContext {
  const SessionContext({
    required this.userId,
    this.profile,
    this.activeMember,
    this.organization,
  });

  final String userId;
  final ProfileModel? profile;
  final MemberModel? activeMember;
  final OrganizationModel? organization;

  bool get hasActiveMembership => activeMember != null;
  bool get onboardingCompleted => profile?.onboardingCompleted ?? false;
}
