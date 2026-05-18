import 'package:flutter/material.dart';

class UagFormDropdownField extends StatelessWidget {
  const UagFormDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.decoration,
  });

  final String value;
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: decoration ?? InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
