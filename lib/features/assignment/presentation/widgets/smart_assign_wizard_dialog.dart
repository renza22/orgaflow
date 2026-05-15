import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../domain/models/assignment_member_option.dart';
import '../../domain/models/smart_assign_recommendation_model.dart';
import '../presenters/assign_task_presenter.dart';
import 'smart_assign_candidate_card.dart';

class SmartAssignWizardDialog extends StatefulWidget {
  SmartAssignWizardDialog({
    super.key,
    required this.taskId,
    required this.taskTitle,
    AssignTaskPresenter? presenter,
    this.assignableMembers,
    this.isLoadingAssignableMembers = false,
    this.assignableMembersError,
    this.onAssigned,
  }) : presenter = presenter ?? AssignTaskPresenter();

  final String taskId;
  final String taskTitle;
  final AssignTaskPresenter presenter;
  final List<AssignmentMemberOption>? assignableMembers;
  final bool isLoadingAssignableMembers;
  final String? assignableMembersError;
  final Future<void> Function()? onAssigned;

  @override
  State<SmartAssignWizardDialog> createState() =>
      _SmartAssignWizardDialogState();
}

class _SmartAssignWizardDialogState extends State<SmartAssignWizardDialog> {
  late final TextEditingController _thresholdController;

  List<SmartAssignRecommendationModel> _recommendations = const [];
  Timer? _thresholdDebounce;
  bool _isLoading = true;
  String? _errorMessage;
  String? _thresholdError;
  String? _assigningMemberId;
  String? _manualMemberId;
  bool _isManualAssigning = false;
  double _thresholdPercent = 120;
  int _requestSerial = 0;

