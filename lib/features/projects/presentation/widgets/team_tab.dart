import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String initials;
  final Color avatarColor;
  final int tasksAssigned;
  final int tasksCompleted;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.initials,
    required this.avatarColor,
    required this.tasksAssigned,
    required this.tasksCompleted,
  });
}

class TeamTab extends StatefulWidget {
  final String projectId;
  
  const TeamTab({super.key, required this.projectId});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  List<TeamMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client
          .from('project_members')
          .select('''
            id,
            member:members!inner(
              id,
              profile:profiles!inner(
                full_name,
                email
              ),
              role,
              position_code
            )
          ''')
          .eq('project_id', widget.projectId);

      final members = (response as List).map((item) {
        final member = item['member'];
        final profile = member['profile'];
        final fullName = profile['full_name'] ?? 'Unknown';
        final role = member['role'] ?? 'member';
        final positionCode = member['position_code'];
        
        // Map role to Indonesian
        String displayRole = 'Member';
        if (role == 'owner') {
          displayRole = 'Ketua Umum';
        } else if (role == 'admin') {
          displayRole = 'Administrator';
        } else if (positionCode != null) {
          displayRole = positionCode;
        }
        
        final nameParts = fullName.split(' ');
        final initials = nameParts.length >= 2
            ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
            : fullName.substring(0, 2).toUpperCase();
        
        final colors = [
          const Color(0xFF6C5CE7),
          const Color(0xFF00CEC9),
          const Color(0xFFFF7675),
          const Color(0xFF00B894),
          const Color(0xFF0984E3),
          const Color(0xFFFDAA5C),
          const Color(0xFFE17055),
        ];
        final colorIndex = fullName.hashCode % colors.length;
        
        return TeamMember(
          id: item['id'],
          name: fullName,
          role: displayRole,
          initials: initials,
          avatarColor: colors[colorIndex.abs()],
          tasksAssigned: 0,
          tasksCompleted: 0,
        );
      }).toList();

      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat anggota: $e')),
        );
      }
    }
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddMemberDialog(
        projectId: widget.projectId,
        onMemberAdded: _loadMembers,
      ),
    );
  }

  Future<void> _removeMember(String projectMemberId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: Text('Apakah Anda yakin ingin menghapus $memberName dari proyek ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('project_members')
            .delete()
            .eq('id', projectMemberId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anggota berhasil dihapus')),
          );
          _loadMembers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus anggota: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final members = _members;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                onPressed: _showAddMemberDialog,
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
          if (members.isEmpty)
            _buildEmptyState()
          else ...[
            _buildSummaryRow(members),
            const SizedBox(height: 24),
            _buildMembersTable(members),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 40,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Anggota',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan anggota untuk memulai kolaborasi dalam proyek ini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Tambah Anggota Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTable(List<TeamMember> members) {
    return Container(
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
          onSelected: (value) {
            if (value == 'remove') {
              _removeMember(member.id, member.name);
            }
          },
        ),
      ]),
    );
  }
}

// ─── Add Member Dialog ──────────────────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onMemberAdded;

  const _AddMemberDialog({
    required this.projectId,
    required this.onMemberAdded,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  List<Map<String, dynamic>> _availableMembers = [];
  List<String> _selectedMemberIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableMembers();
  }

  Future<void> _loadAvailableMembers() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final userMember = await Supabase.instance.client
          .from('members')
          .select('organization_id')
          .eq('profile_id', userId)
          .single();

      final orgId = userMember['organization_id'];

      final allMembers = await Supabase.instance.client
          .from('members')
          .select('''
            id,
            profile:profiles!inner(
              full_name,
              email
            ),
            role,
            position_code
          ''')
          .eq('organization_id', orgId);

      final projectMembers = await Supabase.instance.client
          .from('project_members')
          .select('member_id')
          .eq('project_id', widget.projectId);

      final existingMemberIds = (projectMembers as List)
          .map((pm) => pm['member_id'] as String)
          .toSet();

      final available = (allMembers as List)
          .where((m) => !existingMemberIds.contains(m['id']))
          .map((m) => m as Map<String, dynamic>)
          .toList();

      setState(() {
        _availableMembers = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat anggota: $e')),
        );
      }
    }
  }

  Future<void> _addMembers() async {
    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu anggota')),
      );
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      final inserts = _selectedMemberIds.map((memberId) => {
        'project_id': widget.projectId,
        'member_id': memberId,
        'added_by': userId,
      }).toList();

      await Supabase.instance.client
          .from('project_members')
          .insert(inserts);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedMemberIds.length} anggota berhasil ditambahkan')),
        );
        widget.onMemberAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan anggota: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _availableMembers.where((member) {
      final name = member['profile']['full_name']?.toString().toLowerCase() ?? '';
      final email = member['profile']['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(Icons.person_add, color: Color(0xFF6C5CE7), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Tambah Anggota Proyek',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari anggota...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMembers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Semua anggota sudah ditambahkan'
                                    : 'Tidak ada anggota yang cocok',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = filteredMembers[index];
                            final memberId = member['id'] as String;
                            final profile = member['profile'];
                            final fullName = profile['full_name'] ?? 'Unknown';
                            final email = profile['email'] ?? '';
                            final role = member['role'] ?? 'member';
                            final positionCode = member['position_code'];
                            
                            // Map role to display
                            String displayRole = 'Member';
                            if (role == 'owner') {
                              displayRole = 'Ketua Umum';
                            } else if (role == 'admin') {
                              displayRole = 'Administrator';
                            } else if (positionCode != null) {
                              displayRole = positionCode;
                            }
                            
                            final isSelected = _selectedMemberIds.contains(memberId);

                            final nameParts = fullName.split(' ');
                            final initials = nameParts.length >= 2
                                ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
                                : fullName.substring(0, 2).toUpperCase();

                            final colors = [
                              const Color(0xFF6C5CE7),
                              const Color(0xFF00CEC9),
                              const Color(0xFFFF7675),
                              const Color(0xFF00B894),
                              const Color(0xFF0984E3),
                              const Color(0xFFFDAA5C),
                            ];
                            final color = colors[fullName.hashCode.abs() % colors.length];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected ? const Color(0xFF6C5CE7).withOpacity(0.05) : Colors.white,
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMemberIds.add(memberId);
                                    } else {
                                      _selectedMemberIds.remove(memberId);
                                    }
                                  });
                                },
                                secondary: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      initials,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      email,
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        displayRole,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: color,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                activeColor: const Color(0xFF6C5CE7),
                              ),
                            );
                          },
                        ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedMemberIds.length} anggota dipilih',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _selectedMemberIds.isEmpty ? null : _addMembers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Tambah Anggota'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
