import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/result/result.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../../domain/models/fairness_summary_model.dart';
import '../../domain/models/fairness_trend_model.dart';
import '../../domain/models/member_fairness_breakdown_model.dart';
import '../presenters/fairness_presenter.dart';

class FairnessDashboardPage extends StatefulWidget {
  const FairnessDashboardPage({super.key});

  @override
  State<FairnessDashboardPage> createState() => _FairnessDashboardPageState();
}

class _FairnessDashboardPageState extends State<FairnessDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FairnessPresenter _presenter = FairnessPresenter();

  FairnessSummaryModel? _summary;
  List<MemberFairnessBreakdownModel> _memberBreakdown = const [];
  List<FairnessTrendModel> _fairnessTrend = const [];
  String? _organizationId;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRefreshingSnapshot = false;

  @override
  void initState() {
    super.initState();
    _loadFairnessData();
  }

  Future<void> _loadFairnessData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final context = await sessionService.getCurrentContext(refresh: true);
      final organizationId = context?.activeMember?.organizationId.trim();

      if (!mounted) {
        return;
      }

      if (organizationId == null || organizationId.isEmpty) {
        setState(() {
          _organizationId = null;
          _summary = null;
          _memberBreakdown = const [];
          _fairnessTrend = const [];
          _errorMessage = 'User belum memiliki organisasi aktif.';
          _isLoading = false;
        });
        return;
      }

      _organizationId = organizationId;

      final results = await Future.wait<dynamic>([
        _presenter.fetchOrganizationFairnessSummary(
          organizationId: organizationId,
        ),
        _presenter.fetchMemberFairnessBreakdown(
          organizationId: organizationId,
        ),
        _presenter.fetchOrganizationFairnessTrend(
          organizationId: organizationId,
          limit: 12,
        ),
      ]);

      if (!mounted) {
        return;
      }

      final summaryResult = results[0] as Result<FairnessSummaryModel?>;
      final breakdownResult =
          results[1] as Result<List<MemberFairnessBreakdownModel>>;
      final trendResult = results[2] as Result<List<FairnessTrendModel>>;

      final errorMessage = summaryResult.error?.message ??
          breakdownResult.error?.message ??
          trendResult.error?.message;

      if (errorMessage != null) {
        setState(() {
          _summary = null;
          _memberBreakdown = const [];
          _fairnessTrend = const [];
          _errorMessage = errorMessage;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _summary = summaryResult.data;
        _memberBreakdown = breakdownResult.data ?? const [];
        _fairnessTrend = trendResult.data ?? const [];
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _summary = null;
        _memberBreakdown = const [];
        _fairnessTrend = const [];
        _errorMessage = ErrorMapper.map(error).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSnapshot() async {
    final organizationId = _organizationId;
    if (organizationId == null || organizationId.isEmpty) {
      _showMessage('User belum memiliki organisasi aktif.');
      return;
    }

    setState(() {
      _isRefreshingSnapshot = true;
    });

    final result = await _presenter.refreshOrganizationFairnessScores(
      organizationId: organizationId,
      scoreDate: DateTime.now(),
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _isRefreshingSnapshot = false;
      });
      _showMessage(result.error!.message);
      return;
    }

    await _loadFairnessData(showLoading: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshingSnapshot = false;
    });
    _showMessage('Snapshot fairness diperbarui.');
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
              child: ResponsiveSidebar(currentRoute: '/fairness'),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/fairness'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isSmallScreen),
                  const SizedBox(height: 24),
                  _buildBody(isSmallScreen),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: _isRefreshingSnapshot ? null : _refreshSnapshot,
              backgroundColor: const Color(0xFF6C5CE7),
              child: _isRefreshingSnapshot
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
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
            onPressed: _isRefreshingSnapshot ? null : _refreshSnapshot,
            icon: _isRefreshingSnapshot
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: Text(
              _isRefreshingSnapshot ? 'Menyimpan...' : 'Refresh Snapshot',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    if (_isLoading) {
      return _buildStateCard(
        icon: Icons.insights,
        title: 'Memuat fairness dashboard',
        message: 'Mengambil summary, breakdown anggota, dan histori fairness.',
        child: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return _buildStateCard(
        icon: Icons.error_outline,
        title: 'Fairness dashboard gagal dimuat',
        message: errorMessage,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            onPressed: _loadFairnessData,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    if (_hasEmptyData) {
      return _buildStateCard(
        icon: Icons.balance,
        title: 'Belum ada data fairness',
        message: 'Belum ada anggota aktif dengan kapasitas untuk dihitung.',
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: OutlinedButton.icon(
            onPressed: _isRefreshingSnapshot ? null : _refreshSnapshot,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh Snapshot'),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildKeyMetrics(isSmallScreen),
        const SizedBox(height: 24),
        _buildCharts(isSmallScreen),
        const SizedBox(height: 24),
        _buildAttentionList(),
        const SizedBox(height: 24),
        _buildFairnessScores(),
      ],
    );
  }

  Widget _buildStateCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(bool isSmallScreen) {
    final summary = _summary!;
    final fairnessColor = _fairnessColor(summary.fairnessScore);
    final cards = [
      _MetricCardData(
        label: 'Fairness Score',
        value: '${_formatScore(summary.fairnessScore)}/100',
        subtitle: _fairnessLabel(summary.fairnessScore),
        icon: Icons.balance,
        color: fairnessColor,
      ),
      _MetricCardData(
        label: 'Average Load',
        value: '${_formatPercentage(summary.averageLoadPercentage)}%',
        subtitle: 'Rata-rata beban anggota',
        icon: Icons.speed,
        color: const Color(0xFF6C5CE7),
      ),
      _MetricCardData(
        label: 'Std Dev',
        value: '${_formatPercentage(summary.stddevLoadPercentage)}%',
        subtitle: 'Sebaran beban kerja',
        icon: Icons.show_chart,
        color: const Color(0xFF0984E3),
      ),
      _MetricCardData(
        label: 'Active Members',
        value: '${summary.eligibleMemberCount}',
        subtitle: '${summary.memberCount} total anggota',
        icon: Icons.groups,
        color: const Color(0xFF00B894),
      ),
      _MetricCardData(
        label: 'Overload Count',
        value: '${summary.overloadCount}',
        subtitle: 'Anggota overload',
        icon: Icons.error_outline,
        color: const Color(0xFFFF7675),
        bgColor: summary.overloadCount > 0
            ? const Color(0xFFFF7675).withValues(alpha: 0.05)
            : null,
      ),
      _MetricCardData(
        label: 'Warning Count',
        value: '${summary.warningCount}',
        subtitle: 'Anggota warning',
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF59E0B),
        bgColor: summary.warningCount > 0
            ? const Color(0xFFF59E0B).withValues(alpha: 0.07)
            : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = isSmallScreen ? 12.0 : 16.0;
        final columnCount = isSmallScreen ? 1 : 3;
        final width =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  child: _buildMetricCard(card),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(_MetricCardData data) {
    final bgColor = data.bgColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor != null
              ? data.color.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: bgColor != null ? data.color : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: bgColor != null ? data.color : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: bgColor != null
                        ? data.color.withValues(alpha: 0.8)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
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
    final chartMembers = _memberBreakdown.take(8).toList();

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
            'Beban Kerja per Anggota',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Load saat ini dari breakdown fairness backend',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (chartMembers.isEmpty)
            _buildInlineEmptyState('Belum ada data beban kerja anggota.')
          else
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxLoadChartY(chartMembers),
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartMembers.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _shortName(chartMembers[index].displayName),
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
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
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: chartMembers.asMap().entries.map((entry) {
                    final member = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: math.max(0, member.loadPercentage),
                          color: _workloadStatusColor(member.workloadStatus),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Fairness Score Trend',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isRefreshingSnapshot ? null : _refreshSnapshot,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Snapshot'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Histori fairness dari snapshot backend',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (_fairnessTrend.isEmpty)
            _buildInlineEmptyState(
              'Belum ada histori fairness. Klik Refresh Snapshot untuk '
              'menyimpan data hari ini.',
            )
          else
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _fairnessTrend.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _fairnessTrend[index].dateLabel,
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
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: _fairnessTrend.length > 1
                      ? (_fairnessTrend.length - 1).toDouble()
                      : 1,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _fairnessTrend.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.fairnessScore,
                        );
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

  Widget _buildInlineEmptyState(String message) {
    return Container(
      width: double.infinity,
      height: 300,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildAttentionList() {
    final members = _memberBreakdown
        .where((member) {
          final status = member.workloadStatus.toLowerCase();
          return status == 'warning' || status == 'overload';
        })
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7675).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF7675).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Anggota Perlu Perhatian',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF7675),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Berdasarkan status workload dari backend fairness',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFFFF7675).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          if (members.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Tidak ada anggota warning atau overload saat ini.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          else
            ...members.map(_buildAttentionCard),
        ],
      ),
    );
  }

  Widget _buildAttentionCard(MemberFairnessBreakdownModel member) {
    final color = _workloadStatusColor(member.workloadStatus);

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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatPercentage(member.loadPercentage)}% load, '
                  'deviasi ${_formatSignedPercentage(
                    member.deviationPercentage,
                  )}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  member.workloadStatus.toLowerCase() == 'overload'
                      ? 'Perlu redistribusi beban kerja'
                      : 'Pantau dan pertimbangkan redistribusi',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C5CE7),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusChip(member.workloadStatus),
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
          const SizedBox(height: 4),
          Text(
            'Diurutkan berdasarkan deviasi terbesar dari rata-rata organisasi',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (_memberBreakdown.isEmpty)
            Text(
              'Belum ada data fairness anggota.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          else
            ..._memberBreakdown.map(_buildMemberFairnessRow),
        ],
      ),
    );
  }

  Widget _buildMemberFairnessRow(MemberFairnessBreakdownModel member) {
    final fairnessScore = member.individualFairnessScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
            child: Text(
              _initials(member.displayName),
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusChip(member.workloadStatus),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildMemberMeta(
                      Icons.schedule,
                      '${_formatHours(member.assignedHours)} / '
                      '${_formatHours(member.weeklyCapacityHours)} jam',
                    ),
                    _buildMemberMeta(
                      Icons.speed,
                      '${_formatPercentage(member.loadPercentage)}% load',
                    ),
                    _buildMemberMeta(
                      Icons.compare_arrows,
                      '${_formatSignedPercentage(
                        member.deviationPercentage,
                      )} deviasi',
                    ),
                    _buildMemberMeta(
                      Icons.task_alt,
                      '${member.activeTaskCount} task aktif',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (fairnessScore / 100).clamp(0.0, 1.0).toDouble(),
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF6C5CE7),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatScore(fairnessScore),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberMeta(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _workloadStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        _workloadStatusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  bool get _hasEmptyData {
    final summary = _summary;
    return summary == null || (summary.isEmpty && _memberBreakdown.isEmpty);
  }

  double _maxLoadChartY(List<MemberFairnessBreakdownModel> members) {
    final maxLoad = members.fold<double>(
      100,
      (current, member) => math.max(current, member.loadPercentage),
    );
    return (((maxLoad + 20) / 20).ceil() * 20).toDouble();
  }

  Color _fairnessColor(double score) {
    if (score >= 85) {
      return const Color(0xFF00B894);
    }
    if (score >= 70) {
      return const Color(0xFFF59E0B);
    }
    return const Color(0xFFE17055);
  }

  String _fairnessLabel(double score) {
    if (score >= 85) {
      return 'Sangat Adil';
    }
    if (score >= 70) {
      return 'Cukup Adil';
    }
    if (score >= 50) {
      return 'Kurang Adil';
    }
    return 'Tidak Adil';
  }

  Color _workloadStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'overload':
        return const Color(0xFFFF7675);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'no_capacity':
        return const Color(0xFF6B7280);
      case 'safe':
      default:
        return const Color(0xFF00B894);
    }
  }

  String _workloadStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'overload':
        return 'Overload';
      case 'warning':
        return 'Warning';
      case 'no_capacity':
        return 'No Capacity';
      case 'safe':
      default:
        return 'Safe';
    }
  }

  String _formatScore(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatPercentage(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatSignedPercentage(double value) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${_formatPercentage(value)}%';
  }

  String _formatHours(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _shortName(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) {
      return value;
    }
    return '${parts.first} ${parts.last.characters.first}.';
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return '?';
    }

    return parts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first.toUpperCase())
        .join();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.bgColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color? bgColor;
}
