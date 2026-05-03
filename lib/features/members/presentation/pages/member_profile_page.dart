import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/skill_model.dart';
import '../../models/task_history_model.dart';
import '../../models/workload_trend_model.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class MemberProfilePage extends StatefulWidget {
  final int memberId;
  final String memberName;
  final bool showEditButton;

  const MemberProfilePage({
    super.key,
    required this.memberId,
    required this.memberName,
    this.showEditButton = false,
  });

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Profile data
  String name = "Alex Johnson";
  String role = "Senior Developer";
  String email = "alex.johnson@company.com";
  String phone = "+1 234 567 8900";
  String joinedAt = "Jan 2024";
  int fairnessScore = 85;
  int capacityUsed = 32;
  int capacityMax = 40;

  final List<Skill> skills = [
    Skill(name: "React", level: "Expert", proficiency: 95),
    Skill(name: "TypeScript", level: "Advanced", proficiency: 88),
    Skill(name: "Node.js", level: "Advanced", proficiency: 82),
    Skill(name: "UI/UX Design", level: "Intermediate", proficiency: 70),
  ];

  final List<TaskHistory> taskHistory = [
    TaskHistory(
      id: 1,
      title: "Build Dashboard Component",
      project: "Project Alpha",
      status: "completed",
      completedAt: "2 days ago",
      startedAt: "",
    ),
    TaskHistory(
      id: 2,
      title: "API Integration",
      project: "Project Beta",
      status: "in-progress",
      completedAt: "",
      startedAt: "3 days ago",
    ),
    TaskHistory(
      id: 3,
      title: "Code Review",
      project: "Project Gamma",
      status: "completed",
      completedAt: "1 week ago",
      startedAt: "",
    ),
  ];

  final List<WorkloadTrend> workloadTrend = [
    WorkloadTrend(week: 'W1', load: 65),
    WorkloadTrend(week: 'W2', load: 72),
    WorkloadTrend(week: 'W3', load: 68),
    WorkloadTrend(week: 'W4', load: 85),
    WorkloadTrend(week: 'W5', load: 78),
    WorkloadTrend(week: 'W6', load: 80),
  ];

  double get loadRatio => (capacityUsed / capacityMax) * 100;

  String get currentStatus {
    if (loadRatio >= 100) return "overloaded";
    if (loadRatio >= 80) return "warning";
    return "healthy";
  }

  Color get statusColor {
    switch (currentStatus) {
      case "overloaded":
        return Colors.red;
      case "warning":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Color getProficiencyColor(int proficiency) {
    if (proficiency >= 90) return Colors.green;
    if (proficiency >= 75) return const Color(0xFF6C5CE7);
    if (proficiency >= 60) return Colors.orange;
    return Colors.grey;
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: name);
    final roleController = TextEditingController(text: role);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 425,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              _buildTextField('Name', nameController),
              const SizedBox(height: 16),
              _buildTextField('Role', roleController),
              const SizedBox(height: 16),
              _buildTextField('Email', emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Phone', phoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        name = nameController.text;
                        role = roleController.text;
                        email = emailController.text;
                        phone = phoneController.text;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCapacityDialog() {
    final capacityController = TextEditingController(text: capacityMax.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 425,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Weekly Capacity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              _buildTextField('Max Hours per Week', capacityController, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        capacityMax = int.tryParse(capacityController.text) ?? capacityMax;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
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
                  // Header
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Member Profile',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 20 : 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View and manage member details',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.showEditButton && !isSmallScreen)
                              ElevatedButton.icon(
                                onPressed: _showEditProfileDialog,
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C5CE7),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth >= 1024) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.33,
                              child: _buildProfileCard(isSmallScreen),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _buildMainContent(isSmallScreen),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildProfileCard(isSmallScreen),
                            const SizedBox(height: 24),
                            _buildMainContent(isSmallScreen),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (widget.showEditButton && isSmallScreen)
          ? FloatingActionButton(
              onPressed: _showEditProfileDialog,
              backgroundColor: const Color(0xFF6C5CE7),
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildProfileCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: isSmallScreen ? 80 : 96,
                height: isSmallScreen ? 80 : 96,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C5CE7),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.split(' ').map((n) => n[0]).join('').substring(0, 2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Contact Info
          _buildInfoRow(Icons.email_outlined, email, isSmallScreen),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_outlined, phone, isSmallScreen),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today_outlined, 'Joined $joinedAt', isSmallScreen),
          const SizedBox(height: 24),

          // Fairness Score
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fairness Score',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.emoji_events, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$fairnessScore',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fairnessScore / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF6C5CE7),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isSmallScreen) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isSmallScreen) {
    return Column(
      children: [
        _buildCapacityCard(isSmallScreen),
        const SizedBox(height: 24),
        _buildWorkloadTrendCard(isSmallScreen),
        const SizedBox(height: 24),
        _buildSkillsCard(isSmallScreen),
        const SizedBox(height: 24),
        _buildTaskHistoryCard(isSmallScreen),
      ],
    );
  }

  Widget _buildCapacityCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capacity Status',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current workload allocation',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _showEditCapacityDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: Text(
                      'Update Capacity',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      currentStatus == "overloaded"
                          ? "⚠️ Overload"
                          : currentStatus == "warning"
                              ? "⚡ Warning"
                              : "✓ Healthy",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hours Used',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${capacityUsed}h / ${capacityMax}h per week',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: loadRatio / 100,
              backgroundColor: Colors.grey.shade200,
              color: statusColor,
              minHeight: isSmallScreen ? 10 : 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load ratio: ${loadRatio.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadTrendCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workload Trend',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capacity usage over the last 6 weeks',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: isSmallScreen ? 180 : 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                      dashArray: [3, 3],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < workloadTrend.length) {
                          return Text(
                            workloadTrend[value.toInt()].week,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (workloadTrend.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: workloadTrend.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.load);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF6C5CE7),
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: const Color(0xFF6C5CE7),
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skills & Proficiency',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...skills.map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            skill.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              skill.level,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${skill.proficiency}%',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: skill.proficiency / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: getProficiencyColor(skill.proficiency),
                      minHeight: isSmallScreen ? 6 : 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskHistoryCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task History',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...taskHistory.map((task) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.project,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: task.status == "completed"
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.status == "completed" ? "Completed" : "In Progress",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: task.status == "completed" ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.status == "completed"
                                ? task.completedAt
                                : 'Started ${task.startedAt}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
