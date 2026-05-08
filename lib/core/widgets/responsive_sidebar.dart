import 'package:flutter/material.dart';

import '../session/session_service.dart';
import '../supabase_config.dart';
import '../utils/storage_avatar_url_resolver.dart';

class ResponsiveSidebar extends StatefulWidget {
  final String currentRoute;

  const ResponsiveSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<ResponsiveSidebar> createState() => _ResponsiveSidebarState();
}

class _ResponsiveSidebarState extends State<ResponsiveSidebar> {
  // Static variable to persist collapsed state across page navigations
  static bool _persistentCollapsedState = false;

  final StorageAvatarUrlResolver _avatarUrlResolver =
      StorageAvatarUrlResolver();

  late bool _isCollapsed;
  bool _isLoadingUser = true;
  String _userName = '-';
  String _userEmail = '-';
  String _userSubtitle = '-';
  String? _avatarSignedUrl;

  @override
  void initState() {
    super.initState();
    // Initialize from persistent state
    _isCollapsed = _persistentCollapsedState;
    _loadUserProfile();
  }

  void _toggleSidebar() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      // Update persistent state
      _persistentCollapsedState = _isCollapsed;
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final context = await sessionService.getCurrentContext();
      final profile = context?.profile;
      final activeMember = context?.activeMember;

      final positionLabel = await _fetchPositionLabel(
        activeMember?.positionCode,
      );
      final avatarSignedUrl = await _avatarUrlResolver.resolve(
        profile?.avatarPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _userName = _firstNonEmpty([
          profile?.fullName,
          profile?.email,
        ]);
        _userEmail = _firstNonEmpty([profile?.email]);
        _userSubtitle = positionLabel ??
            _formatRole(activeMember?.role) ??
            _firstNonEmpty([activeMember?.positionCode]);
        _avatarSignedUrl = avatarSignedUrl;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<String?> _fetchPositionLabel(String? positionCode) async {
    final code = positionCode?.trim();
    if (code == null || code.isEmpty) {
      return null;
    }

    try {
      final response = await supabase
          .from('position_templates')
          .select('label')
          .eq('code', code)
          .maybeSingle();
      return response?['label']?.toString();
    } catch (_) {
      return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 70 : 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment:
                  _isCollapsed ? Alignment.center : Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  _isCollapsed ? Icons.menu : Icons.menu_open,
                  color: Colors.grey.shade700,
                ),
                onPressed: _toggleSidebar,
                tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
              ),
            ),
          ),

          // Menu Utama Header
          if (!_isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  icon: Icons.business_outlined,
                  title: 'Kelola Organisasi',
                  route: '/organization-settings',
                ),
              ],
            ),
          ),

          // Burnout Alerts
          if (!_isCollapsed)
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '3 Burnout Alerts',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

          _buildUserProfileMenu(context),
        ],
      ),
    );
  }

  Widget _buildUserProfileMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: _isCollapsed
          ? Center(
              child: PopupMenuButton<String>(
                offset: const Offset(0, -120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: _buildUserMenuItems,
                onSelected: (value) => _handleUserMenuSelection(context, value),
                child: _buildUserAvatar(40),
              ),
            )
          : PopupMenuButton<String>(
              offset: const Offset(0, -120),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: _buildExpandedUserMenuItems,
              onSelected: (value) => _handleUserMenuSelection(context, value),
              child: Row(
                children: [
                  _buildUserAvatar(40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLoadingUser ? 'Memuat...' : _userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isLoadingUser ? '-' : _userSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, size: 20, color: Colors.grey.shade600),
                ],
              ),
            ),
    );
  }

  List<PopupMenuEntry<String>> _buildUserMenuItems(BuildContext context) {
    return [
      PopupMenuItem<String>(
        value: 'profile',
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            const Text('Profile'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'logout',
        child: Row(
          children: [
            Icon(Icons.logout, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
      ),
    ];
  }

  List<PopupMenuEntry<String>> _buildExpandedUserMenuItems(
    BuildContext context,
  ) {
    return [
      PopupMenuItem<String>(
        padding: EdgeInsets.zero,
        enabled: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(),
      ..._buildUserMenuItems(context),
    ];
  }

  Widget _buildUserAvatar(double size) {
    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF6C5CE7),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: _isLoadingUser
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _initialsFor(_userName, _userEmail),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
      );
    }

    final avatarUrl = _avatarSignedUrl;
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

  void _handleUserMenuSelection(BuildContext context, String value) {
    if (value == 'profile') {
      Navigator.pushNamed(context, '/profile');
    } else if (value == 'logout') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout functionality coming soon')),
      );
    }
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '-';
  }

  String? _formatRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      case 'member':
        return 'Member';
      default:
        final normalized = role?.trim();
        return normalized == null || normalized.isEmpty ? null : normalized;
    }
  }

  String _initialsFor(String name, String email) {
    final source = name != '-' ? name : email;
    final parts = source
        .trim()
        .split(RegExp(r'\s+|@'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts.map((part) => part[0].toUpperCase()).join();
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = widget.currentRoute == route ||
        (widget.currentRoute == '/' && route == '/dashboard');

    return Tooltip(
      message: _isCollapsed ? title : '',
      child: InkWell(
        onTap: () {
          if (route == '/dashboard' || route == '/') {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: _isCollapsed
              ? const EdgeInsets.symmetric(vertical: 16)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF6C5CE7).withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(8),
            border: isActive && !_isCollapsed
                ? Border(
                    left: BorderSide(
                      color: const Color(0xFF6C5CE7),
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: _isCollapsed
              ? Icon(
                  icon,
                  color:
                      isActive ? const Color(0xFF6C5CE7) : Colors.grey.shade600,
                  size: 22,
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? const Color(0xFF6C5CE7)
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF6C5CE7)
                              : Colors.grey.shade700,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
