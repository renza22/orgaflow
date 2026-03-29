class OrganizationMembershipResult {
  const OrganizationMembershipResult({
    required this.organizationId,
    required this.memberId,
    this.inviteCode,
    this.role,
  });

  final String organizationId;
  final String memberId;
  final String? inviteCode;
  final String? role;
}
