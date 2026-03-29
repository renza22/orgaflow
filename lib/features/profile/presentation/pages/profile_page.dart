import 'package:flutter/material.dart';

import '../../../../core/session/session_service.dart';
import '../../../../core/supabase_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final fullNameController = TextEditingController();
  final capacityController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadCurrentData();
  }

  Future<void> loadCurrentData() async {
    final sessionContext =
        await sessionService.getCurrentContext(refresh: true);

    if (!mounted || sessionContext == null) {
      return;
    }

    setState(() {
      fullNameController.text = sessionContext.profile?.fullName ?? '';
      capacityController.text =
          (sessionContext.activeMember?.weeklyCapacityHours ?? 0).toString();
    });
  }

  Future<void> saveProfile() async {
    final sessionContext =
        await sessionService.getCurrentContext(refresh: true);
    final user = supabase.auth.currentUser;

    if (user == null || sessionContext == null) {
      showMessage('User belum login');
      return;
    }

    final fullName = fullNameController.text.trim();
    final capacityText = capacityController.text.trim();

    if (fullName.isEmpty || capacityText.isEmpty) {
      showMessage('Nama lengkap dan kapasitas wajib diisi');
      return;
    }

    final capacity = int.tryParse(capacityText);

    if (capacity == null || capacity < 0) {
      showMessage('Kapasitas harus berupa angka yang valid');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      await supabase.from('profiles').update({
        'full_name': fullName,
      }).eq('id', user.id);

      if (sessionContext.activeMember != null) {
        await supabase.from('members').update({
          'weekly_capacity_hours': capacity,
        }).eq('id', sessionContext.activeMember!.id);
      }

      await sessionService.clearCache();
      showMessage('Profile berhasil disimpan');
    } catch (e) {
      showMessage('Gagal menyimpan profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: capacityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kapasitas Jam per Minggu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveProfile,
                child: Text(
                  isLoading ? 'Menyimpan...' : 'Simpan Profil',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
