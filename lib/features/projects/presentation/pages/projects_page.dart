import 'package:flutter/material.dart';

import '../../../../core/navigation/app_route_observer.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../../../project/presentation/presenters/projects_presenter.dart';
import '../../models/project_detail_model.dart';
import 'project_board_page.dart';

enum _ProjectCardAction { edit, delete }

enum _ProjectDialogResult { created, updated }

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ProjectsPresenter _presenter = ProjectsPresenter();

  ModalRoute<dynamic>? _route;
  List<ProjectDetail> _projects = const [];
  bool _isLoading = true;
  bool _canManageProjects = false;
  String? _errorMessage;

  int get _totalProjects => _projects.length;

  int get _activeProjects => _projects
      .where((project) => project.status == ProjectStatus.active)
      .length;

  int get _totalTasks =>
      _projects.fold(0, (sum, project) => sum + project.tasks.total);

  int get _avgCompletion {
    if (_projects.isEmpty) {
      return 0;
    }

    final totalProgress =
        _projects.fold(0, (sum, project) => sum + project.progress);
    return (totalProgress / _projects.length).round();
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
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
    _loadProjects();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<bool> _loadProjects() async {
    final previousProjects = List<ProjectDetail>.from(_projects);

    setState(() {
      _isLoading = true;
      if (previousProjects.isEmpty) {
        _errorMessage = null;
      }
    });

    final fetchProjectsFuture = _presenter.fetchProjects();
    final canManageFuture = _presenter.canManageProjects();

    final projectResult = await fetchProjectsFuture;
    final canManageProjects = await canManageFuture;

    if (!mounted) {
      return false;
    }

    if (projectResult.isFailure) {
      setState(() {
        _projects = previousProjects;
        _canManageProjects = canManageProjects;
        _isLoading = false;
        _errorMessage =
            previousProjects.isEmpty ? projectResult.error!.message : null;
      });
      return false;
    }

    setState(() {
      _projects = projectResult.data!
          .map((project) => ProjectDetail.fromProjectModel(project))
          .toList();
      _canManageProjects = canManageProjects;
      _isLoading = false;
      _errorMessage = null;
    });

    return true;
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _openProjectBoard(ProjectDetail project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectBoardPage(
          projectId: project.id,
          projectName: project.name,
          projectDescription: project.description,
        ),
      ),
    );
  }

  Future<void> _showProjectDialog({
    ProjectDetail? project,
  }) async {
    if (!_canManageProjects) {
      return;
    }

    final isEditing = project != null;
    final nameController = TextEditingController(text: project?.name ?? '');
    final descController = TextEditingController(
      text: project?.description == '-' ? '' : project?.description ?? '',
    );
    DateTime? selectedDate = project?.dueDate;
    var isSubmitting = false;

    final dialogResult = await showDialog<_ProjectDialogResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submitProject() async {
              final name = nameController.text.trim();
              final description = descController.text.trim();
              final isValid = name.isNotEmpty &&
                  description.isNotEmpty &&
                  (selectedDate != null || isEditing);

              if (!isValid) {
                _showSnackBar(
                  'Mohon lengkapi semua field',
                  backgroundColor: Colors.red,
                );
                return;
              }

              setDialogState(() {
                isSubmitting = true;
              });

              final result = isEditing
                  ? await _presenter.updateProject(
                      projectId: project.id,
                      name: name,
                      description: description,
                      endDate: selectedDate,
                    )
                  : await _presenter.createProject(
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
                _showSnackBar(
                  result.error!.message,
                  backgroundColor: Colors.red,
                );
                return;
              }

              Navigator.of(dialogContext).pop(
                isEditing
                    ? _ProjectDialogResult.updated
                    : _ProjectDialogResult.created,
              );
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
                        Text(
                          isEditing ? 'Edit Proyek' : 'Buat Proyek Baru',
                          style: const TextStyle(
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
                      decoration: _buildDialogInputDecoration(
                        hintText: 'Contoh: Inaugurasi 2024',
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
                      decoration: _buildDialogInputDecoration(
                        hintText: 'Jelaskan tujuan dan detail proyek',
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
                              final now = DateTime.now();
                              final firstDate = selectedDate != null &&
                                      selectedDate!.isBefore(now)
                                  ? DateTime(
                                      selectedDate!.year,
                                      selectedDate!.month,
                                      selectedDate!.day,
                                    )
                                  : DateTime(now.year, now.month, now.day);
                              final initialDate = selectedDate ?? firstDate;
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: initialDate,
                                firstDate: firstDate,
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
                                  ? _formatDialogDate(selectedDate!)
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
                          child: Text(
                            isEditing ? 'Simpan Perubahan' : 'Buat Proyek',
                            style: const TextStyle(
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
        );
      },
    );

    nameController.dispose();
    descController.dispose();

    if (dialogResult == null) {
      return;
    }

    final refreshed = await _loadProjects();

    if (!mounted) {
      return;
    }

    if (!refreshed) {
      _showSnackBar(
        'Proyek berhasil disimpan, tetapi daftar gagal dimuat ulang.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    _showSnackBar(
      dialogResult == _ProjectDialogResult.updated
          ? 'Proyek berhasil diperbarui!'
          : 'Proyek berhasil ditambahkan!',
      backgroundColor: Colors.green,
    );
  }

  Future<void> _confirmDeleteProject(ProjectDetail project) async {
    if (!_canManageProjects) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Proyek'),
          content: Text('Apakah Anda yakin ingin menghapus ${project.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final result = await _presenter.deleteProject(project.id);
    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      _showSnackBar(
        result.error!.message,
        backgroundColor: Colors.red,
      );
      return;
    }

    await _loadProjects();
    if (!mounted) {
      return;
    }

    _showSnackBar(
      'Proyek berhasil dihapus!',
      backgroundColor: Colors.green,
    );
  }

  InputDecoration _buildDialogInputDecoration({
    required String hintText,
  }) {
    return InputDecoration(
      hintText: hintText,
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
    );
  }

  String _formatDialogDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
              child: ResponsiveSidebar(currentRoute: '/projects'),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/projects'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
                              'Kelola Proyek',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 24 : 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Track progress dan manage semua proyek organisasi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isSmallScreen && _canManageProjects)
                        ElevatedButton.icon(
                          onPressed: () => _showProjectDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Projek'),
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
                  const SizedBox(height: 24),
                  _buildStatsCards(isSmallScreen),
                  const SizedBox(height: 24),
                  _buildProjectsGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen && _canManageProjects
          ? FloatingActionButton(
              onPressed: () => _showProjectDialog(),
              backgroundColor: const Color(0xFF6C5CE7),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStatsCards(bool isSmallScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildStatCard('Total Projects', '$_totalProjects', null, null),
          const SizedBox(height: 12),
          _buildStatCard(
            'Active',
            '$_activeProjects',
            const Color(0xFF6C5CE7),
            const Color(0xFF6C5CE7).withValues(alpha: 0.05),
          ),
          const SizedBox(height: 12),
          _buildStatCard('Total Tasks', '$_totalTasks', null, null),
          const SizedBox(height: 12),
          _buildStatCard('Avg. Completion', '$_avgCompletion%', null, null),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child:
              _buildStatCard('Total Projects', '$_totalProjects', null, null),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active',
            '$_activeProjects',
            const Color(0xFF6C5CE7),
            const Color(0xFF6C5CE7).withValues(alpha: 0.05),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Total Tasks', '$_totalTasks', null, null),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              _buildStatCard('Avg. Completion', '$_avgCompletion%', null, null),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color? textColor,
    Color? bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _loadProjects(),
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

    if (_projects.isEmpty) {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        var crossAxisCount = 1;
        if (constraints.maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth >= 768) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.0,
          ),
          itemCount: _projects.length,
          itemBuilder: (context, index) {
            return _buildProjectCard(_projects[index]);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(ProjectDetail project) {
    final statusConfig = project.statusBadgeConfig;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openProjectBoard(project),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: project.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          project.initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (_canManageProjects)
                      PopupMenuButton<_ProjectCardAction>(
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade400,
                        ),
                        onSelected: (action) {
                          switch (action) {
                            case _ProjectCardAction.edit:
                              _showProjectDialog(project: project);
                              break;
                            case _ProjectCardAction.delete:
                              _confirmDeleteProject(project);
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<_ProjectCardAction>(
                            value: _ProjectCardAction.edit,
                            child: Text('Edit'),
                          ),
                          PopupMenuItem<_ProjectCardAction>(
                            value: _ProjectCardAction.delete,
                            child: Text('Hapus'),
                          ),
                        ],
                      )
                    else
                      const SizedBox(width: 48, height: 48),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusConfig.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusConfig.textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  project.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
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
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
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
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.dueDateLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${project.members}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    children: [
                      TextSpan(
                        text: '${project.tasks.completed}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: ' / ${project.tasks.total} tasks completed',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _openProjectBoard(project),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Task Board',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          _showSnackBar('Membuka DAG ${project.name}');
                        },
                        icon: const Icon(Icons.account_tree, size: 14),
                        label: const Text(
                          'DAG',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
