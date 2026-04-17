import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/session/session_context.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/supabase_config.dart';
import '../../../../core/utils/message_helper.dart';
import '../../../project/presentation/presenters/projects_presenter.dart';
import '../../models/project_model.dart';
import '../../../organization/data/repositories/organization_repository.dart';
import '../../../projects/presentation/pages/project_board_page.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  static const String _organizationLogosBucket = 'organization-logos';

  bool _isGridView = true;
  String _currentTime = '';
  Timer? _timer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final OrganizationRepository _organizationRepository =
      OrganizationRepository();
  final ProjectsPresenter _projectsPresenter = ProjectsPresenter();
  final ImagePicker _imagePicker = ImagePicker();
  SessionContext? _sessionContext;
  ModalRoute<dynamic>? _route;
  List<Project> _projects = const [];
  bool _isLoadingSessionContext = false;
  bool _isLoadingProjects = true;
  bool _isUploadingOrganizationLogo = false;
  int? _organizationLogoVersion;
  String? _projectErrorMessage;

  @override
  void initState() {
    super.initState();
    _updateTime();
    unawaited(_loadSessionContext());
    unawaited(_loadProjects());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route == null || route == _route) {
      return;
    }

    if (_route != null) {
      appRouteObserver.unsubscribe(this);
    }

    _route = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    unawaited(_loadProjects());
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _loadSessionContext({
    bool refresh = false,
  }) async {
    if (_isLoadingSessionContext) {
      return;
    }

    setState(() {
      _isLoadingSessionContext = true;
    });

    try {
      final contextData = await sessionService.getCurrentContext(
        refresh: refresh,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _sessionContext = contextData;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      MessageHelper.showSnackBar(
        context,
        ErrorMapper.map(error).message,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSessionContext = false;
        });
      }
    }
  }

  bool get _canEditOrganizationLogo {
    final role = _sessionContext?.activeMember?.role;
    return role == 'owner' || role == 'admin';
  }

  Future<bool> _loadProjects() async {
    final previousProjects = List<Project>.from(_projects);

    setState(() {
      _isLoadingProjects = true;
      if (previousProjects.isEmpty) {
        _projectErrorMessage = null;
      }
    });

    final result = await _projectsPresenter.fetchProjects();

    if (!mounted) {
      return false;
    }

    if (result.isFailure) {
      setState(() {
        _projects = previousProjects;
        _isLoadingProjects = false;
        _projectErrorMessage =
            previousProjects.isEmpty ? result.error!.message : null;
      });

      if (previousProjects.isNotEmpty) {
        MessageHelper.showSnackBar(context, result.error!.message);
      }

      return false;
    }

    setState(() {
      _projects = result.data!
          .map((project) => Project.fromProjectModel(project))
          .toList();
      _isLoadingProjects = false;
      _projectErrorMessage = null;
    });

    return true;
  }

  Future<void> _handleOrganizationLogoTap() async {
    if (_isLoadingSessionContext ||
        _isUploadingOrganizationLogo ||
        !_canEditOrganizationLogo) {
      return;
    }

    final organization = _sessionContext?.organization;
    if (organization == null) {
      return;
    }

    XFile? pickedImage;
    try {
      pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
    } catch (_) {
      if (mounted) {
        MessageHelper.showSnackBar(context, 'Gagal membuka galeri gambar.');
      }
      return;
    }

    if (!mounted || pickedImage == null) {
      return;
    }

    setState(() {
      _isUploadingOrganizationLogo = true;
    });

    final result = await _organizationRepository.uploadOrganizationLogo(
      organizationId: organization.id,
      existingLogoPath: organization.logoPath,
      imageFile: pickedImage,
    );

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _isUploadingOrganizationLogo = false;
      });
      MessageHelper.showSnackBar(context, result.error!.message);
      return;
    }

    _organizationLogoVersion = DateTime.now().millisecondsSinceEpoch;
    await _loadSessionContext(refresh: true);

    if (!mounted) {
      return;
    }

    setState(() {
      _isUploadingOrganizationLogo = false;
    });
  }

  String? _buildOrganizationLogoUrl() {
    final logoPath = _sessionContext?.organization?.logoPath;
    if (logoPath == null || logoPath.isEmpty) {
      return null;
    }

    final publicUrl =
        supabase.storage.from(_organizationLogosBucket).getPublicUrl(logoPath);
    final version = _organizationLogoVersion ??
        _sessionContext?.organization?.updatedAt?.millisecondsSinceEpoch;

    if (version == null) {
      return publicUrl;
    }

    final uri = Uri.parse(publicUrl);
    final queryParameters = Map<String, String>.from(uri.queryParameters);
    queryParameters['v'] = version.toString();
    return uri.replace(queryParameters: queryParameters).toString();
  }

  Widget _buildOrganizationLogoPlaceholder() {
    return const Icon(
      Icons.image_outlined,
      color: Colors.grey,
      size: 28,
    );
  }

  Widget _buildOrganizationLogoContent() {
    final logoUrl = _buildOrganizationLogoUrl();
    if (logoUrl == null) {
      return _buildOrganizationLogoPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        logoUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildOrganizationLogoPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildOrganizationLogoPlaceholder();
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return "🌤️ Selamat Siang";
    if (hour >= 12 && hour < 18) return "☀️ Selamat Siang";
    return "🌙 Selamat Malam";
  }

  int get _totalPendingTasks =>
      _projects.fold(0, (sum, project) => sum + project.pendingTasks);

  int get _totalProjects => _projects.length;

  int get _activeProjects =>
      _projects.where((project) => project.status == 'active').length;

  List<Project> get _upcomingDeadlines =>
      _projects.where((project) => project.hasUpcomingDeadline).toList();

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
              child: ResponsiveSidebar(currentRoute: '/'),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for desktop
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/'),

          // Main Content
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeader(isSmallScreen),
                    const SizedBox(height: 24),

                    // Summary Cards
                    _buildSummaryCards(isSmallScreen),
                    const SizedBox(height: 32),

                    // Project List Header
                    _buildProjectListHeader(isSmallScreen),
                    const SizedBox(height: 24),

                    // Project Grid
                    _buildProjectGrid(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    final organizationName = _sessionContext?.organization?.name;

    return Row(
      children: [
        // Logo and Greeting
        GestureDetector(
          onTap: _canEditOrganizationLogo ? _handleOrganizationLogoTap : null,
          child: Container(
            width: isSmallScreen ? 40 : 56,
            height: isSmallScreen ? 40 : 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildOrganizationLogoContent(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6C5CE7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                organizationName == null || organizationName.trim().isEmpty
                    ? 'Himpunan Mahasiswa Teknik Informatika'
                    : organizationName,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Administrator: Admin User',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Clock and Date
        if (!isSmallScreen) ...[
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    _getCurrentDate(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Digital Clock
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentTime,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    final months = [
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
      'Des'
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _showAddProjectDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    DateTime? selectedDate;
    var isSubmitting = false;

    final dialogResult = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> submitProject() async {
            final name = nameController.text.trim();
            final description = descController.text.trim();

            if (name.isEmpty || description.isEmpty || selectedDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mohon lengkapi semua field'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            setDialogState(() {
              isSubmitting = true;
            });

            final result = await _projectsPresenter.createProject(
              name: name,
              description: description,
              endDate: selectedDate,
            );

            if (!mounted || !dialogContext.mounted) {
              return;
            }

            if (result.isFailure) {
              setDialogState(() {
                isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.error!.message),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            Navigator.pop(dialogContext, true);
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Buat Proyek Baru',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nama Proyek',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Inaugurasi 2024',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5CE7),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Jelaskan tujuan dan detail proyek',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF6C5CE7),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Deadline Proyek',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: isSubmitting
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF6C5CE7),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (date != null && dialogContext.mounted) {
                              setDialogState(() {
                                selectedDate = date;
                              });
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedDate != null
                                ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
                                : 'dd/mm/yyyy',
                            style: TextStyle(
                              color: selectedDate != null
                                  ? Colors.black
                                  : Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSubmitting
                            ? null
                            : () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : submitProject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Buat Proyek',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    nameController.dispose();
    descController.dispose();

    if (dialogResult != true) {
      return;
    }

    final refreshed = await _loadProjects();

    if (!mounted) {
      return;
    }

    if (!refreshed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Proyek berhasil disimpan, tetapi daftar gagal dimuat ulang.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Proyek berhasil ditambahkan!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildSummaryCard(
            'Ringkasan Proyek',
            '$_totalProjects',
            Icons.folder_outlined,
            const Color(0xFF6C5CE7),
            _activeProjects == 0
                ? 'Aktif berjalan'
                : '$_activeProjects aktif berjalan',
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Task Pending',
            '$_totalPendingTasks',
            Icons.list_alt,
            const Color(0xFF00CEC9),
            'Menunggu penyelesaian',
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            'Quick Alert',
            '${_upcomingDeadlines.length}',
            Icons.warning_amber_rounded,
            const Color(0xFFFF6B6B),
            'Tenggat waktu < 14 hari',
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Ringkasan Proyek',
            '$_totalProjects',
            Icons.folder_outlined,
            const Color(0xFF6C5CE7),
            _activeProjects == 0
                ? 'Aktif berjalan'
                : '$_activeProjects aktif berjalan',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Task Pending',
            '$_totalPendingTasks',
            Icons.list_alt,
            const Color(0xFF00CEC9),
            'Menunggu penyelesaian',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Quick Alert',
            '${_upcomingDeadlines.length}',
            Icons.warning_amber_rounded,
            const Color(0xFFFF6B6B),
            'Tenggat waktu < 14 hari',
          ),
        ),
      ],
    );
  }

  Widget _buildProjectListHeader(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Proyek',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Klik proyek untuk masuk ke Kanban Board',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.grid_view,
                      color:
                          _isGridView ? const Color(0xFF6C5CE7) : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_list,
                      color:
                          !_isGridView ? const Color(0xFF6C5CE7) : Colors.grey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddProjectDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Proyek'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectGrid() {
    final projects = _projects;

    if (_isLoadingProjects) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_projectErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _projectErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loadProjects,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (projects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Belum ada proyek',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isGridView) {
      return LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth >= 1200) {
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
              childAspectRatio: 1.1,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              return _buildProjectCard(projects[index]);
            },
          );
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildProjectListCard(projects[index]);
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Membuka detail: $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: color,
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

  Widget _buildProjectCard(Project project) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectBoardPage(
              projectId: project.id,
              projectName: project.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: project.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(project.icon, color: Colors.white, size: 28),
                ),
                if (project.isUrgent || project.isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          project.isOverdue ? 'Overdue' : 'Urgent',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progress',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  '${project.progress}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: project.progress / 100,
                backgroundColor: Colors.grey.shade200,
                color: project.color,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${project.completedTasks} / ${project.totalTasks} task selesai',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        project.deadlineLabel,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Text(
                    project.deadlineStatusLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: project.isOverdue
                          ? Colors.red
                          : project.isUrgent
                              ? Colors.orange
                              : project.deadline == null
                                  ? Colors.grey.shade600
                                  : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectListCard(Project project) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectBoardPage(
              projectId: project.id,
              projectName: project.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: project.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(project.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress', style: TextStyle(fontSize: 12)),
                      Text('${project.progress}%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: project.progress / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: project.color,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
