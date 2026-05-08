class ProfileWorkloadTrendModel {
  const ProfileWorkloadTrendModel({
    required this.label,
    required this.scoreDate,
    required this.workloadHours,
    required this.capacityHours,
  });

  final String label;
  final DateTime scoreDate;
  final int workloadHours;
  final int capacityHours;

  double get percentage {
    if (capacityHours <= 0) {
      return 0;
    }
    return workloadHours / capacityHours * 100;
  }
}
