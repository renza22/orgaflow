import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class ProjectBoardPage extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ProjectBoardPage({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectBoardPage> createState() => _ProjectBoardPageState();
}

class _ProjectBoardPageState extends State<ProjectBoardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    KanbanColumn(
      id: "backlog",
      title: "Backlog",
      status: TaskStatus.backlog,
      color: 0xFF718096,
    ),
    KanbanColumn(
      id: "todo",
      title: "Todo",
      status: TaskStatus.todo,
      color: 0xFF00CEC9,
    ),
    KanbanColumn(
      id: "in-progress",
      title: "In Progress",
      status: TaskStatus.inProgress,
      color: 0xFF6C5CE7,
    ),
    KanbanColumn(
      id: "done",
      title: "Done",
      status: TaskStatus.done,
      color: 0xFF00B894,
    ),
  ];

  List<Task> _getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
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
        title: widget.projectName,
        subtitle: 'Kanban board untuk manajemen task proyek',
      ),
      drawer: (isSmallScreen || isMediumScreen)
          ? Drawer(
              child: ResponsiveSidebar(currentRoute: '/projects'),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for desktop
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/projects'),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Action Buttons
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isSmallScreen)
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Membuka Dependency Graph')),
                            );
                          },
                          icon: const Icon(Icons.account_tree, size: 16),
                          label: const Text('Dependency Graph'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      if (!isSmallScreen) const SizedBox(width: 12),
                      if (!isSmallScreen)
                        ElevatedButton.icon(
                          onPressed: _showAddTaskDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                // Kanban Board
                Expanded(
                  child: isSmallScreen || isMediumScreen
                      ? _buildScrollableBoard()
                      : _buildGridBoard(),
                ),
              ],
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

  Widget _buildScrollableBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _columns.map((column) {
            final tasks = _getTasksByStatus(column.status);
            return Container(
              width: 320,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column Header
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Color(column.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          column.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            '${tasks.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Column Body
                  Expanded(
                    child: DragTarget<Task>(
                      onWillAcceptWithDetails: (details) =>
                          details.data.status != column.status,
                      onAcceptWithDetails: (details) {
                        _moveTask(details.data.id, column.status);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;
                        return Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isHovering
                                ? Color(column.color).withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isHovering
                                  ? Color(column.color)
                                  : Colors.grey.shade200,
                              width: isHovering ? 2 : 1,
                            ),
                          ),
                          child: tasks.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Drop task here',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: tasks.length,
                                  itemBuilder: (context, index) {
                                    return _buildTaskCard(
                                        tasks[index], column.color);
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGridBoard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _columns.map((column) {
            final tasks = _getTasksByStatus(column.status);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column Header
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Color(column.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            column.title.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              '${tasks.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Column Body
                    Expanded(
                      child: DragTarget<Task>(
                        onWillAcceptWithDetails: (details) =>
                            details.data.status != column.status,
                        onAcceptWithDetails: (details) {
                          _moveTask(details.data.id, column.status);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isHovering = candidateData.isNotEmpty;
                          return Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isHovering
                                  ? Color(column.color).withValues(alpha: 0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isHovering
                                    ? Color(column.color)
                                    : Colors.grey.shade200,
                                width: isHovering ? 2 : 1,
                              ),
                            ),
                            child: tasks.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Text(
                                        'Drop task here',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: tasks.length,
                                    itemBuilder: (context, index) {
                                      return _buildTaskCard(
                                          tasks[index], column.color);
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, int columnColor) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: Opacity(
            opacity: 0.8,
            child: _buildTaskCardContent(task, columnColor),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(task, columnColor),
      ),
      child: _buildTaskCardContent(task, columnColor),
    );
  }

  Widget _buildTaskCardContent(Task task, int columnColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Color(columnColor), width: 3),
          right: BorderSide(color: Colors.grey.shade200),
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with drag handle
            Row(
              children: [
                Icon(Icons.drag_indicator,
                    size: 16, color: Colors.grey.shade300),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Description
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Meta (Dependencies & Time)
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Row(
                children: [
                  if (task.dependencies.isNotEmpty) ...[
                    Icon(Icons.account_tree,
                        size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${task.dependencies.length} deps',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.access_time,
                      size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${task.estimatedHours}h',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Skills
            if (task.skills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: task.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Assignee
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(left: 22, top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: task.assignee.isNotEmpty
                  ? Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C5CE7).withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF6C5CE7).withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              task.initials,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C5CE7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.assignee,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Assign member')),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '+ Assign',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    "Design",
    "Creative",
    "Event Management",
    "Logistik",
    "Public Speaking",
    "Technical Writing",
    "Photography",
    "Videography",
    "Social Media",
    "Backend",
    "Frontend",
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
          ? widget.existingTasks
                  .map((t) => t.id)
                  .reduce((a, b) => a > b ? a : b) +
              1
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
              child: Row(
                children: [
                  const Text(
                    'Input Task Manual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Title
                    const Text(
                      'Judul Task',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Cetak Banner',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan detail task yang harus dikerjakan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Estimated Hours
                    const Text(
                      'Bobot Jam (Estimasi Waktu)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _hoursController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '5',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'jam',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perkiraan berapa jam task ini akan selesai',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skill Tags
                    const Text(
                      'Skill Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Skill apa yang dibutuhkan untuk task ini?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Selected Skills
                    if (_selectedSkills.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedSkills.remove(skill);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Skill Search
                    TextField(
                      controller: _skillSearchController,
                      onChanged: (value) {
                        setState(() {
                          _skillSearch = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari atau pilih skill...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Skill Suggestions
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
                                spacing: 8,
                                runSpacing: 8,
                                children: filteredSkills.map((skill) {
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedSkills.add(skill);
                                        _skillSearchController.clear();
                                        _skillSearch = '';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        skill,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    'Tidak ada skill yang cocok',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                      ),

                    // Quick Select Skills
                    if (_skillSearch.isEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSkills
                            .where((s) => !_selectedSkills.contains(s))
                            .take(6)
                            .map((skill) {
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedSkills.add(skill);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+ $skill',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 20),

                    // Dependencies
                    const Text(
                      'Dependency (Prasyarat Task)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih task yang harus selesai dulu sebelum task ini bisa dikerjakan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
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
                                  value:
                                      _selectedDependencies.contains(task.id),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedDependencies.add(task.id);
                                      } else {
                                        _selectedDependencies.remove(task.id);
                                      }
                                    });
                                  },
                                  title: Text(
                                    task.title,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    task.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  secondary: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${task.estimatedHours}h',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  dense: true,
                                );
                              },
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Belum ada task lain yang tersedia',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (_selectedDependencies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_selectedDependencies.length} dependency dipilih',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C5CE7),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tambah Task'),
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
