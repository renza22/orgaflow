import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../domain/models/user_profile_detail_model.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepository {
  ProfileRepository({
    ProfileRemoteDatasource? remoteDatasource,
    SessionService? sessionServiceOverride,
  })  : _remoteDatasource = remoteDatasource ?? ProfileRemoteDatasource(),
        _sessionService = sessionServiceOverride ?? sessionService;

  final ProfileRemoteDatasource _remoteDatasource;
  final SessionService _sessionService;

  Future<Result<UserProfileDetailModel>> fetchProfileDetail(
    String memberId,
  ) async {
    try {
      final profile = await _remoteDatasource.fetchProfileDetail(memberId);
      if (profile == null) {
        return Result<UserProfileDetailModel>.failure(
          const AppError('Profile anggota tidak ditemukan.'),
        );
      }

      return Result<UserProfileDetailModel>.success(profile);
    } catch (error) {
      return Result<UserProfileDetailModel>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> updateProfile({
    required String profileId,
    required String fullName,
    required String? nim,
    required String? bio,
    String? studyProgramCode,
  }) async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);
      if (context == null || context.userId != profileId) {
        return Result<void>.failure(
          const AppError('Anda hanya dapat mengubah profile sendiri.'),
        );
      }

      await _remoteDatasource.updateProfile(
        profileId: profileId,
        fullName: fullName,
        nim: nim,
        bio: bio,
        studyProgramCode: studyProgramCode,
      );
      await _sessionService.clearCache();
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<void>> updateWeeklyCapacity({
    required String memberId,
    required int weeklyCapacityHours,
  }) async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);
      if (context == null || context.activeMember?.id != memberId) {
        return Result<void>.failure(
          const AppError('Anda hanya dapat mengubah kapasitas sendiri.'),
        );
      }

      await _remoteDatasource.updateWeeklyCapacity(
        memberId: memberId,
        weeklyCapacityHours: weeklyCapacityHours,
      );
      await _sessionService.clearCache();
      return Result<void>.success(null);
    } catch (error) {
      return Result<void>.failure(ErrorMapper.map(error));
    }
  }

  Future<Result<String>> uploadProfileAvatar({
    required String profileId,
    required XFile imageFile,
    String? existingAvatarPath,
  }) async {
    try {
      final context = await _sessionService.getCurrentContext(refresh: true);
      if (context == null || context.userId != profileId) {
        return Result<String>.failure(
          const AppError('Anda hanya dapat mengubah foto profile sendiri.'),
        );
      }

      final avatarPath = await _remoteDatasource.uploadProfileAvatar(
        profileId: profileId,
        imageFile: imageFile,
        existingAvatarPath: existingAvatarPath,
      );
      await _sessionService.clearCache();
      return Result<String>.success(avatarPath);
    } catch (error) {
      return Result<String>.failure(ErrorMapper.map(error));
    }
  }
}
