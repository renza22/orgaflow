import 'package:flutter/material.dart';

class ResponsiveSidebar extends StatelessWidget {
  final String currentRoute;

  const ResponsiveSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Menu Utama Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Kelola Proyek',
                  route: '/projects',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Kelola Anggota',
                  route: '/members',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.bar_chart_outlined,
                  title: 'Insights & Fairness',
                  route: '/fairness',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  route: '/settings',
                ),
              ],
            ),
          ),

          // Burnout Alerts
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '3 Burnout Alerts',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Members need workload rebalancing',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // User Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C5CE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'AD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Ketua Organisasi',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = currentRoute == route;

    return InkWell(
      onTap: () {
        if (route == '/settings') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings page coming soon')),
          );
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C5CE7).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: const Color(0xFF6C5CE7),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isActive ? const Color(0xFF6C5CE7) : Colors.grey.shade600,
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? const Color(0xFF6C5CE7) : Colors.grey.shade700,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          dense: true,
        ),
      ),
    );
  }
}
