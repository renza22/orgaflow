class MasterOption {
  const MasterOption({
    required this.code,
    required this.label,
  });

  final String code;
  final String label;

  factory MasterOption.fromJson(Map<String, dynamic> json) {
    return MasterOption(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}
