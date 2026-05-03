import 'package:flutter/material.dart';
import '../../../members/presentation/pages/member_profile_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to MemberProfilePage with showEditButton = true
    // Using dummy data for now - in production, this would use actual logged-in user data
    return const MemberProfilePage(
      memberId: 0, // Current user ID
      memberName: 'Admin', // Current user name
      showEditButton: true,
    );
  }
}
