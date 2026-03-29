import 'package:flutter/material.dart';

import '../../../../core/supabase_config.dart';
import '../../../project/presentation/pages/create_project_page.dart';

class SkillSetupPage extends StatefulWidget {
  final String memberId;

  const SkillSetupPage({
    super.key,
    required this.memberId,
  });

  @override
  State<SkillSetupPage> createState() => _SkillSetupPageState();
}

class _SkillSetupPageState extends State<SkillSetupPage> {
  bool isLoading = false;
  List<dynamic> skills = [];
  List<String> selectedSkillIds = [];

  @override
  void initState() {
    super.initState();
    fetchSkills();
  }

  Future<void> fetchSkills() async {
    try {
      final data =
          await supabase.from('skills').select().order('name', ascending: true);

      setState(() {
        skills = data;
      });
    } catch (e) {
      showMessage('Gagal mengambil data skill: $e');
    }
  }

  void toggleSkill(String skillId) {
    setState(() {
      if (selectedSkillIds.contains(skillId)) {
        selectedSkillIds.remove(skillId);
      } else {
        selectedSkillIds.add(skillId);
      }
    });
  }

  Future<void> saveSkills() async {
    if (selectedSkillIds.isEmpty) {
      showMessage('Pilih minimal satu skill');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final dataToInsert = selectedSkillIds.map((skillId) {
        return {
          'member_id': widget.memberId,
          'skill_id': skillId,
          'proficiency_level': 3,
          'source': 'manual',
        };
      }).toList();

      await supabase.from('member_skills').upsert(
            dataToInsert,
            onConflict: 'member_id,skill_id',
          );

      showMessage('Skill berhasil disimpan');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CreateProjectPage(),
        ),
      );
    } catch (e) {
      showMessage('Gagal menyimpan skill: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Skill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih skill yang kamu kuasai:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: skills.isEmpty
                  ? const Center(child: Text('Belum ada data skill'))
                  : ListView.builder(
                      itemCount: skills.length,
                      itemBuilder: (context, index) {
                        final skill = skills[index];
                        final skillId = skill['id'];
                        final isSelected = selectedSkillIds.contains(skillId);

                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(skill['name']),
                          subtitle: skill['category_code'] != null
                              ? Text(skill['category_code'])
                              : null,
                          onChanged: (_) => toggleSkill(skillId),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveSkills,
                child: Text(
                  isLoading ? 'Menyimpan...' : 'Simpan Skill',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
