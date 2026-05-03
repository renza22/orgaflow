import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../../../../core/navigation/no_transition_page_route.dart';
import 'member_profile_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _searchQuery = '';
  String _selectedSkill = 'All Skills';

  final List<Member> _members = [
    Member(
      id: 1,
      name: "Sarah Chen",
      role: "Lead Designer",
      email: "sarah.chen@org.com",
      capacityMax: 40,
      capacityUsed: 37,
      skills: ["UI/UX", "Creative", "Prototyping"],
      status: MemberStatus.overloaded,
      tasksCount: 12,
    ),
    Member(
      id: 2,
      name: "Mike Johnson",
      role: "Senior Developer",
      email: "mike.j@org.com",
      capacityMax: 40,
      capacityUsed: 35,
      skills: ["Backend", "Python", "Database"],
      status: MemberStatus.warning,
      tasksCount: 15,
    ),
    Member(
      id: 3,
      name: "Emma Davis",
      role: "Product Manager",
      email: "emma.d@org.com",
      capacityMax: 35,
      capacityUsed: 30,
      skills: ["Management", "Planning", "Communication"],
      status: MemberStatus.warning,
      tasksCount: 10,
    ),
    Member(
      id: 4,
      name: "Alex Kim",
      role: "DevOps Engineer",
      email: "alex.kim@org.com",
      capacityMax: 40,
      capacityUsed: 29,
      skills: ["DevOps", "Cloud", "Automation"],
      status: MemberStatus.active,
      tasksCount: 8,
    ),
    Member(
      id: 5,
      name: "Tom Wilson",
      role: "QA Engineer",
      email: "tom.w@org.com",
      capacityMax: 40,
      capacityUsed: 27,
      skills: ["Testing", "QA", "Automation"],
      status: MemberStatus.active,
      tasksCount: 9,
    ),
    Member(
      id: 6,
      name: "Lisa Anderson",
      role: "Marketing Lead",
      email: "lisa.a@org.com",
      capacityMax: 35,
      capacityUsed: 23,
      skills: ["Marketing", "Content", "Social Media"],
      status: MemberStatus.active,
      tasksCount: 7,
    ),
  ];

  final List<String> _skillCategories = [
    "All Skills",
    "UI/UX",
    "Backend",
    "Frontend",
    "DevOps",
    "Management",
    "Marketing"
  ];

  List<Member> get _filteredMembers {
    return _members.where((member) {
      final matchesSearch = member.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSkill = _selectedSkill == 'All Skills' ||
          member.skills.any((skill) => skill.toLowerCase().contains(_selectedSkill.toLowerCase()));
      return matchesSearch && matchesSkill;
    }).toList();
  }

  int get _totalMembers => 24;
  int get _healthyCount => 18;
  int get _warningCount => 3;
  int get _overloadedCount => 3;

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
          // Sidebar for desktop
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/members'),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title
                  Column(
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
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsCards(isSmallScreen),
                  const SizedBox(height: 24),

                  // Search and Filters
                  _buildSearchAndFilters(isSmallScreen),
                  const SizedBox(height: 24),

                  // Members Grid
                  _buildMembersGrid(isSmallScreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildStatCard('Total Members', '$_totalMembers', null, null),
          const SizedBox(height: 12),
          _buildStatCard('Healthy', '$_healthyCount', Colors.green, Colors.green.shade50),
          const SizedBox(height: 12),
          _buildStatCard('Warning', '$_warningCount', Colors.orange, Colors.orange.shade50),
          const SizedBox(height: 12),
          _buildStatCard('Overloaded', '$_overloadedCount', Colors.red, Colors.red.shade50),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Members', '$_totalMembers', null, null)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Healthy', '$_healthyCount', Colors.green, Colors.green.shade50)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Warning', '$_warningCount', Colors.orange, Colors.orange.shade50)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Overloaded', '$_overloadedCount', Colors.red, Colors.red.shade50)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color? textColor, Color? bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor?.withOpacity(0.2) ?? Colors.grey.shade200,
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

  Widget _buildSearchAndFilters(bool isSmallScreen) {
    return Column(
      children: [
        // Search Bar
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
              hintText: 'Search members...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Skill Filters
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _skillCategories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final skill = _skillCategories[index];
              final isSelected = _selectedSkill == skill;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSkill = skill;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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
            childAspectRatio: 1.45,
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
    final loadRatio = member.loadRatio;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          NoTransitionPageRoute(
            builder: (context) => MemberProfilePage(
              memberId: member.id,
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Name
            Row(
              children: [
                Stack(
                  children: [
                    Container(
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
                    ),
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
                      ),
                      Text(
                        member.role,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Email and Tasks
            Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.email,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.work_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  '${member.tasksCount} active tasks',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Skills
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: member.skills.map((skill) {
                return Container(
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
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Capacity Bar
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
                      '${member.capacityUsed}/${member.capacityMax}h',
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
                    value: loadRatio / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: statusConfig.color,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    '${statusConfig.label} (${loadRatio.toStringAsFixed(0)}%)',
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
}
