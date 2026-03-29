import 'package:flutter/material.dart';

import '../../../../core/supabase_config.dart';
import '../../../skill/presentation/pages/skill_setup_page.dart';

class MemberSetupPage extends StatefulWidget {
  const MemberSetupPage({super.key});

  @override
  State<MemberSetupPage> createState() => _MemberSetupPageState();
}

class _MemberSetupPageState extends State<MemberSetupPage> {
  final positionController = TextEditingController();
  final capacityController = TextEditingController();

  bool isLoading = false;
  List<dynamic> organizations = [];
  String? selectedOrganizationId;

  @override
  void initState() {
    super.initState();
    fetchOrganizations();
  }

  Future<void> fetchOrganizations() async {
    try {
      final data = await supabase
          .from('organizations')
          .select()
          .order('created_at', ascending: true);

      setState(() {
        organizations = data;
      });
    } catch (e) {
      showMessage('Gagal mengambil data organisasi: $e');
    }
  }

  Future<void> saveMember() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage('User belum login');
      return;
    }

    final position = positionController.text.trim();
    final capacityText = capacityController.text.trim();

    if (selectedOrganizationId == null) {
      showMessage('Pilih organisasi terlebih dahulu');
      return;
    }

    if (position.isEmpty || capacityText.isEmpty) {
      showMessage('Jabatan dan kapasitas wajib diisi');
      return;
    }

    final capacity = int.tryParse(capacityText);

    if (capacity == null || capacity < 0) {
      showMessage('Kapasitas harus berupa angka yang valid');
      return;
    }

    final positionCode = await resolvePositionCode(position);
    if (positionCode == null) {
      showMessage('Jabatan tidak ditemukan di master data');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final existingMember = await supabase
          .from('members')
          .select('id')
          .eq('profile_id', user.id)
          .eq('organization_id', selectedOrganizationId!)
          .maybeSingle();

      Map<String, dynamic> insertedMember;
      if (existingMember != null) {
        insertedMember = await supabase
            .from('members')
            .update({
              'position_code': positionCode,
              'weekly_capacity_hours': capacity,
              'availability_status': 'available',
              'status': 'active',
            })
            .eq('id', existingMember['id'])
            .select()
            .single();
      } else {
        insertedMember = await supabase
            .from('members')
            .insert({
              'profile_id': user.id,
              'organization_id': selectedOrganizationId,
              'role': 'member',
              'position_code': positionCode,
              'division_code': null,
              'weekly_capacity_hours': capacity,
              'capacity_used_hours': 0,
              'availability_status': 'available',
              'status': 'active',
            })
            .select()
            .single();
      }

      showMessage('Data anggota berhasil disimpan');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SkillSetupPage(
            memberId: insertedMember['id'],
          ),
        ),
      );
    } catch (e) {
      showMessage('Gagal menyimpan data anggota: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> resolvePositionCode(String input) async {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }

    final positions = await supabase
        .from('position_templates')
        .select('code, label')
        .eq('is_active', true);

    for (final rawPosition in positions) {
      final position = rawPosition;
      final code = (position['code'] as String?) ?? '';
      final label = (position['label'] as String?) ?? '';

      if (code.toLowerCase() == normalized ||
          label.toLowerCase() == normalized) {
        return code;
      }
    }

    return null;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    positionController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Keanggotaan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedOrganizationId,
              items: organizations.map<DropdownMenuItem<String>>((org) {
                return DropdownMenuItem<String>(
                  value: org['id'],
                  child: Text(org['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedOrganizationId = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pilih Organisasi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(
                labelText: 'Jabatan',
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
                onPressed: isLoading ? null : saveMember,
                child: Text(
                  isLoading ? 'Menyimpan...' : 'Simpan Keanggotaan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
