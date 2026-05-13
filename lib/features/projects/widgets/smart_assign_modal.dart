import 'package:flutter/material.dart';
import '../models/member_recommendation_model.dart';

class SmartAssignModal extends StatelessWidget {
  final List<String> requiredSkills;
  final String taskTitle;
  final double estimatedHours;
  final Function(String memberName, int memberId) onAssign;

  const SmartAssignModal({
    super.key,
    required this.requiredSkills,
    this.taskTitle = '',
    this.estimatedHours = 0,
    required this.onAssign,
  });

  // Mock data - in production, this would come from API
  List<MemberRecommendation> _getRecommendations() {
    return [
      MemberRecommendation(
        id: 1,
        name: "Mike Johnson",
        role: "Lead Designer",
        avatarUrl: "",
        matchScore: 91,
        reason: "Semua skill cocok & beban rendah",
        capacityUsed: 8,
        capacityMax: 35,
        matchingSkills: ["Logistik"],
      ),
      MemberRecommendation(
        id: 2,
        name: "Alex Rodriguez",
        role: "Senior Developer",
        avatarUrl: "",
        matchScore: 35,
        reason: "Kapasitas tersedia",
        capacityUsed: 5,
        capacityMax: 40,
        matchingSkills: [],
      ),
      MemberRecommendation(
        id: 3,
        name: "Sarah Chen",
        role: "DevOps Engineer",
        avatarUrl: "",
        matchScore: 28,
        reason: "Kapasitas tersedia",
        capacityUsed: 12,
        capacityMax: 40,
        matchingSkills: [],
      ),
      MemberRecommendation(
        id: 4,
        name: "Emma Davis",
        role: "Product Manager",
        avatarUrl: "",
        matchScore: 20,
        reason: "Kapasitas tersedia",
        capacityUsed: 25,
        capacityMax: 35,
        matchingSkills: [],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final recommendations = _getRecommendations();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isSmallScreen ? screenWidth - 32 : 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Smart Assign',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            children: [
                              const TextSpan(text: 'Rekomendasi anggota terbaik untuk: '),
                              TextSpan(
                                text: taskTitle.isNotEmpty ? taskTitle : 'Task',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Skills & Estimasi Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill yang dibutuhkan:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (requiredSkills.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: requiredSkills.map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00CEC9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  skill,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            'Tidak ada skill spesifik',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (estimatedHours > 0) ...[
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          '${estimatedHours.toInt()}h',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Recommendations Title
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              alignment: Alignment.centerLeft,
              child: Text(
                'Rekomendasi Anggota',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ),

            // Recommendations List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final member = recommendations[index];
                  final isTopPick = index == 0;
                  return _buildRecommendationCard(
                    context,
                    member,
                    isTopPick,
                    isSmallScreen,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    MemberRecommendation member,
    bool isTopPick,
    bool isSmallScreen,
  ) {
    final statusColor = member.loadRatio >= 90
        ? Colors.red
        : member.loadRatio >= 75
            ? Colors.orange
            : const Color(0xFF00B894);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isTopPick ? const Color(0xFFE8F5F4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTopPick
              ? const Color(0xFF00B894)
              : Colors.grey.shade200,
          width: isTopPick ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onAssign(member.name, member.id);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: isSmallScreen ? 48 : 56,
                          height: isSmallScreen ? 48 : 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              member.initials,
                              style: TextStyle(
                                color: const Color(0xFF6C5CE7),
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (isTopPick)
                          Positioned(
                            top: -2,
                            left: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Top Pick',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.reason,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Match Score
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${member.matchScore.toInt()}%',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          'Match Score',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Matching Skills
                if (member.matchingSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill cocok:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: member.matchingSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00CEC9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Capacity Bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Beban Kerja',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${member.capacityUsed}h / ${member.capacityMax}h',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: member.loadRatio / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
