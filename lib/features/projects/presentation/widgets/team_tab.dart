import 'package:flutter/material.dart';

class TeamMember {
  final String name;
  final String role;
  final String initials;
  final Color avatarColor;
  final int tasksAssigned;
  final int tasksCompleted;

  TeamMember({
    required this.name,
    required this.role,
    required this.initials,
    required this.avatarColor,
    required this.tasksAssigned,
    required this.tasksCompleted,
  });
}

class TeamTab extends StatelessWidget {
  const TeamTab({super.key});

  List<TeamMember> get _members => [
        TeamMember(name: 'Sarah Chen', role: 'Project Lead', initials: 'SC',
            avatarColor: const Color(0xFF6C5CE7), tasksAssigned: 5, tasksCompleted: 3),
        TeamMember(name: 'Ahmad Rizki', role: 'Designer', initials: 'AR',
            avatarColor: const Color(0xFF00CEC9), tasksAssigned: 4, tasksCompleted: 2),
        TeamMember(name: 'Maya Putri', role: 'Content Writer', initials: 'MP',
            avatarColor: const Color(0xFFFF7675), tasksAssigned: 6, tasksCompleted: 5),
        TeamMember(name: 'Mike Johnson', role: 'Event Coordinator', initials: 'MJ',
            avatarColor: const Color(0xFF00B894), tasksAssigned: 3, tasksCompleted: 3),
        TeamMember(name: 'David Lee', role: 'Logistics', initials: 'DL',
            avatarColor: const Color(0xFF0984E3), tasksAssigned: 4, tasksCompleted: 1),
        TeamMember(name: 'Siti Nurhaliza', role: 'Marketing', initials: 'SN',
            avatarColor: const Color(0xFFFDAA5C), tasksAssigned: 3, tasksCompleted: 2),
        TeamMember(name: 'Emma Davis', role: 'MC Coordinator', initials: 'ED',
            avatarColor: const Color(0xFFE17055), tasksAssigned: 2, tasksCompleted: 1),
      ];

  @override
  Widget build(BuildContext context) {
    final members = _members;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Row(
            children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Anggota Proyek', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                  SizedBox(height: 4),
                  Text('Kelola tim yang terlibat dalam proyek ini', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                ]),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah Anggota'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Summary cards
          _buildSummaryRow(members),
          const SizedBox(height: 24),
          // Members list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(children: [
                    const Expanded(flex: 3, child: Text('Anggota', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                    const Expanded(flex: 2, child: Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                    const Expanded(child: Text('Tasks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                    const Expanded(child: Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
                    const SizedBox(width: 40),
                  ]),
                ),
                ...members.map((m) => _buildMemberRow(m, context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(List<TeamMember> members) {
    final totalTasks = members.fold<int>(0, (s, m) => s + m.tasksAssigned);
    final completedTasks = members.fold<int>(0, (s, m) => s + m.tasksCompleted);
    return Row(children: [
      Expanded(child: _buildMiniStat('Total Anggota', '${members.length}', Icons.people, const Color(0xFF6C5CE7))),
      const SizedBox(width: 12),
      Expanded(child: _buildMiniStat('Total Tasks', '$totalTasks', Icons.task_alt, const Color(0xFF00CEC9))),
      const SizedBox(width: 12),
      Expanded(child: _buildMiniStat('Selesai', '$completedTasks', Icons.check_circle, const Color(0xFF00B894))),
    ]);
  }

  Widget _buildMiniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ]),
      ]),
    );
  }

  Widget _buildMemberRow(TeamMember member, BuildContext context) {
    final progress = member.tasksAssigned > 0 ? member.tasksCompleted / member.tasksAssigned : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: member.avatarColor.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text(member.initials,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: member.avatarColor))),
            ),
            const SizedBox(width: 12),
            Text(member.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: member.avatarColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(member.role, style: TextStyle(fontSize: 12, color: member.avatarColor, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
          ),
        ),
        Expanded(
          child: Text('${member.tasksCompleted}/${member.tasksAssigned}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? const Color(0xFF00B894) : const Color(0xFF6C5CE7)),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('Lihat Profil')),
            const PopupMenuItem(value: 'remove', child: Text('Hapus dari Proyek', style: TextStyle(color: Colors.red))),
          ],
        ),
      ]),
    );
  }
}
