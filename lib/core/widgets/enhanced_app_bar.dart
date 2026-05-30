import 'package:flutter/material.dart';
import '../services/global_search_service.dart';
import 'global_command_bar.dart';
import 'notification_center.dart';

class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenuButton;
  final bool? isOpen;
  final VoidCallback? onMenuPressed;
  final String? title;
  final String? subtitle;

  const EnhancedAppBar({
    super.key,
    this.showMenuButton = false,
    this.isOpen,
    this.onMenuPressed,
    this.title,
    this.subtitle,
  });

  @override
  Size get preferredSize =>
      subtitle != null ? const Size.fromHeight(80) : const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Container(
      height: subtitle != null ? 80 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 24,
          vertical: 12,
        ),
        child: Row(
          children: [
            // Menu button for mobile/tablet
            if (showMenuButton) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      isOpen ?? false ? Icons.menu_open : Icons.menu,
                      color: const Color(0xFF475569),
                      size: 22,
                    ),
                    onPressed: onMenuPressed,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Logo OrgaFlow (only on desktop, left of search bar)
            if (!isSmallScreen && !isMediumScreen) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF6C5CE7),
                      child: const Icon(Icons.apps, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'OrgaFlow',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 24),
            ],

            // Title and subtitle (if provided)
            if (title != null && (isSmallScreen || isMediumScreen)) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Global Command Bar (center on desktop)
            if (title == null || (!isSmallScreen && !isMediumScreen)) ...[
              if (!isSmallScreen)
                const Expanded(
                  child: Center(
                    child: GlobalCommandBar(),
                  ),
                ),
            ],

            if (isSmallScreen) Spacer(),
            const SizedBox(width: 16),

            // Dark mode toggle (desktop/tablet)
            if (!isSmallScreen)
              IconButton(
                icon: const Icon(Icons.dark_mode_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dark mode toggle')),
                  );
                },
                color: Colors.grey.shade700,
                tooltip: 'Toggle dark mode',
              ),

            // On small screens, place search button to the right next to notifications
            if (isSmallScreen) ...[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: _GlobalSearchDelegate(),
                  );
                },
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
            ],

            // Notification Center
            const NotificationCenter(),
          ],
        ),
      ),
    );
  }
}

class _GlobalSearchDelegate extends SearchDelegate {
  final GlobalSearchService _searchService = GlobalSearchService();
  Future<List<Map<String, dynamic>>>? _dataFuture;

  _GlobalSearchDelegate() {
    _dataFuture = _searchService.fetchAllSearchableData();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No results found'));
        }

        final allData = snapshot.data!;
        final filteredData = allData.where((item) {
          if (query.isEmpty) return true;
          final name = item['name']?.toString().toLowerCase() ?? '';
          final role = item['role']?.toString().toLowerCase() ?? '';
          final project = item['project']?.toString().toLowerCase() ?? '';
          return name.contains(query.toLowerCase()) || 
                 role.contains(query.toLowerCase()) || 
                 project.contains(query.toLowerCase());
        }).toList();

        if (filteredData.isEmpty && query.isNotEmpty) {
           return const Center(child: Text('No matching results'));
        }

        return ListView.builder(
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final item = filteredData[index];
            final type = item['type'] as String;
            final icon = item['icon'] as IconData;
            final name = item['name'] as String;

            return ListTile(
              leading: Icon(icon),
              title: Text(name),
              subtitle: Text(item['role'] ?? item['project'] ?? type),
              onTap: () {
                close(context, null);
                if (item['route'] != null) {
                  Navigator.pushNamed(context, item['route']);
                }
              },
            );
          },
        );
      },
    );
  }
}
