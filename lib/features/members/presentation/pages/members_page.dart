import 'package:flutter/material.dart';

import '../../../../core/navigation/no_transition_page_route.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../../models/member_model.dart';
import '../presenters/members_presenter.dart';
import 'member_profile_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MembersPresenter _presenter = MembersPresenter();

  String _searchQuery = '';
  String _selectedSkill = 'All Skills';
  List<Member> _members = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _presenter.loadMembers();

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.error!.message;
      });
      return;
    }

    final members = result.data!;
    final skillOptions = _buildSkillOptions(members);

    setState(() {
      _members = members;
      if (!skillOptions.contains(_selectedSkill)) {
        _selectedSkill = 'All Skills';
      }
      _isLoading = false;
      _errorMessage = null;
    });
  }

  List<Member> get _filteredMembers {
    return _members.where((member) {
      final matchesSearch = member.matchesQuery(_searchQuery);
      final matchesSkill = _selectedSkill == 'All Skills' ||
          member.skills.any(
            (skill) => skill.toLowerCase() == _selectedSkill.toLowerCase(),
          );
      return matchesSearch && matchesSkill;
    }).toList();
  }

  List<String> get _skillCategories => _buildSkillOptions(_members);

  int get _totalMembers => _members.length;
  int get _safeCount => _countByStatus(MemberStatus.safe);
  int get _warningCount => _countByStatus(MemberStatus.warning);
  int get _criticalCount => _countByStatus(MemberStatus.critical);
  int get _overloadCount => _countByStatus(MemberStatus.overload);
  int get _noCapacityCount => _countByStatus(MemberStatus.noCapacity);

  int _countByStatus(MemberStatus status) {
    return _members.where((member) => member.status == status).length;
  }

  List<String> _buildSkillOptions(List<Member> members) {
    final skills = members.expand((member) => member.skills).toSet().toList()
      ..sort((left, right) => left.toLowerCase().compareTo(
            right.toLowerCase(),
          ));
    return ['All Skills', ...skills];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: EnhancedAppBar(
        showMenuButton: isSmallScreen || isMediumScreen,
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: (isSmallScreen || isMediumScreen)
          ? Drawer(
              child: ResponsiveSidebar(currentRoute: '/members'),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/members'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageTitle(isSmallScreen),
                  const SizedBox(height: 24),
                  _buildBodyContent(isSmallScreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kelola Anggota',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Daftar anggota dengan status kapasitas kerja',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(bool isSmallScreen) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_members.isEmpty) {
      return _buildEmptyState('Belum ada anggota.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsCards(isSmallScreen),
        const SizedBox(height: 24),
        _buildSearchAndFilters(),
        const SizedBox(height: 24),
        _buildMembersGrid(isSmallScreen),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadMembers,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(bool isSmallScreen) {
    final cards = [
      _StatCardData('Total', '$_totalMembers', null, null),
      _StatCardData(
          'Aman', '$_safeCount', Colors.green.shade700, Colors.green.shade50),
      _StatCardData('Warning', '$_warningCount', Colors.orange.shade700,
          Colors.orange.shade50),
      _StatCardData('Critical', '$_criticalCount', Colors.red.shade600,
          Colors.red.shade50),
      _StatCardData('Overload', '$_overloadCount', Colors.red.shade900,
          Colors.red.shade50),
      _StatCardData('No Capacity', '$_noCapacityCount', Colors.grey.shade700,
          Colors.grey.shade100),
    ];

    if (isSmallScreen) {
      return Column(
        children: [
          for (final card in cards) ...[
            _buildStatCard(
              card.label,
              card.value,
              card.textColor,
              card.backgroundColor,
            ),
            if (card != cards.last) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100 ? 6 : 3;
        final cardWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _buildStatCard(
                  card.label,
                  card.value,
                  card.textColor,
                  card.backgroundColor,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color? textColor,
    Color? bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor?.withValues(alpha: 0.2) ?? Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final skillCategories = _skillCategories;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari anggota...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: skillCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final skill = skillCategories[index];
              final isSelected = _selectedSkill == skill;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSkill = skill;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMembersGrid(bool isSmallScreen) {
    final members = _filteredMembers;

    if (members.isEmpty) {
      return _buildEmptyState('Tidak ada anggota yang cocok.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth >= 900) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 600) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isSmallScreen ? 1.05 : 1.15,
          ),
          itemCount: members.length,
          itemBuilder: (context, index) {
            return _buildMemberCard(members[index]);
          },
        );
      },
    );
  }

  Widget _buildMemberCard(Member member) {
    final statusConfig = member.statusConfig;
    final percentage = member.displayLoadPercentage;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          NoTransitionPageRoute(
            builder: (context) => MemberProfilePage(
              memberId: member.memberId,
              memberName: member.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    _buildMemberAvatar(member),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusConfig.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        member.displayRole,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildIconText(Icons.email_outlined, member.email),
            const SizedBox(height: 4),
            _buildIconText(Icons.account_tree_outlined, member.displayDivision),
            const SizedBox(height: 4),
            _buildIconText(
              Icons.work_outline,
              '${member.activeTaskCount} active tasks',
            ),
            const SizedBox(height: 8),
            _buildSkillChips(member),
            const Spacer(),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      member.capacityMax <= 0
                          ? 'Belum set kapasitas'
                          : '${member.capacityUsed}/${member.capacityMax} jam',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusConfig.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: member.progressValue,
                    backgroundColor: Colors.grey.shade200,
                    color: statusConfig.color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${statusConfig.label} (${percentage.toStringAsFixed(0)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusConfig.color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatar(Member member) {
    Widget fallback() {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF6C5CE7),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            member.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final avatarUrl = member.avatarSignedUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return fallback();
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text.isEmpty ? '-' : text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChips(Member member) {
    if (member.skills.isEmpty) {
      return Text(
        'Belum ada skill',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      );
    }

    final visibleSkills = member.skills.take(3).toList();
    final hiddenCount = member.skills.length - visibleSkills.length;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final skill in visibleSkills)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          ),
        if (hiddenCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+$hiddenCount',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCardData {
  const _StatCardData(
    this.label,
    this.value,
    this.textColor,
    this.backgroundColor,
  );

  final String label;
  final String value;
  final Color? textColor;
  final Color? backgroundColor;
}
