import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/create_organization_input.dart';
import '../../domain/models/join_organization_input.dart';
import '../../domain/models/organization_membership_result.dart';
import '../../domain/models/organization_settings_model.dart';
import '../../domain/models/update_organization_settings_input.dart';
import '../datasources/organization_remote_datasource.dart';

class OrganizationRepository {
  OrganizationRepository({
    OrganizationRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? OrganizationRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final OrganizationRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<List<MasterOption>>> fetchOrganizationTypes() async {
    try {
      final items = await _remoteDatasource.fetchOrganizationTypes();
      return Result<List<MasterOption>>.success(items);
    } catch (error) {
      return Result<List<MasterOption>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<OrganizationSettingsModel>> fetchOrganizationSettings(
    String organizationId,
  ) async {
    try {
      final settings =
          await _remoteDatasource.fetchOrganizationSettings(organizationId);
      return Result<OrganizationSettingsModel>.success(settings);
    } catch (error) {
      return Result<OrganizationSettingsModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<OrganizationSettingsModel>> updateOrganizationSettings(
    UpdateOrganizationSettingsInput input,
  ) async {
    try {
      final settings =
          await _remoteDatasource.updateOrganizationSettings(input);
      await _sessionService.clearCache();
      return Result<OrganizationSettingsModel>.success(settings);
    } catch (error) {
      return Result<OrganizationSettingsModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<List<String>>> fetchActiveSkillNames() async {
    try {
      final items = await _remoteDatasource.fetchActiveSkillNames();
      return Result<List<String>>.success(items);
    } catch (error) {
      return Result<List<String>>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<OrganizationMembershipResult>> createOrganization(
    CreateOrganizationInput input,
  ) async {
    try {
      final result = await _remoteDatasource.createOrganizationWithOwner(input);
      await _sessionService.clearCache();
      return Result<OrganizationMembershipResult>.success(result);
    } catch (error) {
      return Result<OrganizationMembershipResult>.failure(
        ErrorMapper.map(error),
      );
    }
  }

  Future<Result<OrganizationMembershipResult>> joinOrganization(
    JoinOrganizationInput input,
  ) async {
    try {
      final result =
          await _remoteDatasource.joinOrganizationByInviteCode(input);
      await _sessionService.clearCache();
      return Result<OrganizationMembershipResult>.success(result);
    } catch (error) {
      return Result<OrganizationMembershipResult>.failure(
        ErrorMapper.map(error),
      );
    }
  }

  Future<Result<String>> uploadOrganizationLogo({
    required String organizationId,
    String? existingLogoPath,
    required XFile imageFile,
  }) async {
    try {
      final logoPath = await _remoteDatasource.uploadOrganizationLogo(
        organizationId: organizationId,
        existingLogoPath: existingLogoPath,
        imageFile: imageFile,
      );
      await _sessionService.clearCache();
      return Result<String>.success(logoPath);
    } catch (error) {
      return Result<String>.failure(ErrorMapper.map(error));
    }
  }
}
