import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? suffix;
  final bool isInteger;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? initialValue;
  final TextInputType? keyboardType;
  final String? hintText;
  final String? prefixText;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.suffix,
    this.isInteger = false,
    this.validator,
    this.onChanged,
    this.initialValue,
    this.keyboardType,
    this.hintText,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          keyboardType: keyboardType ?? TextInputType.numberWithOptions(decimal: !isInteger),
          onChanged: onChanged,
          validator: validator ?? (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Wajib diisi';
            }
            if (isInteger) {
              final parsed = int.tryParse(value);
              if (parsed == null) return 'Angka bulat tidak valid';
              if (parsed < 0) return 'Tidak boleh negatif';
            } else {
              final parsed = double.tryParse(value.replaceAll(',', '.'));
              if (parsed == null) return 'Angka tidak valid';
              if (parsed < 0) return 'Tidak boleh negatif';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText ?? '0',
            suffixText: suffix,
            prefixText: prefixText,
          ),
        ),
      ],
    );
  }
}
