import 'package:flutter/material.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';

class OrganizationSettingsPage extends StatefulWidget {
  const OrganizationSettingsPage({super.key});

  @override
  State<OrganizationSettingsPage> createState() => _OrganizationSettingsPageState();
}

class _OrganizationSettingsPageState extends State<OrganizationSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controllers
  final _orgNameController = TextEditingController(text: 'Tech Student Organization');
  final _periodController = TextEditingController(text: '2025/2026');
  final _semesterController = TextEditingController(text: 'Spring 2026');
  final _startDateController = TextEditingController(text: '2025-09-01');
  final _endDateController = TextEditingController(text: '2026-06-30');
  final _warningThresholdController = TextEditingController(text: '80');
  final _overloadThresholdController = TextEditingController(text: '100');
  final _burnoutDaysController = TextEditingController(text: '14');

  // Sliders
  double _skillWeight = 40;
  double _capacityWeight = 35;
  double _fairnessWeight = 25;

  // Skills
  final List<String> _skills = [
    "UI/UX Design",
    "Frontend",
    "Backend",
    "DevOps",
    "Cloud",
    "Database",
    "Mobile",
    "Testing",
    "QA",
    "Marketing",
    "Content",
    "Social Media",
    "Management",
    "Planning",
    "Leadership",
    "Communication",
  ];

  @override
  void dispose() {
    _orgNameController.dispose();
    _periodController.dispose();
    _semesterController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _warningThresholdController.dispose();
    _overloadThresholdController.dispose();
    _burnoutDaysController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Skill',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Skill Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.isNotEmpty) {
                        setState(() {
                          _skills.add(controller.text);
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  void _resetDefaults() {
    setState(() {
      _warningThresholdController.text = '80';
      _overloadThresholdController.text = '100';
      _burnoutDaysController.text = '14';
      _skillWeight = 40;
      _capacityWeight = 35;
      _fairnessWeight = 25;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset to default values')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: EnhancedAppBar(
        showMenuButton: isSmallScreen || isMediumScreen,
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: (isSmallScreen || isMediumScreen)
          ? Drawer(
              child: ResponsiveSidebar(currentRoute: '/organization-settings'),
            )
          : null,
      body: Row(
        children: [
          if (!isSmallScreen && !isMediumScreen)
            const ResponsiveSidebar(currentRoute: '/organization-settings'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 896),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Kelola Organisasi',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 24 : 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Konfigurasi organisasi dan parameter sistem',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Organization Info
                    _buildCard(
                      title: 'Organization Information',
                      child: Column(
                        children: [
                          _buildTextField('Organization Name', _orgNameController),
                          const SizedBox(height: 16),
                          if (isSmallScreen) ...[
                            _buildTextField('Current Period', _periodController),
                            const SizedBox(height: 16),
                            _buildTextField('Semester', _semesterController),
                          ] else
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Current Period', _periodController)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Semester', _semesterController)),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (isSmallScreen) ...[
                            _buildTextField('Start Date', _startDateController, isDate: true),
                            const SizedBox(height: 16),
                            _buildTextField('End Date', _endDateController, isDate: true),
                          ] else
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Start Date', _startDateController, isDate: true)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('End Date', _endDateController, isDate: true)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Workload Thresholds
                    _buildCard(
                      title: 'Workload Thresholds',
                      child: Column(
                        children: [
                          _buildTextField(
                            'Warning Threshold (%)',
                            _warningThresholdController,
                            keyboardType: TextInputType.number,
                            helperText: 'Members above this percentage will be marked as "Warning"',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Overload Threshold (%)',
                            _overloadThresholdController,
                            keyboardType: TextInputType.number,
                            helperText: 'Members at or above this will trigger burnout alerts',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Burnout Alert Days',
                            _burnoutDaysController,
                            keyboardType: TextInputType.number,
                            helperText: 'Days at overload threshold before sending burnout alert',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Skill Taxonomy
                    _buildCard(
                      title: 'Skill Taxonomy',
                      titleAction: OutlinedButton(
                        onPressed: _addSkill,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Add Skill', style: TextStyle(fontSize: 13)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage available skills for members and tasks',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      skill,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _removeSkill(skill),
                                      child: Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Smart Assignment Weights
                    _buildCard(
                      title: 'Smart Assignment Algorithm Weights',
                      child: Column(
                        children: [
                          _buildSlider(
                            'Skill Match Weight (%)',
                            _skillWeight,
                            (value) => setState(() => _skillWeight = value),
                          ),
                          const SizedBox(height: 16),
                          _buildSlider(
                            'Capacity Score Weight (%)',
                            _capacityWeight,
                            (value) => setState(() => _capacityWeight = value),
                          ),
                          const SizedBox(height: 16),
                          _buildSlider(
                            'Fairness Bonus Weight (%)',
                            _fairnessWeight,
                            (value) => setState(() => _fairnessWeight = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isSmallScreen) ...[
                          OutlinedButton(
                            onPressed: _resetDefaults,
                            child: const Text('Reset to Defaults'),
                          ),
                          const SizedBox(width: 12),
                        ],
                        ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                    if (isSmallScreen) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _resetDefaults,
                          child: const Text('Reset to Defaults'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    Widget? titleAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (titleAction != null) titleAction,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? helperText,
    bool isDate = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon: isDate ? const Icon(Icons.calendar_today, size: 18) : null,
          ),
          readOnly: isDate,
          onTap: isDate
              ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    controller.text = date.toString().split(' ')[0];
                  }
                }
              : null,
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toInt()}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF6C5CE7),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: const Color(0xFF6C5CE7),
            overlayColor: const Color(0xFF6C5CE7).withOpacity(0.2),
            trackHeight: 8,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
