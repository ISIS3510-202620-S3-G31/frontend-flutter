import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.textInputAction,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.onChanged,
    this.errorText,
    this.helperText,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;

  final String? errorText;

  /// The rule of the field, shown while there is nothing to complain about.
  final String? helperText;

  /// For fields filled from a picker instead of the keyboard.
  final bool readOnly;
  final VoidCallback? onTap;

  /// What the phone may fill in from the accounts it has saved, such as
  /// [AutofillHints.email].
  final Iterable<String>? autofillHints;

  /// Off for emails and passwords, which the keyboard would "fix".
  final bool autocorrect;

  /// Off for passwords, so the keyboard does not learn them.
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppText.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          autofillHints: autofillHints,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          style: AppText.body.copyWith(color: AppColors.text, fontSize: 15),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppText.bodyMuted.copyWith(fontSize: 14),
            errorText: errorText,
            helperText: helperText,
            helperStyle: AppText.bodyMuted.copyWith(fontSize: 12),
            helperMaxLines: 2,
            errorMaxLines: 2,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.panel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.surfaceDim,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.accent, width: 2.0),
            ),
            errorStyle: AppText.body.copyWith(
              color: AppColors.accent,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
