import 'package:flutter/material.dart';
import '../../models/rebalance_model.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class RebalanceWizardPage extends StatefulWidget {
  const RebalanceWizardPage({super.key});

  @override
  State<RebalanceWizardPage> createState() => _RebalanceWizardPageState();
}

class _RebalanceWizardPageState extends State<RebalanceWizardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<RebalanceItem> _items = [
    RebalanceItem(
      id: 1,
      taskTitle: "API Documentation",
      fromMember: "Sarah Chen",
      toMember: "Lisa Anderson",
      reason: "Sarah at 92% capacity, Lisa has matching skills at 65%",
      estimatedHours: 6,
      approved: null,
    ),
    RebalanceItem(
      id: 2,
      taskTitle: "User Testing Session",
      fromMember: "Mike Johnson",
      toMember: "Tom Wilson",
      reason: "Mike approaching burnout, Tom has capacity and QA expertise",
      estimatedHours: 8,
      approved: null,
    ),
    RebalanceItem(
      id: 3,
      taskTitle: "Design Review",
      fromMember: "Emma Davis",
      toMember: "Alex Kim",
      reason: "Emma at 85% capacity, redistribute for better balance",
      estimatedHours: 4,
      approved: null,
    ),
  ];

  void _handleApprove(int id, bool approved) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index].approved = approved;
      }
    });
  }

  int get _approvedCount => _items.where((i) => i.approved == true).length;
  int get _rejectedCount => _items.where((i) => i.approved == false).length;

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

                  // Summary Cards
                  _buildSummaryCards(isSmallScreen),
                  const SizedBox(height: 24),

                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withOpacity(0.2),
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

                  // Rebalance Items
                  const Text(
                    'Suggested Redistributions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._items.map((item) => _buildRebalanceCard(item, isSmallScreen)),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _approvedCount > 0
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Executing $_approvedCount approved changes'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text('Execute $_approvedCount Approved Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildSummaryCard('Total Suggestions', '${_items.length}', null, null),
          const SizedBox(height: 12),
          _buildSummaryCard('Approved', '$_approvedCount', Colors.green, Colors.green.shade50),
          const SizedBox(height: 12),
          _buildSummaryCard('Rejected', '$_rejectedCount', Colors.red, Colors.red.shade50),
          const SizedBox(height: 12),
          _buildSummaryCard('Expected Impact', '+12%', null, null),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Total Suggestions', '${_items.length}', null, null)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Approved', '$_approvedCount', Colors.green, Colors.green.shade50)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Rejected', '$_rejectedCount', Colors.red, Colors.red.shade50)),
        const SizedBox(width: 16),
        Expanded(child: _buildSummaryCard('Expected Impact', '+12%', null, null)),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color? textColor, Color? bgColor) {
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

  Widget _buildRebalanceCard(RebalanceItem item, bool isSmallScreen) {
    Color? borderColor;
    Color? bgColor;

    if (item.approved == true) {
      borderColor = Colors.green.withOpacity(0.3);
      bgColor = Colors.green.withOpacity(0.05);
    } else if (item.approved == false) {
      borderColor = Colors.red.withOpacity(0.3);
      bgColor = Colors.red.withOpacity(0.05);
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
                  '${item.estimatedHours}h estimated',
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
                  color: Colors.red.withOpacity(0.1),
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
                  color: Colors.green.withOpacity(0.1),
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
            onPressed: () => _handleApprove(item.id, true),
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
            onPressed: () => _handleApprove(item.id, false),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
