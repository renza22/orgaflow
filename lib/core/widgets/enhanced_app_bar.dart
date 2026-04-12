import 'package:flutter/material.dart';
import 'global_command_bar.dart';
import 'notification_center.dart';

class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final String? title;
  final String? subtitle;

  const EnhancedAppBar({
    super.key,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.title,
    this.subtitle,
  });

  @override
  Size get preferredSize => subtitle != null ? const Size.fromHeight(80) : const Size.fromHeight(70);

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
            color: Colors.black.withOpacity(0.05),
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
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onMenuPressed,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
            ],

            // Logo OrgaFlow (only on desktop, left of search bar)
            if (!isSmallScreen && !isMediumScreen) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apps,
                  color: Colors.white,
                  size: 20,
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

            // Global Command Bar (center on desktop, expandable on mobile)
            if (title == null || (!isSmallScreen && !isMediumScreen)) ...[
              if (isSmallScreen)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: _GlobalSearchDelegate(),
                    );
                  },
                  color: Colors.grey.shade700,
                )
              else
                const Expanded(
                  child: Center(
                    child: GlobalCommandBar(),
                  ),
                ),
            ],

            const SizedBox(width: 16),

            // Dark mode toggle
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

            // Notification Center
            const NotificationCenter(),
          ],
        ),
      ),
    );
  }
}

class _GlobalSearchDelegate extends SearchDelegate {
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
    return Center(
      child: Text('Search results for: $query'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = [
      'Sarah Chen',
      'API Documentation',
      'Website Redesign',
      'Kelola Anggota',
    ].where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
