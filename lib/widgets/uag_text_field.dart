import 'package:flutter/material.dart';
import 'theme.dart';

class UAGTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final bool obscure;
  final Object? prefixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hintText;
  final bool enabled;
  final VoidCallback? onTap;
  final bool readOnly;

  const UAGTextField({
    super.key,
    this.controller,
    required this.label,
    this.obscure = false,
    this.prefixIcon,
    this.onChanged,
    this.keyboardType,
    this.maxLines = 1,
    this.hintText,
    this.enabled = true,
    this.onTap,
    this.readOnly = false,
  });

  Widget? _buildPrefixIcon() {
    if (prefixIcon == null) return null;

    if (prefixIcon is Widget) {
      return prefixIcon as Widget;
    }

    if (prefixIcon is IconData) {
      return Icon(
        prefixIcon as IconData,
        color: AppTheme.neonPink,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLines: obscure ? 1 : maxLines,
      enabled: enabled,
      onTap: onTap,
      readOnly: readOnly,
      style: AppTheme.bodyTextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      decoration: AppTheme.inputDecoration(label).copyWith(
        hintText: hintText,
        prefixIcon: _buildPrefixIcon(),
      ),
    );
  }
}
