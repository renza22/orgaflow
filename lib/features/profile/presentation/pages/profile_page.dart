import 'package:flutter/material.dart';

import '../../../../core/session/session_service.dart';
import '../../../members/presentation/pages/member_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _memberId;
  String? _memberName;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    try {
      final sessionContext =
          await sessionService.getCurrentContext(refresh: true);

      if (!mounted) {
        return;
      }

      if (sessionContext == null) {
        Navigator.pushReplacementNamed(context, '/auth');
        return;
      }

      final activeMember = sessionContext.activeMember;
      if (activeMember == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User belum memiliki organisasi aktif.';
        });
        return;
      }

      setState(() {
        _memberId = activeMember.id;
        _memberName =
            sessionContext.profile?.fullName ?? sessionContext.profile?.email;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat profile user.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final memberId = _memberId;
    if (_errorMessage != null || memberId == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Profile user tidak ditemukan.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadCurrentUserProfile();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MemberProfilePage(
      memberId: memberId,
      memberName: _memberName,
      showEditButton: true,
      isCurrentUser: true,
      sidebarRoute: '/profile',
    );
  }
}
