import '../../../../core/errors/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/nim_validator.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../domain/models/master_option.dart';
import '../../domain/models/onboarding_initial_data.dart';
import '../../domain/models/onboarding_submission.dart';
import '../../domain/models/portfolio_link_input.dart';
import '../../domain/models/selected_skill_input.dart';

class OnboardingPresenter {
  OnboardingPresenter({
    OnboardingRepository? repository,
  }) : _repository = repository ?? OnboardingRepository();

  final OnboardingRepository _repository;

  Future<Result<OnboardingInitialData>> loadInitialData() {
    return _repository.loadInitialData();
  }

  String? labelForCode(List<MasterOption> options, String? code) {
    if (code == null) {
      return null;
    }

    for (final option in options) {
      if (option.code == code) {
        return option.label;
      }
    }

    return null;
  }

  String? codeForLabel(List<MasterOption> options, String? label) {
    if (label == null) {
      return null;
    }

    for (final option in options) {
      if (option.label == label) {
        return option.code;
      }
    }

    return null;
  }

  bool isOwnerLocked(OnboardingInitialData initialData) {
    return initialData.member.isOwner;
  }

  Map<String, Map<String, String>> buildSelectedSkills(
    OnboardingInitialData initialData,
  ) {
    final selections = <String, Map<String, String>>{};

    for (final item in initialData.skills) {
      final skill = initialData.masterData.skills.firstWhereOrNull(
        (entry) => entry.id == item.skillId,
      );

      if (skill == null) {
        continue;
      }

      final category = initialData.masterData.skillCategories.firstWhereOrNull(
        (entry) => entry.code == skill.categoryCode,
      );

      if (category == null) {
        continue;
      }

      selections.putIfAbsent(category.label, () => <String, String>{});
      selections[category.label]![skill.name] =
          _mapLevelToProficiency(item.proficiencyLevel);
    }

    return selections;
  }

  List<PortfolioLinkInput> buildPortfolioDrafts(
    OnboardingInitialData initialData,
  ) {
    return initialData.portfolioLinks;
  }

  Future<Result<void>> submit({
    required OnboardingInitialData initialData,
    required String fullName,
    required String nim,
    required String? studyProgramLabel,
    required String? positionLabel,
    required String? divisionLabel,
    required int weeklyCapacityHours,
    required bool isAvailable,
    required String bio,
    required List<PortfolioLinkInput> portfolioLinks,
    required Map<String, Map<String, String>> selectedSkills,
    String? avatarPath,
  }) async {
    final studyProgramCode = codeForLabel(
      initialData.masterData.studyPrograms,
      studyProgramLabel,
    );
    final nimError = NimValidator.validate(nim);

    final isOwner = isOwnerLocked(initialData);
    final positionCode = isOwner
        ? initialData.member.positionCode ?? 'ketua_umum'
        : codeForLabel(initialData.masterData.positions, positionLabel);
    final divisionCode = isOwner
        ? initialData.member.divisionCode
        : codeForLabel(initialData.masterData.divisions, divisionLabel);

    if (studyProgramCode == null) {
      return Result<void>.failure(
        const AppError('Program studi wajib dipilih.'),
      );
    }

    if (!isOwner && positionCode == null) {
      return Result<void>.failure(
        const AppError('Jabatan wajib dipilih.'),
      );
    }

    if (!isOwner && divisionCode == null) {
      return Result<void>.failure(
        const AppError('Divisi wajib dipilih.'),
      );
    }

    if (nimError != null) {
      return Result<void>.failure(
        AppError(nimError),
      );
    }

    final mappedPortfolioLinks = <PortfolioLinkInput>[];
    for (var index = 0; index < portfolioLinks.length; index++) {
      final item = portfolioLinks[index];
      final platformCode = codeForLabel(
        initialData.masterData.portfolioPlatforms,
        item.platformCode,
      );

      if (platformCode == null || item.url.trim().isEmpty) {
        continue;
      }

      mappedPortfolioLinks.add(
        PortfolioLinkInput(
          platformCode: platformCode,
          url: item.url.trim(),
          sortOrder: index,
        ),
      );
    }

    final mappedSkills = <SelectedSkillInput>[];
    for (final categoryEntry in selectedSkills.entries) {
      for (final skillEntry in categoryEntry.value.entries) {
        final skill = initialData.masterData.findSkillByName(skillEntry.key);
        if (skill == null) {
          continue;
        }

        mappedSkills.add(
          SelectedSkillInput(
            skillId: skill.id,
            proficiencyLevel: _mapProficiencyToLevel(skillEntry.value),
          ),
        );
      }
    }

    final submission = OnboardingSubmission(
      fullName: fullName.trim(),
      nim: NimValidator.normalize(nim),
      studyProgramCode: studyProgramCode,
      bio: bio.trim(),
      avatarPath: avatarPath,
      positionCode: positionCode,
      divisionCode: divisionCode,
      weeklyCapacityHours: weeklyCapacityHours,
      availabilityStatus: isAvailable ? 'available' : 'unavailable',
      portfolioLinks: mappedPortfolioLinks,
      skills: mappedSkills,
    );

    return _repository.submitOnboarding(submission);
  }

  int _mapProficiencyToLevel(String proficiency) {
    // UI lama memakai 3 level string, lalu dikonversi ke skala database 1..5.
    switch (proficiency) {
      case 'beginner':
        return 2;
      case 'intermediate':
        return 3;
      case 'expert':
        return 5;
      default:
        return 3;
    }
  }

  String _mapLevelToProficiency(int level) {
    if (level >= 5) {
      return 'expert';
    }

    if (level >= 3) {
      return 'intermediate';
    }

    return 'beginner';
  }
}

extension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) predicate) {
    for (final item in this) {
      if (predicate(item)) {
        return item;
      }
    }

    return null;
  }
}
