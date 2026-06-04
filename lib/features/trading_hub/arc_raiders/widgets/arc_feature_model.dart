import 'package:flutter/material.dart';

class ArcFeatureItem {
  const ArcFeatureItem({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}
