import 'package:flutter/material.dart';
import '../../models/capacity_model.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class CapacityOverviewPage extends StatefulWidget {
  const CapacityOverviewPage({super.key});

  @override
  State<CapacityOverviewPage> createState() => _CapacityOverviewPageState();
}

class _CapacityOverviewPageState extends State<CapacityOverviewPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    final List<MemberCapacity> members = [
      MemberCapacity(name: "Sarah Chen", role: "Lead Designer", max: 40, used: 37, status: CapacityStatus.overloaded),
      MemberCapacity(name: "Mike Johnson", role: "Senior Developer", max: 40, used: 35, status: CapacityStatus.warning),
      MemberCapacity(name: "Emma Davis", role: "Product Manager", max: 35, used: 30, status: CapacityStatus.warning),
      MemberCapacity(name: "Alex Kim", role: "DevOps Engineer", max: 40, used: 29, status: CapacityStatus.active),
      MemberCapacity(name: "Tom Wilson", role: "QA Engineer", max: 40, used: 27, status: CapacityStatus.active),
      MemberCapacity(name: "Lisa Anderson", role: "Marketing Lead", max: 35, used: 23, status: CapacityStatus.active),
      MemberCapacity(name: "James Brown", role: "Backend Developer", max: 40, used: 23, status: CapacityStatus.active),
      MemberCapacity(name: "Sophia Martinez", role: "UX Designer", max: 35, used: 16, status: CapacityStatus.active),
    ];

    final totalCapacity = members.fold(0, (sum, m) => sum + m.max);
    final totalUsed = members.fold(0, (sum, m) => sum + m.used);
    final totalAvailable = totalCapacity - totalUsed;
    final avgLoad = ((totalUsed / totalCapacity) * 100).round();

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
              child: ResponsiveSidebar(currentRoute: '/fairness'),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for desktop
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/fairness'),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacity Overview',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Detailed view of all member capacity and workload',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  _buildSummaryCards(
                    isSmallScreen,
                    totalCapacity,
                    totalUsed,
                    totalAvailable,
                    avgLoad,
                  ),
                  const SizedBox(height: 24),

                  // Member Capacity Details
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Member Capacity Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...members.map((member) => _buildMemberCard(member)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    bool isSmallScreen,
    int totalCapacity,
    int totalUsed,
    int totalAvailable,
    int avgLoad,
  ) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildSummaryCard('Total Capacity', '${totalCapacity}h'),
          const SizedBox(height: 12),
          _buildSummaryCard('Used', '${totalUsed}h'),
          const SizedBox(height: 12),
          _buildSummaryCard('Available', '${totalAvailable}h'),
          const SizedBox(height: 12),
          _buildSummaryCard('Avg. Load', '$avgLoad%'),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total Capacity', '${totalCapacity}h')),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Used', '${totalUsed}h')),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Available', '${totalAvailable}h')),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Avg. Load', '$avgLoad%')),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberCapacity member) {
    final statusConfig = member.statusConfig;
    final loadRatio = member.loadRatio;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Avatar and Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            member.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: statusConfig.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        member.role,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusConfig.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusConfig.color.withOpacity(0.3)),
                ),
                child: Text(
                  statusConfig.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusConfig.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Capacity Usage
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Capacity Usage',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${member.used}h / ${member.max}h per week',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusConfig.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: loadRatio / 100,
                  backgroundColor: Colors.grey.shade200,
                  color: statusConfig.color,
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Load Ratio',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${loadRatio.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusConfig.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
