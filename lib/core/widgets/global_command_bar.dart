import 'package:flutter/material.dart';

class GlobalCommandBar extends StatefulWidget {
  const GlobalCommandBar({super.key});

  @override
  State<GlobalCommandBar> createState() => _GlobalCommandBarState();
}

class _GlobalCommandBarState extends State<GlobalCommandBar> {
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => const _SearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showSearchDialog,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search tasks, members, projects...',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '⌘',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'K',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          height: 1,
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
    );
  }
}

class _SearchDialog extends StatefulWidget {
  const _SearchDialog();

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Mock data
  final List<Map<String, dynamic>> _allProjects = [
    {'name': 'Inagurasi PKKMB UNESA 5 2026', 'type': 'project', 'icon': Icons.folder_outlined},
    {'name': 'Seminar Nasional IT', 'type': 'project', 'icon': Icons.folder_outlined},
    {'name': 'Kampanye Sosial Media', 'type': 'project', 'icon': Icons.folder_outlined},
    {'name': 'Website Redesign', 'type': 'project', 'icon': Icons.folder_outlined},
    {'name': 'Mobile App Launch', 'type': 'project', 'icon': Icons.folder_outlined},
  ];

  final List<Map<String, dynamic>> _allMembers = [
    {'name': 'Sarah Chen', 'role': 'Lead Designer', 'type': 'member', 'icon': Icons.person_outline},
    {'name': 'Mike Johnson', 'role': 'Senior Developer', 'type': 'member', 'icon': Icons.person_outline},
    {'name': 'Emma Davis', 'role': 'Product Manager', 'type': 'member', 'icon': Icons.person_outline},
    {'name': 'Alex Kim', 'role': 'DevOps Engineer', 'type': 'member', 'icon': Icons.person_outline},
    {'name': 'Tom Wilson', 'role': 'QA Engineer', 'type': 'member', 'icon': Icons.person_outline},
    {'name': 'Lisa Anderson', 'role': 'Marketing Lead', 'type': 'member', 'icon': Icons.person_outline},
  ];

  final List<Map<String, dynamic>> _allTasks = [
    {'name': 'Desain Banner Utama', 'project': 'Inagurasi PKKMB', 'type': 'task', 'icon': Icons.task_outlined},
    {'name': 'Persiapan Venue', 'project': 'Inagurasi PKKMB', 'type': 'task', 'icon': Icons.task_outlined},
    {'name': 'Cetak Banner', 'project': 'Inagurasi PKKMB', 'type': 'task', 'icon': Icons.task_outlined},
    {'name': 'API Documentation', 'project': 'Website Redesign', 'type': 'task', 'icon': Icons.task_outlined},
    {'name': 'User Testing Session', 'project': 'Mobile App', 'type': 'task', 'icon': Icons.task_outlined},
  ];

  List<Map<String, dynamic>> get _filteredResults {
    if (_searchQuery.isEmpty) {
      return [];
    }

    final query = _searchQuery.toLowerCase();
    final results = <Map<String, dynamic>>[];

    // Search projects
    results.addAll(_allProjects.where((item) => 
      item['name'].toString().toLowerCase().contains(query)
    ));

    // Search members
    results.addAll(_allMembers.where((item) => 
      item['name'].toString().toLowerCase().contains(query) ||
      item['role'].toString().toLowerCase().contains(query)
    ));

    // Search tasks
    results.addAll(_allTasks.where((item) => 
      item['name'].toString().toLowerCase().contains(query) ||
      item['project'].toString().toLowerCase().contains(query)
    ));

    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input
            Row(
              children: [
                Icon(Icons.search, color: Colors.grey.shade600, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tasks, members, projects...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // Results or Quick Actions
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildQuickActions()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionItem(
            icon: Icons.people_outline,
            title: 'View All Members',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/members');
            },
          ),
          _buildQuickActionItem(
            icon: Icons.folder_outlined,
            title: 'View Projects',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/projects');
            },
          ),
          _buildQuickActionItem(
            icon: Icons.bar_chart_outlined,
            title: 'Fairness Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/fairness');
            },
          ),
          _buildQuickActionItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredResults;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return _buildResultItem(item);
      },
    );
  }

  Widget _buildResultItem(Map<String, dynamic> item) {
    final type = item['type'] as String;
    final icon = item['icon'] as IconData;
    final name = item['name'] as String;

    Color typeColor;
    String typeLabel;

    switch (type) {
      case 'project':
        typeColor = const Color(0xFF6C5CE7);
        typeLabel = 'Project';
        break;
      case 'member':
        typeColor = const Color(0xFF00B894);
        typeLabel = 'Member';
        break;
      case 'task':
        typeColor = const Color(0xFF00CEC9);
        typeLabel = 'Task';
        break;
      default:
        typeColor = Colors.grey;
        typeLabel = 'Item';
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $name')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (type == 'member' && item['role'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['role'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (type == 'task' && item['project'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['project'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: typeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
