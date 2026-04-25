import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../widgets/overview_tab.dart';
import '../widgets/kanban_tab.dart';
import '../widgets/workflow_tab.dart';
import '../widgets/team_tab.dart';

class ProjectBoardPage extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String projectDescription;

  const ProjectBoardPage({
    super.key,
    required this.projectId,
    required this.projectName,
    this.projectDescription = '',
  });

  @override
  State<ProjectBoardPage> createState() => _ProjectBoardPageState();
}

class _ProjectBoardPageState extends State<ProjectBoardPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  final List<Task> _tasks = [
    Task(
      id: 1,
      title: "Desain Banner Utama",
      description: "Membuat desain banner untuk acara inaugurasi",
      assignee: "Sarah Chen",
      status: TaskStatus.inProgress,
      estimatedHours: 5,
      skills: ["Design", "Creative"],
      dependencies: [],
    ),
    Task(
      id: 2,
      title: "Persiapan Venue",
      description: "Survey dan booking venue untuk acara",
      assignee: "Mike Johnson",
      status: TaskStatus.done,
      estimatedHours: 8,
      skills: ["Event Management"],
      dependencies: [],
    ),
    Task(
      id: 3,
      title: "Cetak Banner",
      description: "Cetak banner setelah desain selesai",
      assignee: "",
      status: TaskStatus.todo,
      estimatedHours: 3,
      skills: ["Logistik"],
      dependencies: [1],
    ),
    Task(
      id: 4,
      title: "Buat Rundown Acara",
      description: "Menyusun timeline detail acara inaugurasi",
      assignee: "",
      status: TaskStatus.backlog,
      estimatedHours: 4,
      skills: ["Event Management"],
      dependencies: [],
    ),
    Task(
      id: 5,
      title: "Brief MC dan Moderator",
      description: "Koordinasi dengan MC tentang rundown",
      assignee: "Emma Davis",
      status: TaskStatus.todo,
      estimatedHours: 2,
      skills: ["Public Speaking"],
      dependencies: [4],
    ),
  ];

  final List<KanbanColumn> _columns = [
    KanbanColumn(id: "backlog", title: "Backlog", status: TaskStatus.backlog, color: 0xFF718096),
    KanbanColumn(id: "todo", title: "Todo", status: TaskStatus.todo, color: 0xFF00CEC9),
    KanbanColumn(id: "in-progress", title: "In Progress", status: TaskStatus.inProgress, color: 0xFF6C5CE7),
    KanbanColumn(id: "done", title: "Done", status: TaskStatus.done, color: 0xFF00B894),
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentIndex) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _moveTask(int taskId, TaskStatus newStatus) {
    setState(() {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);
      }
    });
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddTaskDialog(
        existingTasks: _tasks,
        onAddTask: (task) {
          setState(() {
            _tasks.add(task);
          });
        },
      ),
    );
  }

  int get _daysRemaining {
    // Demo: 18 days remaining
    return 18;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/projects'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project Header
                  _buildProjectHeader(isSmallScreen),
                  // Tab Bar
                  _buildTabBar(),
                  // Tab Content
                  _buildCurrentTabContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isSmallScreen
          ? FloatingActionButton(
              onPressed: _showAddTaskDialog,
              backgroundColor: const Color(0xFF6C5CE7),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentIndex) {
      case 0:
        return OverviewTab(
          tasks: _tasks,
          dueDate: DateTime.now().add(Duration(days: _daysRemaining)),
          projectDescription: 'Acara pelantikan pengurus baru organisasi mahasiswa periode 2024/2025',
        );
      case 1:
        return KanbanTab(
          tasks: _tasks,
          columns: _columns,
          onMoveTask: _moveTask,
          onAddTask: _showAddTaskDialog,
        );
      case 2:
        return WorkflowTab(tasks: _tasks);
      case 3:
        return TeamTab(projectId: widget.projectId);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProjectHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(isSmallScreen ? 16 : 28, 20, isSmallScreen ? 16 : 28, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF374151)),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.projectName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                ),
                if (widget.projectDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.projectDescription,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Countdown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00CEC9), Color(0xFF00B894)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00CEC9).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '${_daysRemaining}d',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 14),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: const Color(0xFF6C5CE7),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF6C5CE7),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Papan Tugas (Kanban)'),
          Tab(text: 'Alur Kerja (Graph)'),
          Tab(text: 'Tim'),
        ],
      ),
    );
  }
}

