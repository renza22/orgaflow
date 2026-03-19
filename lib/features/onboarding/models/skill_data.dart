import 'package:flutter/material.dart';

class SkillData {
  final String skillName;
  final String category;
  String proficiency; // 'beginner', 'intermediate', 'expert'

  SkillData({
    required this.skillName,
    required this.category,
    this.proficiency = 'beginner',
  });
}

class PortfolioLink {
  String? platform;
  final TextEditingController urlController;

  PortfolioLink({
    this.platform,
  }) : urlController = TextEditingController();

  void dispose() {
    urlController.dispose();
  }
}