  bool get _isSaving => _assigningMemberId != null || _isManualAssigning;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(text: '120');
    _loadRecommendations();
  }

  @override
  void dispose() {
    _thresholdDebounce?.cancel();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    if (_thresholdError != null) {
      return;
    }

    final taskId = widget.taskId.trim();
    if (taskId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Task tidak valid.';
      });
      return;
    }

    final requestSerial = ++_requestSerial;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.presenter.loadSmartRecommendations(
      taskId: taskId,
      limit: 3,
      hardOverloadThreshold: _thresholdPercent / 100,
    );

    if (!mounted || requestSerial != _requestSerial) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _recommendations = const [];
        _isLoading = false;
        _errorMessage = result.error!.message;
      });
      return;
    }

    setState(() {
      _recommendations = result.data ?? const [];
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _scheduleRecommendationsReload() {
    _thresholdDebounce?.cancel();
    _thresholdDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadRecommendations,
    );
  }

  void _handleSliderChanged(double value) {
    final percent = value.roundToDouble();
    setState(() {
      _thresholdPercent = percent;
      _thresholdError = null;
      _thresholdController.text = _formatThreshold(percent);
      _thresholdController.selection = TextSelection.collapsed(
        offset: _thresholdController.text.length,
      );
    });
    _scheduleRecommendationsReload();
  }

  void _handleThresholdTextChanged(String value) {
    final normalized = value.trim().replaceAll('%', '').replaceAll(',', '.');
    final parsed = double.tryParse(normalized);

    if (parsed == null) {
      _thresholdDebounce?.cancel();
      setState(() {
        _thresholdError = 'Masukkan angka threshold yang valid.';
      });
      return;
    }

    if (parsed < 100 || parsed > 200) {
      _thresholdDebounce?.cancel();
      setState(() {
        _thresholdError = 'Threshold harus di antara 100% sampai 200%.';
      });
      return;
    }

    setState(() {
      _thresholdPercent = parsed;
      _thresholdError = null;
    });
    _scheduleRecommendationsReload();
  }

  Future<void> _assignRecommendation(
    SmartAssignRecommendationModel recommendation,
  ) async {
    if (_isSaving) {
      return;
    }

    if (recommendation.isRiskyAlert) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi assignment'),
          content: const Text(
            'Kandidat ini berisiko meningkatkan beban kerja. '
            'Lanjutkan assignment?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
    }

    await _assignMember(recommendation.memberId);
  }

  Future<void> _assignManualMember() async {
    if (_isSaving) {
      return;
    }

    final memberId = _manualMemberId;
    if (memberId == null || memberId.trim().isEmpty) {
      _showMessage('Pilih member terlebih dahulu.');
      return;
    }

    await _assignMember(memberId, isManual: true);
  }

  Future<void> _assignMember(
    String memberId, {
    bool isManual = false,
  }) async {
    setState(() {
      if (isManual) {
        _isManualAssigning = true;
      } else {
        _assigningMemberId = memberId;
      }
    });

    final result = await widget.presenter.assignTask(
      taskId: widget.taskId,
      memberId: memberId,
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      final message = result.error!.message;
      setState(() {
        _assigningMemberId = null;
        _isManualAssigning = false;
      });

      if (ErrorMapper.isOverloadErrorMessage(message)) {
        await _showOverloadDialog(message);
        return;
      }

      _showMessage(message);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final onAssigned = widget.onAssigned;

    Navigator.of(context).pop(true);

    if (onAssigned != null) {
      await onAssigned();
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('Task berhasil ditugaskan')),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showOverloadDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overload Terdeteksi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 640;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 32,
        vertical: 24,
      ),
      child: Container(
        width: isSmallScreen ? screenWidth - 32 : 760,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildThresholdControl(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecommendationContent(),
                    _buildManualAssignSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Assign Wizard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.taskTitle.trim().isNotEmpty
                      ? widget.taskTitle.trim()
                      : 'Task',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdControl() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hard overload threshold',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              SizedBox(
                width: 86,
                child: TextField(
                  controller: _thresholdController,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: _handleThresholdTextChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: '%',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6C5CE7),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color(0xFF6C5CE7),
              overlayColor: const Color(0xFF6C5CE7).withValues(alpha: 0.18),
              trackHeight: 4,
            ),
            child: Slider(
              value: _thresholdPercent.clamp(100.0, 200.0).toDouble(),
              min: 100,
              max: 200,
              divisions: 100,
              label: '${_formatThreshold(_thresholdPercent)}%',
              onChanged: _isSaving ? null : _handleSliderChanged,
            ),
          ),
          if (_thresholdError != null) ...[
            const SizedBox(height: 4),
            Text(
              _thresholdError!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildStateMessage(
        icon: Icons.error_outline,
        title: 'Rekomendasi gagal dimuat',
        message: _errorMessage!,
        actionLabel: 'Retry',
        onAction: _thresholdError == null ? _loadRecommendations : null,
      );
    }

    if (_recommendations.isEmpty) {
      return _buildStateMessage(
        icon: Icons.person_search_outlined,
        title: 'Belum ada kandidat',
        message: 'Tidak ada kandidat yang lolos filter Smart Assign saat ini.',
        actionLabel: 'Retry',
        onAction: _thresholdError == null ? _loadRecommendations : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top ${_recommendations.length} kandidat',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        ..._recommendations.map(
          (recommendation) => SmartAssignCandidateCard(
            recommendation: recommendation,
            isAssigning: _assigningMemberId == recommendation.memberId,
            isDisabled: _isSaving,
            onAssign: () => _assignRecommendation(recommendation),
          ),
        ),
      ],
    );
  }

  Widget _buildStateMessage({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.grey.shade500),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualAssignSection() {
    final members = widget.assignableMembers;
    if (members == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: _recommendations.isEmpty ? 0 : 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assign Manual',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          if (widget.isLoadingAssignableMembers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (widget.assignableMembersError?.trim().isNotEmpty == true)
            Text(
              widget.assignableMembersError!.trim(),
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            )
          else if (members.isEmpty)
            Text(
              'Belum ada anggota aktif',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _manualMemberId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Pilih member',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: members
                        .map(
                          (member) => DropdownMenuItem<String>(
                            value: member.id,
                            child: Text(
                              member.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() {
                              _manualMemberId = value;
                            }),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSaving ? null : _assignManualMember,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111827),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isManualAssigning ? 'Assigning...' : 'Assign',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatThreshold(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}