// ─── Add Task Dialog (preserved from original) ──────────────

class _AddTaskDialog extends StatefulWidget {
  final List<Task> existingTasks;
  final Function(Task) onAddTask;

  const _AddTaskDialog({
    required this.existingTasks,
    required this.onAddTask,
  });

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _skillSearchController = TextEditingController();

  final List<String> _availableSkills = [
    "Design", "Creative", "Event Management", "Logistik",
    "Public Speaking", "Technical Writing", "Photography",
    "Videography", "Social Media", "Backend", "Frontend",
  ];

  final List<String> _selectedSkills = [];
  final List<int> _selectedDependencies = [];
  String _skillSearch = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (_titleController.text.isEmpty || _hoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan bobot jam harus diisi')),
      );
      return;
    }

    final newTask = Task(
      id: widget.existingTasks.isNotEmpty
          ? widget.existingTasks.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1
          : 1,
      title: _titleController.text,
      description: _descriptionController.text,
      assignee: '',
      status: TaskStatus.backlog,
      estimatedHours: double.tryParse(_hoursController.text) ?? 0,
      skills: _selectedSkills,
      dependencies: _selectedDependencies,
    );

    widget.onAddTask(newTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredSkills = _availableSkills
        .where((skill) =>
            skill.toLowerCase().contains(_skillSearch.toLowerCase()) &&
            !_selectedSkills.contains(skill))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                const Text('Input Task Manual',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Judul Task', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Cetak Banner',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Deskripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan detail task yang harus dikerjakan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Bobot Jam (Estimasi Waktu)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _hoursController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '5',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('jam', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    ]),
                    const SizedBox(height: 20),
                    const Text('Skill Tags', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_selectedSkills.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _selectedSkills.map((skill) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C5CE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(skill, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => setState(() => _selectedSkills.remove(skill)),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ]),
                          )).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _skillSearchController,
                      onChanged: (v) => setState(() => _skillSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Cari atau pilih skill...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_skillSearch.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: filteredSkills.isNotEmpty
                            ? Wrap(
                                spacing: 8, runSpacing: 8,
                                children: filteredSkills.map((skill) => InkWell(
                                  onTap: () => setState(() {
                                    _selectedSkills.add(skill);
                                    _skillSearchController.clear();
                                    _skillSearch = '';
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(skill, style: const TextStyle(fontSize: 13)),
                                  ),
                                )).toList(),
                              )
                            : Center(child: Text('Tidak ada skill yang cocok',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                      ),
                    if (_skillSearch.isEmpty)
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _availableSkills
                            .where((s) => !_selectedSkills.contains(s))
                            .take(6)
                            .map((skill) => InkWell(
                                  onTap: () => setState(() => _selectedSkills.add(skill)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('+ $skill', style: const TextStyle(fontSize: 12)),
                                  ),
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 20),
                    const Text('Dependency (Prasyarat Task)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: widget.existingTasks.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              itemCount: widget.existingTasks.length,
                              itemBuilder: (context, index) {
                                final task = widget.existingTasks[index];
                                return CheckboxListTile(
                                  value: _selectedDependencies.contains(task.id),
                                  onChanged: (value) => setState(() {
                                    if (value == true) {
                                      _selectedDependencies.add(task.id);
                                    } else {
                                      _selectedDependencies.remove(task.id);
                                    }
                                  }),
                                  title: Text(task.title,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                  subtitle: Text(task.description,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  dense: true,
                                );
                              },
                            )
                          : Center(child: Text('Belum ada task lain',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tambah Task'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
