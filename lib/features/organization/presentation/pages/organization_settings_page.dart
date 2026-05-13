import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/widgets/enhanced_app_bar.dart';
import '../../../../core/widgets/responsive_sidebar.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/organization_settings_model.dart';
import '../../domain/models/update_organization_settings_input.dart';
import '../presenters/organization_presenter.dart';

class OrganizationSettingsPage extends StatefulWidget {
  const OrganizationSettingsPage({super.key});

  @override
  State<OrganizationSettingsPage> createState() =>
      _OrganizationSettingsPageState();
}

class _OrganizationSettingsPageState extends State<OrganizationSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final OrganizationPresenter _presenter = OrganizationPresenter();

  final _orgNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _periodController = TextEditingController();
  final _semesterController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _warningThresholdController = TextEditingController();
  final _criticalThresholdController = TextEditingController();
  final _overloadThresholdController = TextEditingController();
  final _burnoutDaysController = TextEditingController();

  List<MasterOption> _organizationTypes = const [];
  List<String> _skillNames = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _activeOrganizationId;
  OrganizationSettingsModel? _settings;
  bool _canEditSettings = false;
  String? _selectedOrgTypeCode;

  double _skillWeight = 40;
  double _capacityWeight = 35;
  double _fairnessWeight = 25;

  bool get _isFormEnabled => _canEditSettings && !_isSaving;

  int get _totalWeight =>
      _skillWeight.round() + _capacityWeight.round() + _fairnessWeight.round();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _descriptionController.dispose();
    _periodController.dispose();
    _semesterController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _warningThresholdController.dispose();
    _criticalThresholdController.dispose();
    _overloadThresholdController.dispose();
    _burnoutDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _isSaving = false;
      _errorMessage = null;
    });

    try {
      final contextData = await sessionService.getCurrentContext(refresh: true);
      final activeMember = contextData?.activeMember;
      final organization = contextData?.organization;

      if (activeMember == null ||
          organization == null ||
          organization.id.trim().isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = 'User belum memiliki organisasi aktif.';
          _activeOrganizationId = null;
          _settings = null;
          _canEditSettings = false;
        });
        return;
      }

      final organizationId = organization.id;
      final role = activeMember.role.toLowerCase();
      final canEditSettings = role == 'owner' || role == 'admin';

      final organizationTypesFuture = _presenter.loadOrganizationTypes();
      final settingsFuture =
          _presenter.loadOrganizationSettings(organizationId);
      final skillNamesFuture = _presenter.loadActiveSkillNames();

      final organizationTypesResult = await organizationTypesFuture;
      final settingsResult = await settingsFuture;
      final skillNamesResult = await skillNamesFuture;

      if (!mounted) {
        return;
      }

      if (organizationTypesResult.isFailure) {
        setState(() {
          _isLoading = false;
          _errorMessage = organizationTypesResult.error!.message;
          _activeOrganizationId = organizationId;
          _settings = null;
          _canEditSettings = canEditSettings;
        });
        return;
      }

      if (settingsResult.isFailure) {
        setState(() {
          _isLoading = false;
          _errorMessage = settingsResult.error!.message;
          _activeOrganizationId = organizationId;
          _settings = null;
          _canEditSettings = canEditSettings;
        });
        return;
      }

      final settings = settingsResult.data!;
      final organizationTypes = _includeCurrentOrganizationType(
        organizationTypesResult.data!,
        settings.typeCode,
      );

      _populateFromSettings(settings);

      setState(() {
        _organizationTypes = organizationTypes;
        _skillNames =
            skillNamesResult.isSuccess ? skillNamesResult.data! : const [];
        _activeOrganizationId = organizationId;
        _settings = settings;
        _canEditSettings = canEditSettings;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = ErrorMapper.map(error).message;
        _settings = null;
        _canEditSettings = false;
      });
    }
  }

  List<MasterOption> _includeCurrentOrganizationType(
    List<MasterOption> options,
    String typeCode,
  ) {
    if (typeCode.trim().isEmpty ||
        options.any((option) => option.code == typeCode)) {
      return options;
    }

    return [
      ...options,
      MasterOption(code: typeCode, label: typeCode),
    ];
  }

  void _populateFromSettings(OrganizationSettingsModel settings) {
    _orgNameController.text = settings.name;
    _descriptionController.text = settings.description ?? '';
    _periodController.text = settings.periodLabel ?? '';
    _semesterController.text = settings.semesterLabel ?? '';
    _startDateController.text = _formatDate(settings.periodStartDate);
    _endDateController.text = _formatDate(settings.periodEndDate);
    _warningThresholdController.text =
        _formatNumber(settings.warningThreshold * 100);
    _criticalThresholdController.text =
        _formatNumber(settings.criticalThreshold * 100);
    _overloadThresholdController.text =
        _formatNumber(settings.overloadThreshold * 100);
    _burnoutDaysController.text = settings.burnoutAlertDays.toString();
    _selectedOrgTypeCode =
        settings.typeCode.trim().isEmpty ? null : settings.typeCode;
    _skillWeight = settings.skillWeight * 100;
    _capacityWeight = settings.capacityWeight * 100;
    _fairnessWeight = settings.fairnessWeight * 100;
  }

  Future<void> _saveChanges() async {
    if (!_canEditSettings || _isSaving) {
      return;
    }

    final input = _buildUpdateInput();
    if (input == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final result = await _presenter.updateOrganizationSettings(input);

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        _isSaving = false;
      });
      _showSnackBar(result.error!.message, backgroundColor: Colors.red);
      return;
    }

    final settings = result.data!;
    final organizationTypes = _includeCurrentOrganizationType(
      _organizationTypes,
      settings.typeCode,
    );

    _populateFromSettings(settings);

    setState(() {
      _settings = settings;
      _activeOrganizationId = settings.organizationId;
      _organizationTypes = organizationTypes;
      _isSaving = false;
      _errorMessage = null;
    });

    _showSnackBar('Pengaturan organisasi berhasil disimpan.');
  }

  UpdateOrganizationSettingsInput? _buildUpdateInput() {
    final organizationId = _activeOrganizationId?.trim();
    final name = _orgNameController.text.trim();
    final typeCode = _selectedOrgTypeCode?.trim();

    if (organizationId == null || organizationId.isEmpty) {
      _showSnackBar('Organisasi aktif tidak valid.',
          backgroundColor: Colors.red);
      return null;
    }

    if (name.isEmpty) {
      _showSnackBar('Nama organisasi wajib diisi.',
          backgroundColor: Colors.red);
      return null;
    }

    if (typeCode == null || typeCode.isEmpty) {
      _showSnackBar('Tipe organisasi wajib dipilih.',
          backgroundColor: Colors.red);
      return null;
    }

    DateTime? startDate;
    DateTime? endDate;

    try {
      startDate = _parseDateField(_startDateController, 'Start Date');
      endDate = _parseDateField(_endDateController, 'End Date');
    } on FormatException catch (error) {
      _showSnackBar(error.message, backgroundColor: Colors.red);
      return null;
    }

    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      _showSnackBar(
        'End Date tidak boleh sebelum Start Date.',
        backgroundColor: Colors.red,
      );
      return null;
    }

    final warningThreshold = _parseNumberField(
      _warningThresholdController,
      'Warning Threshold',
    );
    final overloadThreshold = _parseNumberField(
      _overloadThresholdController,
      'Overload Threshold',
    );

    if (warningThreshold == null || overloadThreshold == null) {
      return null;
    }

    if (warningThreshold < 0 || warningThreshold >= 100) {
      _showSnackBar(
        'Warning threshold harus antara 0-99%.',
        backgroundColor: Colors.red,
      );
      return null;
    }

    if (overloadThreshold <= warningThreshold || overloadThreshold > 150) {
      _showSnackBar(
        'Overload threshold harus lebih besar dari warning dan maksimal 150%.',
        backgroundColor: Colors.red,
      );
      return null;
    }

    final burnoutDays = int.tryParse(_burnoutDaysController.text.trim());
    if (burnoutDays == null || burnoutDays < 1 || burnoutDays > 365) {
      _showSnackBar(
        'Burnout alert days harus berada di antara 1 sampai 365.',
        backgroundColor: Colors.red,
      );
      return null;
    }

    final skillWeight = _skillWeight.round();
    final capacityWeight = _capacityWeight.round();
    final fairnessWeight = _fairnessWeight.round();
    final totalWeight = skillWeight + capacityWeight + fairnessWeight;

    if (totalWeight != 100) {
      _showSnackBar(
        'Total bobot Smart Assignment harus 100%.',
        backgroundColor: Colors.red,
      );
      return null;
    }

    return UpdateOrganizationSettingsInput(
      organizationId: organizationId,
      name: name,
      typeCode: typeCode,
      description: _normalizeOptionalText(_descriptionController.text),
      periodLabel: _normalizeOptionalText(_periodController.text),
      semesterLabel: _normalizeOptionalText(_semesterController.text),
      periodStartDate: startDate,
      periodEndDate: endDate,
      warningThreshold: warningThreshold / 100,
      criticalThreshold: warningThreshold / 100, // Same as warning for backward compatibility
      overloadThreshold: overloadThreshold / 100,
      burnoutAlertDays: burnoutDays,
      skillWeight: skillWeight / 100,
      capacityWeight: capacityWeight / 100,
      fairnessWeight: fairnessWeight / 100,
    );
  }

  void _resetDefaults() {
    if (!_canEditSettings || _isSaving) {
      return;
    }

    setState(() {
      _warningThresholdController.text = '75';
      _overloadThresholdController.text = '100';
      _burnoutDaysController.text =
          OrganizationSettingsModel.defaultBurnoutAlertDays.toString();
      _skillWeight = OrganizationSettingsModel.defaultSkillWeight * 100;
      _capacityWeight = OrganizationSettingsModel.defaultCapacityWeight * 100;
      _fairnessWeight = OrganizationSettingsModel.defaultFairnessWeight * 100;
    });

    _showSnackBar(
        'Nilai default diterapkan. Klik Save Changes untuk menyimpan.');
  }

  void _copyInviteCode() {
    final inviteCode = _settings?.inviteCode.trim() ?? '';
    if (inviteCode.isEmpty) {
      return;
    }

    Clipboard.setData(ClipboardData(text: inviteCode));
    _showSnackBar('Invite code disalin.');
  }

  void _showSnackBar(
    String message, {
    Color? backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  DateTime? _parseDateField(
    TextEditingController controller,
    String label,
  ) {
    return _parseDateText(controller.text, label);
  }

  DateTime? _parseDateText(
    String text,
    String label,
  ) {
    final value = text.trim();
    if (value.isEmpty) {
      return null;
    }

    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('$label harus berformat YYYY-MM-DD.');
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);

    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw FormatException('$label tidak valid.');
    }

    return parsed;
  }

  double? _parseNumberField(
    TextEditingController controller,
    String label,
  ) {
    final value = controller.text.trim();
    final parsed = double.tryParse(value);

    if (value.isEmpty || parsed == null) {
      _showSnackBar('$label wajib berupa angka.', backgroundColor: Colors.red);
      return null;
    }

    return parsed;
  }

  String? _normalizeOptionalText(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _formatNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) {
      return rounded.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
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
                    _buildHeader(isSmallScreen),
                    const SizedBox(height: 24),
                    _buildBodyContent(isSmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildBodyContent(bool isSmallScreen) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_settings == null) {
      return _buildEmptyState('Pengaturan organisasi tidak ditemukan.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_canEditSettings) ...[
          _buildPermissionNotice(),
          const SizedBox(height: 24),
        ],
        _buildOrganizationInformationCard(isSmallScreen),
        const SizedBox(height: 24),
        _buildWorkloadThresholdsCard(),
        const SizedBox(height: 24),
        _buildSkillTaxonomyCard(),
        const SizedBox(height: 24),
        _buildSmartAssignmentWeightsCard(),
        const SizedBox(height: 24),
        _buildActions(isSmallScreen),
      ],
    );
  }

  Widget _buildOrganizationInformationCard(bool isSmallScreen) {
    return _buildCard(
      title: 'Organization Information',
      child: Column(
        children: [
          _buildTextField('Organization Name', _orgNameController),
          const SizedBox(height: 16),
          _buildOrganizationTypeField(),
          const SizedBox(height: 16),
          _buildTextField(
            'Description',
            _descriptionController,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _buildReadOnlyValue(
            'Invite Code',
            _settings?.inviteCode ?? '',
            onCopy: (_settings?.inviteCode.trim().isNotEmpty ?? false)
                ? _copyInviteCode
                : null,
          ),
          const SizedBox(height: 16),
          if (isSmallScreen) ...[
            _buildTextField('Current Period', _periodController),
            const SizedBox(height: 16),
            _buildTextField('Semester', _semesterController),
          ] else
            Row(
              children: [
                Expanded(
                  child: _buildTextField('Current Period', _periodController),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField('Semester', _semesterController),
                ),
              ],
            ),
          const SizedBox(height: 16),
          if (isSmallScreen) ...[
            _buildTextField(
              'Start Date',
              _startDateController,
              isDate: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'End Date',
              _endDateController,
              isDate: true,
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'Start Date',
                    _startDateController,
                    isDate: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    'End Date',
                    _endDateController,
                    isDate: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWorkloadThresholdsCard() {
    final warningValue = double.tryParse(_warningThresholdController.text) ?? 75;
    final overloadValue = double.tryParse(_overloadThresholdController.text) ?? 100;

    return _buildCard(
      title: 'Workload Thresholds',
      child: Column(
        children: [
          // Warning Threshold with Slider
          _buildThresholdSlider(
            'Warning Threshold (%)',
            warningValue,
            _warningThresholdController,
            (value) {
              setState(() {
                _warningThresholdController.text = value.round().toString();
              });
            },
            helperText: 'Anggota dengan Load Ratio 75%-99% akan ditandai kuning (Warning)',
          ),
          const SizedBox(height: 24),
          
          // Overload Threshold with Slider
          _buildThresholdSlider(
            'Overload Threshold (%)',
            overloadValue,
            _overloadThresholdController,
            (value) {
              setState(() {
                _overloadThresholdController.text = value.round().toString();
              });
            },
            helperText: 'Anggota dengan Load Ratio ≥100% akan ditandai merah (Overload)',
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            'Burnout Alert Days',
            _burnoutDaysController,
            keyboardType: TextInputType.number,
            helperText: 'Jumlah hari overload sebelum mengirim alert burnout',
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider(
    String label,
    double value,
    TextEditingController controller,
    ValueChanged<double> onChanged,
    {String? helperText}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Small input field
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                enabled: _isFormEnabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  suffixText: '%',
                  suffixStyle: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                onChanged: (text) {
                  final parsed = double.tryParse(text);
                  if (parsed != null && parsed >= 0 && parsed <= 100) {
                    onChanged(parsed);
                  }
                },
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
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: _isFormEnabled ? onChanged : null,
          ),
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

  Widget _buildSkillTaxonomyCard() {
    return _buildCard(
      title: 'Skill Taxonomy',
      titleAction: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: const Text('Add Skill', style: TextStyle(fontSize: 13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill taxonomy bersifat read-only. Pengelolaan skill taxonomy akan diatur pada task terpisah.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (_skillNames.isEmpty)
            Text(
              'Belum ada skill aktif.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillNames.map((skill) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSmartAssignmentWeightsCard() {
    final totalColor =
        _totalWeight == 100 ? Colors.grey.shade700 : Colors.red.shade600;

    return _buildCard(
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: $_totalWeight%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: totalColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(bool isSmallScreen) {
    final saveButton = ElevatedButton(
      onPressed: _isFormEnabled ? _saveChanges : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C5CE7),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Save Changes'),
    );

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          saveButton,
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isFormEnabled ? _resetDefaults : null,
            child: const Text('Reset to Defaults'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isFormEnabled ? _resetDefaults : null,
          child: const Text('Reset to Defaults'),
        ),
        const SizedBox(width: 12),
        saveButton,
      ],
    );
  }

  Widget _buildPermissionNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Text(
        'Hanya owner/admin yang dapat mengubah pengaturan organisasi.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.orange.shade900,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loadSettings,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.apartment, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (titleAction != null) ...[
                const SizedBox(width: 12),
                titleAction,
              ],
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
    int maxLines = 1,
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
          enabled: _isFormEnabled,
          keyboardType: keyboardType,
          minLines: maxLines > 1 ? 3 : 1,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixIcon:
                isDate ? const Icon(Icons.calendar_today, size: 18) : null,
          ),
          readOnly: isDate,
          onTap: isDate && _isFormEnabled
              ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate:
                        _parseDateForPicker(controller.text) ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    controller.text = _formatDate(date);
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

  Widget _buildOrganizationTypeField() {
    final selectedValue =
        _organizationTypes.any((option) => option.code == _selectedOrgTypeCode)
            ? _selectedOrgTypeCode
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organization Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(selectedValue ?? 'no-organization-type'),
          initialValue: selectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          hint: const Text('Pilih tipe organisasi'),
          items: _organizationTypes
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.code,
                  child: Text(option.label),
                ),
              )
              .toList(),
          onChanged: _isFormEnabled
              ? (value) {
                  setState(() {
                    _selectedOrgTypeCode = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildReadOnlyValue(
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();

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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'Copy invite code',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${value.round()}%',
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
            overlayColor: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
            trackHeight: 8,
          ),
          child: Slider(
            value: value.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: _isFormEnabled ? onChanged : null,
          ),
        ),
      ],
    );
  }

  DateTime? _parseDateForPicker(String value) {
    try {
      return _parseDateText(value, 'Tanggal');
    } on FormatException {
      return null;
    }
  }
}
