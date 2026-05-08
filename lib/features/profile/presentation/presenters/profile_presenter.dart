import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/nim_validator.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/user_profile_detail_model.dart';

class ProfilePresenter {
  ProfilePresenter({
    ProfileRepository? repository,
  }) : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;

  Future<Result<UserProfileDetailModel>> loadProfileDetail(String memberId) {
    return _repository.fetchProfileDetail(memberId);
  }

  Future<Result<void>> updateProfile({
    required String profileId,
    required String fullName,
    required String? nim,
    required String? bio,
    String? studyProgramCode,
  }) {
    final normalizedName = fullName.trim();
    if (normalizedName.isEmpty) {
      return Future.value(
        Result<void>.failure(const AppError('Nama wajib diisi.')),
      );
    }

    final nimError = NimValidator.validate(nim ?? '', required: false);
    if (nimError != null) {
      return Future.value(Result<void>.failure(AppError(nimError)));
    }

    return _repository.updateProfile(
      profileId: profileId,
      fullName: normalizedName,
      nim: nim == null ? null : NimValidator.normalize(nim),
      bio: bio?.trim(),
      studyProgramCode: studyProgramCode,
    );
  }

  Future<Result<void>> updateWeeklyCapacity({
    required String memberId,
    required int weeklyCapacityHours,
  }) {
    if (weeklyCapacityHours < 0) {
      return Future.value(
        Result<void>.failure(
          const AppError('Kapasitas mingguan tidak boleh negatif.'),
        ),
      );
    }

    return _repository.updateWeeklyCapacity(
      memberId: memberId,
      weeklyCapacityHours: weeklyCapacityHours,
    );
  }

  Future<Result<String>> uploadProfileAvatar({
    required String profileId,
    required XFile imageFile,
    String? existingAvatarPath,
  }) {
    return _repository.uploadProfileAvatar(
      profileId: profileId,
      imageFile: imageFile,
      existingAvatarPath: existingAvatarPath,
    );
  }
}
