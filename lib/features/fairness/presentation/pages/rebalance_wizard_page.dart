import 'package:flutter/material.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/session/session_service.dart';
import '../../models/rebalance_model.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../presenters/fairness_presenter.dart';

class RebalanceWizardPage extends StatefulWidget {
  const RebalanceWizardPage({super.key});

  @override
  State<RebalanceWizardPage> createState() => _RebalanceWizardPageState();
}

class _RebalanceWizardPageState extends State<RebalanceWizardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FairnessPresenter _presenter = FairnessPresenter();

  List<RebalanceItem> _items = const [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _loadRebalancePlan();
  }

  Future<void> _loadRebalancePlan() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final context = await sessionService.getCurrentContext(refresh: true);
      final organizationId = context?.activeMember?.organizationId.trim();

      if (!mounted) {
        return;
      }

      if (organizationId == null || organizationId.isEmpty) {
        setState(() {
          _items = const [];
          _errorMessage = 'User belum memiliki organisasi aktif.';
          _isLoading = false;
        });
        return;
      }

      final result = await _presenter.generateAutoRebalancePlan(
        organizationId: organizationId,
      );

      if (!mounted) {
        return;
      }

      if (result.isFailure) {
        setState(() {
          _items = const [];
          _errorMessage = result.error!.message;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _items = result.data ?? const [];
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _items = const [];
        _errorMessage = ErrorMapper.map(error).message;
        _isLoading = false;
      });
    }
  }

  void _handleApprove(String id, bool approved) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].approved = approved;
      }
    });
  }

  Future<void> _executeApprovedChanges() async {
    if (_isExecuting) {
      return;
    }

    final approvedItems =
        _items.where((item) => item.approved == true).toList();
    if (approvedItems.isEmpty) {
      return;
    }

    final planId = _items.isEmpty ? '' : _items.first.planId.trim();
    if (planId.isEmpty) {
      _showSnackBar('Plan rebalance tidak valid.', isError: true);
      return;
    }

    setState(() {
      _isExecuting = true;
    });

    final result = await _presenter.executeRebalancePlan(
      planId: planId,
      itemIds: approvedItems.map((item) => item.id).toList(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isExecuting = false;
    });

    if (result.isFailure) {
      _showSnackBar(result.error!.message, isError: true);
      return;
    }

    final message = result.data?['message']?.toString();
    _showSnackBar(
      message == null || message.isEmpty
          ? 'Rebalance berhasil dieksekusi.'
          : message,
    );
    Navigator.pop(context, true);
  }

  int get _approvedCount => _items.where((i) => i.approved == true).length;
  int get _rejectedCount => _items.where((i) => i.approved == false).length;
  double get _expectedImpact {
    if (_items.isEmpty) {
      return 0;
    }

    final item = _items.first;
    return item.scoreAfter - item.scoreBefore;
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
                        'Rebalance Wizard',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Redistribusi tugas otomatis untuk keseimbangan beban kerja',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildContent(isSmallScreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen) {
    if (_isLoading) {
      return _buildStateCard(
        icon: Icons.balance,
        title: 'Memuat rekomendasi rebalance',
        message: 'Mengambil rekomendasi redistribusi tugas dari Supabase.',
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
        title: 'Rebalance wizard gagal dimuat',
        message: errorMessage,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ElevatedButton.icon(
            onPressed: _loadRebalancePlan,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return _buildStateCard(
        icon: Icons.task_alt,
        title: 'Tidak ada rekomendasi rebalance',
        message: 'Saat ini tidak ada redistribusi tugas yang direkomendasikan.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryCards(isSmallScreen),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'The system has analyzed current workloads and generated ${_items.length} rebalancing suggestions. Review each suggestion and approve or reject based on your judgment. Approved changes will be executed immediately.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Suggested Redistributions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ..._items.map(
          (item) => _buildRebalanceCard(item, isSmallScreen),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isExecuting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _approvedCount > 0 && !_isExecuting
                  ? _executeApprovedChanges
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                _isExecuting
                    ? 'Executing...'
                    : 'Execute $_approvedCount Approved Changes',
              ),
            ),
          ],
        ),
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

  Widget _buildSummaryCards(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildSummaryCard(
              'Total Suggestions', '${_items.length}', null, null),
          const SizedBox(height: 12),
          _buildSummaryCard('Approved', '$_approvedCount', Colors.green,
              Colors.green.shade50),
          const SizedBox(height: 12),
          _buildSummaryCard(
              'Rejected', '$_rejectedCount', Colors.red, Colors.red.shade50),
          const SizedBox(height: 12),
          _buildSummaryCard('Expected Impact',
              _formatSignedPercentage(_expectedImpact), null, null),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
            child: _buildSummaryCard(
                'Total Suggestions', '${_items.length}', null, null)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildSummaryCard('Approved', '$_approvedCount',
                Colors.green, Colors.green.shade50)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildSummaryCard(
                'Rejected', '$_rejectedCount', Colors.red, Colors.red.shade50)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildSummaryCard('Expected Impact',
                _formatSignedPercentage(_expectedImpact), null, null)),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, Color? textColor, Color? bgColor) {
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

  Widget _buildRebalanceCard(RebalanceItem item, bool isSmallScreen) {
    Color? borderColor;
    Color? bgColor;

    if (item.approved == true) {
      borderColor = Colors.green.withValues(alpha: 0.3);
      bgColor = Colors.green.withValues(alpha: 0.05);
    } else if (item.approved == false) {
      borderColor = Colors.red.withValues(alpha: 0.3);
      bgColor = Colors.red.withValues(alpha: 0.05);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? Colors.grey.shade200,
        ),
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(item),
                const SizedBox(height: 16),
                _buildTransferInfo(item),
                const SizedBox(height: 16),
                _buildReason(item),
                if (item.approved == null) ...[
                  const SizedBox(height: 16),
                  _buildActions(item),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardHeader(item),
                      const SizedBox(height: 16),
                      _buildTransferInfo(item),
                      const SizedBox(height: 16),
                      _buildReason(item),
                    ],
                  ),
                ),
                if (item.approved == null) ...[
                  const SizedBox(width: 24),
                  _buildActions(item),
                ],
              ],
            ),
    );
  }

  Widget _buildCardHeader(RebalanceItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.taskTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_formatHours(item.estimatedHours)}h estimated',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        if (item.approved != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: item.approved! ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.approved! ? Icons.check : Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  item.approved! ? 'Approved' : 'Rejected',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTransferInfo(RebalanceItem item) {
    return Row(
      children: [
        // From Member
        Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.fromInitials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      item.fromMember,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        // To Member
        Expanded(
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    item.toInitials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      item.toMember,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReason(RebalanceItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reason',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.reason,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(RebalanceItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed:
                _isExecuting ? null : () => _handleApprove(item.id, true),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed:
                _isExecuting ? null : () => _handleApprove(item.id, false),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  String _formatHours(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatSignedPercentage(double value) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix${_formatHours(value)}%';
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
