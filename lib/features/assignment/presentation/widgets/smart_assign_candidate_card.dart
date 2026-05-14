import 'package:flutter/material.dart';

import '../../domain/models/smart_assign_recommendation_model.dart';

class SmartAssignCandidateCard extends StatelessWidget {
  const SmartAssignCandidateCard({
    super.key,
    required this.recommendation,
    required this.isAssigning,
    required this.isDisabled,
    required this.onAssign,
  });

  final SmartAssignRecommendationModel recommendation;
  final bool isAssigning;
  final bool isDisabled;
  final VoidCallback? onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertColors = _alertColors(recommendation.preemptiveAlertLevel);
    final isTopPick = recommendation.recommendationRank == 1;
    final meta = [
      recommendation.displayPosition,
      recommendation.displayDivision,
    ].where((item) => item.trim().isNotEmpty).join(' - ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTopPick ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTopPick ? const Color(0xFF14B8A6) : Colors.grey.shade200,
          width: isTopPick ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRankBadge(),
                const SizedBox(width: 12),
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.fullName.trim().isNotEmpty
                            ? recommendation.fullName.trim()
                            : 'Tanpa Nama',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${recommendation.totalScore}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                    Text(
                      'Total score',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildScoreBreakdown(),
            const SizedBox(height: 12),
            Text(
              recommendation.recommendationReason,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            _buildWorkloadSection(alertColors),
            if (recommendation.matchedSkills.isNotEmpty ||
                recommendation.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildSkillSection(),
            ],
            const SizedBox(height: 14),
            _buildAlertSection(alertColors),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isDisabled ? null : onAssign,
                icon: isAssigning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add_alt_1, size: 16),
                label: Text(isAssigning ? 'Assigning...' : 'Assign'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    final rank = recommendation.recommendationRank > 0
        ? recommendation.recommendationRank
        : 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Rank #$rank',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
        ),
      ),
      child: Center(
        child: Text(
          _initials(recommendation.fullName),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF6C5CE7),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildScoreChip('Skill', recommendation.skillScore),
        _buildScoreChip('Capacity', recommendation.capacityScore),
        _buildScoreChip('Fairness', recommendation.fairnessScore),
      ],
    );
  }

  Widget _buildScoreChip(String label, int score) {
    final color = score < 0 ? Colors.red.shade700 : const Color(0xFF047857);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label $score',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWorkloadSection(_AlertColors alertColors) {
    final projectedValue = recommendation.projectedLoadRatio.isFinite
        ? recommendation.projectedLoadRatio.clamp(0.0, 1.0).toDouble()
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWorkloadRow(
          'Current workload',
          recommendation.currentAssignedHours,
          recommendation.currentLoadLabel,
        ),
        const SizedBox(height: 8),
        _buildWorkloadRow(
          'Projected workload',
          recommendation.projectedAssignedHours,
          recommendation.projectedLoadLabel,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: projectedValue,
            minHeight: 7,
            backgroundColor: Colors.grey.shade200,
            color: alertColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadRow(String label, int hours, String percentLabel) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          '$hours / ${recommendation.weeklyCapacityHours} jam',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          percentLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (recommendation.matchedSkills.isNotEmpty)
          _buildSkillChips(
            'Matched skills',
            recommendation.matchedSkills,
            const Color(0xFF0F766E),
            const Color(0xFFCCFBF1),
          ),
        if (recommendation.matchedSkills.isNotEmpty &&
            recommendation.missingSkills.isNotEmpty)
          const SizedBox(height: 10),
        if (recommendation.missingSkills.isNotEmpty)
          _buildSkillChips(
            'Missing skills',
            recommendation.missingSkills,
            const Color(0xFF92400E),
            const Color(0xFFFEF3C7),
          ),
      ],
    );
  }

  Widget _buildSkillChips(
    String label,
    List<String> skills,
    Color textColor,
    Color backgroundColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills
              .map(
                (skill) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAlertSection(_AlertColors alertColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: alertColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: alertColors.badgeBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              recommendation.alertLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: alertColors.text,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.preemptiveAlertMessage,
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: alertColors.text,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  _AlertColors _alertColors(String level) {
    switch (level.toLowerCase()) {
      case 'safe':
        return const _AlertColors(
          background: Color(0xFFECFDF5),
          badgeBackground: Color(0xFFD1FAE5),
          border: Color(0xFFA7F3D0),
          text: Color(0xFF047857),
        );
      case 'warning':
        return const _AlertColors(
          background: Color(0xFFFFFBEB),
          badgeBackground: Color(0xFFFEF3C7),
          border: Color(0xFFFDE68A),
          text: Color(0xFFB45309),
        );
      case 'critical':
        return const _AlertColors(
          background: Color(0xFFFEF2F2),
          badgeBackground: Color(0xFFFEE2E2),
          border: Color(0xFFFCA5A5),
          text: Color(0xFFB91C1C),
        );
      case 'overload':
        return const _AlertColors(
          background: Color(0xFFFFF1F2),
          badgeBackground: Color(0xFFFFCDD2),
          border: Color(0xFF991B1B),
          text: Color(0xFF7F1D1D),
        );
      case 'no_capacity':
        return const _AlertColors(
          background: Color(0xFFF3F4F6),
          badgeBackground: Color(0xFFE5E7EB),
          border: Color(0xFFD1D5DB),
          text: Color(0xFF4B5563),
        );
      default:
        return const _AlertColors(
          background: Color(0xFFECFDF5),
          badgeBackground: Color(0xFFD1FAE5),
          border: Color(0xFFA7F3D0),
          text: Color(0xFF047857),
        );
    }
  }
}

class _AlertColors {
  const _AlertColors({
    required this.background,
    required this.badgeBackground,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color badgeBackground;
  final Color border;
  final Color text;
}
