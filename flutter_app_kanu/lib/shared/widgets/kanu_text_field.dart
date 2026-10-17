import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de formulaire KANU avec label, aide et validation.
class KanuTextField extends StatelessWidget {
  const KanuTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            prefixIcon:
                prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffix,
            counterText: maxLength != null ? '' : null,
          ),
        ),
      ],
    );
  }
}
