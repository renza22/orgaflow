import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/skill_data.dart';
import '../../data/onboarding_data.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int currentStep = 0;
  final PageController _pageController = PageController();

  // Step 1
  File? profileImage;
  final namaLengkapController = TextEditingController();
  final nimController = TextEditingController();
  String? selectedProdi;
  String? selectedJabatan;
  String? selectedDivisi;

  // Step 2
  Map<String, Map<String, String>> selectedSkills = {};

  // Step 3
  double weeklyCapacity = 10;
  bool isAvailable = true;

  // Step 4
  List<PortfolioLink> portfolioLinks = [PortfolioLink()];
  final bioController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    namaLengkapController.dispose();
    nimController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => profileImage = File(pickedFile.path));
    }
  }


  void nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _pageController.animateToPage(currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _pageController.animateToPage(currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void handleComplete() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.secondary.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(theme),
              _buildProgressIndicator(theme),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => currentStep = index),
                  children: [
                    _buildStep1(theme),
                    _buildStep2(theme),
                    _buildStep3(theme),
                    _buildStep4(theme),
                  ],
                ),
              ),
              _buildNavigationButtons(theme),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentStep > 0) IconButton(icon: const Icon(Icons.arrow_back), onPressed: previousStep),
          Expanded(
            child: Text('Complete Your Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted || isActive ? theme.colorScheme.primary : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }


  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1: Data Identitas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                child: profileImage != null
                    ? ClipOval(child: Image.file(profileImage!, fit: BoxFit.cover))
                    : Icon(Icons.add_a_photo, size: 40, color: theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(controller: namaLengkapController, label: 'Nama Lengkap', hint: 'John Doe', icon: Icons.person_outline, theme: theme),
          const SizedBox(height: 20),
          _buildTextField(controller: nimController, label: 'NIM', hint: '12345678', icon: Icons.tag, theme: theme),
          const SizedBox(height: 20),
          _buildDropdown(label: 'Program Studi', value: selectedProdi, items: OnboardingData.prodiList, onChanged: (v) => setState(() => selectedProdi = v), icon: Icons.school_outlined, theme: theme),
          const SizedBox(height: 20),
          _buildDropdown(label: 'Jabatan', value: selectedJabatan, items: OnboardingData.jabatanList, onChanged: (v) => setState(() => selectedJabatan = v), icon: Icons.work_outline, theme: theme),
          const SizedBox(height: 20),
          _buildDropdown(label: 'Divisi', value: selectedDivisi, items: OnboardingData.divisiList, onChanged: (v) => setState(() => selectedDivisi = v), icon: Icons.business_outlined, theme: theme),
        ],
      ),
    );
  }


  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2: Skill Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 24),
          ...OnboardingData.skillCategories.entries.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.value.map((skill) {
                    final isSelected = selectedSkills.containsKey(skill);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedSkills.remove(skill);
                          } else {
                            selectedSkills[skill] = {'level': 'Beginner'};
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.check, size: 16, color: Colors.white)),
                            Text(skill, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
          if (selectedSkills.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('Summary: ${selectedSkills.length} skills selected', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
            ),
        ],
      ),
    );
  }


  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3: Capacity & Commitment', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 24),
          Text('Weekly Capacity: ${weeklyCapacity.toInt()} hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          Slider(
            value: weeklyCapacity,
            min: 5,
            max: 40,
            divisions: 35,
            label: '${weeklyCapacity.toInt()} hours',
            onChanged: (value) => setState(() => weeklyCapacity = value),
            activeColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Available for new tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
              Switch(value: isAvailable, onChanged: (value) => setState(() => isAvailable = value), activeColor: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStep4(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4: Portfolio & Bio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 24),
          Text('Portfolio Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
          ...portfolioLinks.asMap().entries.map((entry) {
            final index = entry.key;
            final link = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: link.platform,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: OnboardingData.platformList.map((platform) => DropdownMenuItem(value: platform, child: Text(platform))).toList(),
                      onChanged: (value) => setState(() => portfolioLinks[index].platform = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: link.urlController,
                      decoration: InputDecoration(
                        hintText: 'URL',
                        filled: true,
                        fillColor: theme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: portfolioLinks.length > 1 ? () => setState(() => portfolioLinks.removeAt(index)) : null,
                    color: Colors.red,
                  ),
                ],
              ),
            );
          }).toList(),
          TextButton.icon(onPressed: () => setState(() => portfolioLinks.add(PortfolioLink())), icon: const Icon(Icons.add), label: const Text('Add Link')),
          const SizedBox(height: 24),
          Text('Bio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          const SizedBox(height: 12),
          TextField(
            controller: bioController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }


  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, required ThemeData theme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color))]),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required Function(String?) onChanged, required IconData icon, required ThemeData theme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 16, color: theme.colorScheme.primary), const SizedBox(width: 8), Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color))]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (currentStep > 0) Expanded(child: OutlinedButton(onPressed: previousStep, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: theme.colorScheme.primary)), child: const Text('Back'))),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(child: ElevatedButton(onPressed: currentStep < 3 ? nextStep : handleComplete, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(currentStep < 3 ? 'Next' : 'Complete'))),
        ],
      ),
    );
  }
}
