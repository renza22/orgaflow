import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/message_helper.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../../../profile/domain/models/profile_task_history_model.dart';
import '../../../profile/domain/models/user_profile_detail_model.dart';
import '../../../profile/presentation/presenters/profile_presenter.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({
    super.key,
    required this.memberId,
    this.memberName,
    this.showEditButton = false,
    this.isCurrentUser = false,
    this.sidebarRoute = '/members',
  });

  final String memberId;
  final String? memberName;
  final bool showEditButton;
  final bool isCurrentUser;
  final String sidebarRoute;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProfilePresenter _presenter = ProfilePresenter();

  UserProfileDetailModel? _profile;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  bool get _canEdit => widget.showEditButton && widget.isCurrentUser;
  Key get _sidebarKey => ValueKey(
        'profile-sidebar-${_profile?.avatarPath ?? ''}-${_profile?.fullName ?? ''}',
      );

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant MemberProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final result = await _presenter.loadProfileDetail(widget.memberId);

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

    setState(() {
      _profile = result.data!;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final profile = _profile;
    if (!_canEdit || profile == null || _isUploadingAvatar) {
      return;
    }

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });

    final result = await _presenter.uploadProfileAvatar(
      profileId: profile.profileId,
      imageFile: pickedFile,
      existingAvatarPath: profile.avatarPath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isUploadingAvatar = false;
    });

    if (result.isFailure) {
      MessageHelper.showSnackBar(context, result.error!.message);
      return;
    }

    MessageHelper.showSnackBar(context, 'Foto profile berhasil diperbarui.');
    await _loadProfile(showLoading: false);
  }

  Future<void> _showEditProfileDialog() async {
    final profile = _profile;
    if (!_canEdit || profile == null) {
      return;
    }

    final nameController = TextEditingController(text: profile.fullName);
    final nimController = TextEditingController(text: profile.nim ?? '');
    final bioController = TextEditingController(text: profile.bio ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
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
              _buildTextField('Nama', nameController),
              const SizedBox(height: 16),
              _buildTextField('NIM', nimController),
              const SizedBox(height: 16),
              _buildTextField('Bio', bioController, maxLines: 4),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await _presenter.updateProfile(
                        profileId: profile.profileId,
                        fullName: nameController.text,
                        nim: nimController.text,
                        bio: bioController.text,
                        studyProgramCode: profile.studyProgramCode,
                      );

                      if (!mounted || !dialogContext.mounted) {
                        return;
                      }

                      if (result.isFailure) {
                        MessageHelper.showSnackBar(
                          context,
                          result.error!.message,
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);
                      MessageHelper.showSnackBar(
                        context,
                        'Profile berhasil diperbarui.',
                      );
                      await _loadProfile(showLoading: false);
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

    nameController.dispose();
    nimController.dispose();
    bioController.dispose();
  }

  Future<void> _showEditCapacityDialog() async {
    final profile = _profile;
    if (!_canEdit || profile == null) {
      return;
    }

    final capacityController = TextEditingController(
      text: profile.weeklyCapacityHours.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
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
              _buildTextField(
                'Max Hours per Week',
                capacityController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final value = int.tryParse(
                        capacityController.text.trim(),
                      );
                      if (value == null || value < 0) {
                        MessageHelper.showSnackBar(
                          context,
                          'Kapasitas mingguan harus berupa angka positif.',
                        );
                        return;
                      }

                      final result = await _presenter.updateWeeklyCapacity(
                        memberId: profile.memberId,
                        weeklyCapacityHours: value,
                      );

                      if (!mounted || !dialogContext.mounted) {
                        return;
                      }

                      if (result.isFailure) {
                        MessageHelper.showSnackBar(
                          context,
                          result.error!.message,
                        );
                        return;
                      }

                      Navigator.pop(dialogContext);
                      MessageHelper.showSnackBar(
                        context,
                        'Kapasitas mingguan berhasil diperbarui.',
                      );
                      await _loadProfile(showLoading: false);
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

    capacityController.dispose();
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
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
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
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
              child: ResponsiveSidebar(
                key: _sidebarKey,
                currentRoute: widget.sidebarRoute,
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            ResponsiveSidebar(
              key: _sidebarKey,
              currentRoute: widget.sidebarRoute,
            ),
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
      floatingActionButton: (_canEdit && isSmallScreen)
          ? FloatingActionButton(
              onPressed: _showEditProfileDialog,
              backgroundColor: const Color(0xFF6C5CE7),
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          },
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
                      widget.memberName == null
                          ? 'View member details'
                          : widget.memberName!,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_canEdit && !isSmallScreen)
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
    );
  }

  Widget _buildBody(bool isSmallScreen) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    final profile = _profile;
    if (profile == null) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        message: 'Profile anggota tidak ditemukan.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.33,
                child: _buildProfileCard(profile, isSmallScreen),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildMainContent(profile, isSmallScreen),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildProfileCard(profile, isSmallScreen),
            const SizedBox(height: 24),
            _buildMainContent(profile, isSmallScreen),
          ],
        );
      },
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
              onPressed: _loadProfile,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
    final statusColor = _workloadStatusColor(profile.workloadStatus);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              _buildAvatar(profile, isSmallScreen ? 80 : 96),
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
              if (_canEdit)
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Tooltip(
                    message: 'Upload foto profile',
                    child: InkWell(
                      onTap: _pickAndUploadAvatar,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C5CE7),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(7),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                size: 15,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            profile.displayRole,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildInfoRow(Icons.email_outlined, profile.email, isSmallScreen),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.badge_outlined, profile.nim, isSmallScreen),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.school_outlined,
            profile.studyProgramLabel ?? profile.studyProgramCode,
            isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.account_tree_outlined,
            profile.displayDivision,
            isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Joined ${_formatDate(profile.joinedAt)}',
            isSmallScreen,
          ),
          if ((profile.bio ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                profile.bio!.trim(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildFairnessCard(profile, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfileDetailModel profile, double size) {
    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF6C5CE7),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            profile.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final avatarUrl = profile.avatarSignedUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return fallback();
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String? text, bool isSmallScreen) {
    final value = text?.trim();
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value == null || value.isEmpty ? '-' : value,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFairnessCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
    final score = profile.fairnessScore;

    return Container(
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
              if (score != null)
                Text(
                  score.toStringAsFixed(
                      score.truncateToDouble() == score ? 0 : 1),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (score == null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Belum ada data fairness',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0).toDouble(),
                backgroundColor: Colors.grey.shade200,
                color: const Color(0xFF6C5CE7),
                minHeight: 8,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
    return Column(
      children: [
        _buildCapacityCard(profile, isSmallScreen),
        const SizedBox(height: 24),
        _buildWorkloadTrendCard(profile, isSmallScreen),
        const SizedBox(height: 24),
        _buildSkillsCard(profile, isSmallScreen),
        const SizedBox(height: 24),
        _buildPortfolioCard(profile, isSmallScreen),
        const SizedBox(height: 24),
        _buildTaskHistoryCard(profile, isSmallScreen),
      ],
    );
  }

  Widget _buildCapacityCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
    final statusColor = _workloadStatusColor(profile.workloadStatus);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_canEdit) ...[
                    OutlinedButton(
                      onPressed: _showEditCapacityDialog,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Update Capacity',
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      profile.workloadStatusLabel,
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
                profile.weeklyCapacityHours <= 0
                    ? 'Belum set kapasitas'
                    : '${profile.assignedHours}h / ${profile.weeklyCapacityHours}h per week',
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
              value: profile.progressValue,
              backgroundColor: Colors.grey.shade200,
              color: statusColor,
              minHeight: isSmallScreen ? 10 : 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Load ratio: ${profile.loadPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadTrendCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
    final trend = profile.workloadTrend;

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
            'Capacity usage from fairness history',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (trend.isEmpty)
            _buildEmptyState(
              icon: Icons.show_chart_outlined,
              message: 'Riwayat workload belum tersedia.',
            )
          else
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
                          final index = value.toInt();
                          if (index >= 0 && index < trend.length) {
                            return Text(
                              trend[index].label,
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
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: trend.length == 1 ? 1 : (trend.length - 1).toDouble(),
                  minY: 0,
                  maxY: _trendMaxY(profile),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trend.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.percentage,
                        );
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

  Widget _buildSkillsCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
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
          if (profile.skills.isEmpty)
            _buildEmptyState(
              icon: Icons.psychology_outlined,
              message: 'Belum ada skill.',
            )
          else
            ...profile.skills.map((skill) {
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                skill.proficiencyLabel,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${skill.proficiencyPercent}%',
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
                        value: skill.proficiencyPercent / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: _proficiencyColor(skill.proficiencyPercent),
                        minHeight: isSmallScreen ? 6 : 8,
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

  Widget _buildPortfolioCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
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
            'Portfolio',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (profile.portfolioLinks.isEmpty)
            _buildEmptyState(
              icon: Icons.link_outlined,
              message: 'Belum ada link portfolio.',
            )
          else
            ...profile.portfolioLinks.map((link) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link.platformLabel,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            link.url,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildTaskHistoryCard(
    UserProfileDetailModel profile,
    bool isSmallScreen,
  ) {
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
          if (profile.taskHistory.isEmpty)
            _buildEmptyState(
              icon: Icons.task_outlined,
              message: 'Belum ada riwayat task.',
            )
          else
            ...profile.taskHistory.map((task) {
              return _buildTaskHistoryItem(task, isSmallScreen);
            }),
        ],
      ),
    );
  }

  Widget _buildTaskHistoryItem(
    ProfileTaskHistoryModel task,
    bool isSmallScreen,
  ) {
    final statusColor = _taskStatusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
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
                  task.projectName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _taskDateText(task),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              task.statusLabel,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 11,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _trendMaxY(UserProfileDetailModel profile) {
    var maxValue = 100.0;
    for (final item in profile.workloadTrend) {
      if (item.percentage > maxValue) {
        maxValue = item.percentage;
      }
    }

    return (((maxValue + 20) / 25).ceil() * 25).toDouble();
  }

  Color _workloadStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'overload':
        return Colors.red.shade900;
      case 'critical':
        return Colors.red.shade600;
      case 'warning':
        return Colors.orange.shade700;
      case 'no_capacity':
        return Colors.grey.shade600;
      case 'safe':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _taskStatusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'done':
        return const Color(0xFF6C5CE7);
      case 'in_progress':
        return Colors.blue.shade700;
      case 'in_review':
        return Colors.teal.shade700;
      case 'blocked':
        return Colors.red.shade600;
      case 'cancelled':
        return Colors.grey.shade700;
      case 'todo':
      case 'backlog':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _proficiencyColor(int proficiency) {
    if (proficiency >= 90) {
      return Colors.green;
    }
    if (proficiency >= 75) {
      return const Color(0xFF6C5CE7);
    }
    if (proficiency >= 60) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  String _taskDateText(ProfileTaskHistoryModel task) {
    final parts = <String>[];
    if (task.assignedAt != null) {
      parts.add('Assigned ${_formatDate(task.assignedAt)}');
    }
    if (task.dueDate != null) {
      parts.add('Due ${_formatDate(task.dueDate)}');
    }
    if (task.allocationHours != null) {
      parts.add('${task.allocationHours}h');
    }
    return parts.isEmpty ? '-' : parts.join(' - ');
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }
}
