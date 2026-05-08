import '../../../../core/result/result.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../data/repositories/organization_repository.dart';
import '../../domain/models/create_organization_input.dart';
import '../../domain/models/join_organization_input.dart';
import '../../domain/models/organization_membership_result.dart';
import '../../domain/models/organization_settings_model.dart';
import '../../domain/models/update_organization_settings_input.dart';

class OrganizationPresenter {
  OrganizationPresenter({
    OrganizationRepository? repository,
  }) : _repository = repository ?? OrganizationRepository();

  final OrganizationRepository _repository;

  Future<Result<List<MasterOption>>> loadOrganizationTypes() {
    return _repository.fetchOrganizationTypes();
  }

  Future<Result<OrganizationSettingsModel>> loadOrganizationSettings(
    String organizationId,
  ) {
    return _repository.fetchOrganizationSettings(organizationId);
  }

  Future<Result<OrganizationSettingsModel>> updateOrganizationSettings(
    UpdateOrganizationSettingsInput input,
  ) {
    return _repository.updateOrganizationSettings(input);
  }

  Future<Result<List<String>>> loadActiveSkillNames() {
    return _repository.fetchActiveSkillNames();
  }

  Future<Result<OrganizationMembershipResult>> createOrganization(
    CreateOrganizationInput input,
  ) {
    return _repository.createOrganization(input);
  }

  Future<Result<OrganizationMembershipResult>> joinOrganization(
    JoinOrganizationInput input,
  ) {
    return _repository.joinOrganization(input);
  }
}
