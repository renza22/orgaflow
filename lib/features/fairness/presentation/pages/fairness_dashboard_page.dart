import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/fairness_model.dart';
import 'rebalance_wizard_page.dart';
import 'capacity_overview_page.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class FairnessDashboardPage extends StatefulWidget {
  const FairnessDashboardPage({super.key});

  @override
  State<FairnessDashboardPage> createState() => _FairnessDashboardPageState();
}

class _FairnessDashboardPageState extends State<FairnessDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final List<MemberWorkload> _memberWorkload = [
    MemberWorkload(name: "Sarah C.", load: 92, fairness: 45, status: WorkloadStatus.red, id: "fw-1"),
    MemberWorkload(name: "Mike J.", load: 88, fairness: 52, status: WorkloadStatus.yellow, id: "fw-2"),
    MemberWorkload(name: "Emma D.", load: 85, fairness: 58, status: WorkloadStatus.yellow, id: "fw-3"),
    MemberWorkload(name: "Alex K.", load: 72, fairness: 78, status: WorkloadStatus.green, id: "fw-4"),
    MemberWorkload(name: "Tom W.", load: 68, fairness: 82, status: WorkloadStatus.green, id: "fw-5"),
    MemberWorkload(name: "Lisa A.", load: 65, fairness: 85, status: WorkloadStatus.green, id: "fw-6"),
    MemberWorkload(name: "James B.", load: 58, fairness: 88, status: WorkloadStatus.green, id: "fw-7"),
    MemberWorkload(name: "Sophia M.", load: 45, fairness: 92, status: WorkloadStatus.green, id: "fw-8"),
  ];

  final List<FairnessTrend> _fairnessTrend = [
    FairnessTrend(month: "Oct", score: 65, id: "ft-1"),
    FairnessTrend(month: "Nov", score: 68, id: "ft-2"),
    FairnessTrend(month: "Dec", score: 72, id: "ft-3"),
    FairnessTrend(month: "Jan", score: 74, id: "ft-4"),
    FairnessTrend(month: "Feb", score: 76, id: "ft-5"),
    FairnessTrend(month: "Mar", score: 78, id: "ft-6"),
  ];

  final List<BurnoutAlert> _alerts = [
    BurnoutAlert(
      id: 1,
      member: "Sarah Chen",
      issue: "92% capacity for 14 days",
      severity: AlertSeverity.critical,
      action: "Immediate rebalance needed",
    ),
    BurnoutAlert(
      id: 2,
      member: "Mike Johnson",
      issue: "88% capacity with 5 high-priority tasks",
      severity: AlertSeverity.warning,
      action: "Consider task redistribution",
    ),
    BurnoutAlert(
      id: 3,
      member: "Emma Davis",
      issue: "85% capacity approaching threshold",
      severity: AlertSeverity.warning,
      action: "Monitor workload closely",
    ),
  ];

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Insights & Fairness',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scoreboard keadilan distribusi beban kerja',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isSmallScreen)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RebalanceWizardPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.balance, size: 18),
                          label: const Text('Rebalance Wizard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Key Metrics
                  _buildKeyMetrics(isSmallScreen),
                  const SizedBox(height: 24),

                  // Charts
                  _buildCharts(isSmallScreen),
                  const SizedBox(height: 24),

                  // Alerts
                  _buildAlerts(),
                  const SizedBox(height: 24),

                  // Fairness Scores
                  _buildFairnessScores(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RebalanceWizardPage(),
                  ),
                );
              },
              backgroundColor: const Color(0xFF6C5CE7),
              child: const Icon(Icons.balance),
            )
          : null,
    );
  }

  Widget _buildKeyMetrics(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildMetricCard(
            'Overall Fairness Index',
            '78%',
            '+5% this month',
            Icons.balance,
            Colors.green,
            null,
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Members at Risk',
            '3',
            'Need attention',
            Icons.warning_amber_rounded,
            const Color(0xFFFDCB6E),
            const Color(0xFFFDCB6E).withOpacity(0.05),
          ),
          const SizedBox(height: 12),
          _buildMetricCard(
            'Rebalance Actions',
            '12',
            'This quarter',
            Icons.trending_up,
            const Color(0xFF6C5CE7),
            null,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Overall Fairness Index',
            '78%',
            '+5% this month',
            Icons.balance,
            Colors.green,
            null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Members at Risk',
            '3',
            'Need attention',
            Icons.warning_amber_rounded,
            const Color(0xFFFDCB6E),
            const Color(0xFFFDCB6E).withOpacity(0.05),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Rebalance Actions',
            '12',
            'This quarter',
            Icons.trending_up,
            const Color(0xFF6C5CE7),
            null,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    Color? bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor != null ? color.withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: bgColor != null ? color : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: bgColor != null ? color : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (label == 'Overall Fairness Index')
                      Icon(Icons.trending_up, size: 16, color: color),
                    if (label == 'Overall Fairness Index') const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: bgColor != null ? color.withOpacity(0.8) : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildWorkloadChart(),
          const SizedBox(height: 24),
          _buildTrendChart(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildWorkloadChart()),
        const SizedBox(width: 24),
        Expanded(child: _buildTrendChart()),
      ],
    );
  }

  Widget _buildWorkloadChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Beban Kerja per Anggota',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current capacity usage',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CapacityOverviewPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _memberWorkload.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _memberWorkload[value.toInt()].name,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                ),
                borderData: FlBorderData(show: false),
                barGroups: _memberWorkload.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.load.toDouble(),
                        color: entry.value.statusColor,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    return Container(
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
            'Fairness Score Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6-month improvement trajectory',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _fairnessTrend.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _fairnessTrend[value.toInt()].month,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: _fairnessTrend.asMap().entries.map((entry) {
                      return FlSpot(entry.key.toDouble(), entry.value.score.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF00B894),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: const Color(0xFF00B894),
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

  Widget _buildAlerts() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7675).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF7675).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Burnout Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF7675),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Members requiring immediate attention',
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFFF7675).withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RebalanceWizardPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Take Action'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7675),
                  side: BorderSide(color: const Color(0xFFFF7675).withOpacity(0.3)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._alerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BurnoutAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: alert.severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: alert.severityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.member,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.issue,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  alert.action,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: alert.severityColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              alert.severityLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFairnessScores() {
    return Container(
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
            'Individual Fairness Scores',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._memberWorkload.map((member) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      member.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: member.fairness / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: const Color(0xFF6C5CE7),
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${member.fairness}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
