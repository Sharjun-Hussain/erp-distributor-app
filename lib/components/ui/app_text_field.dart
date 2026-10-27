import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Shopify-style rounded smooth input.
/// Polaris-like: 12px radius, 1px neutral border, soft fill,
/// primary focus ring, 15px regular text.
class AppTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final bool disabled;
  final Widget? suffixIcon;
  final Widget? suffixWidget;
  final VoidCallback? onSuffixTap;
  final int maxLines;
  final TextInputType? keyboardType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final FloatingLabelBehavior floatingLabelBehavior;

  const AppTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.disabled = false,
    this.suffixIcon,
    this.suffixWidget,
    this.onSuffixTap,
    this.maxLines = 1,
    this.keyboardType,
    this.isRequired = false,
    this.validator,
    this.floatingLabelBehavior = FloatingLabelBehavior.always,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cleanLabel =
        widget.label.replaceAll(RegExp(r'\s*\*\s*$'), '');
    final showStar =
        widget.isRequired || widget.label.contains('*');

    const radius = BorderRadius.all(Radius.circular(12));

    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final idleBorder =
        theme.brightness == Brightness.dark
            ? const Color(0x33FFFFFF) // clearer 20% white border instead of faint 8%
            : const Color(0xFFCBD5E1); // slate-300

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      enabled: !widget.disabled,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      cursorColor: scheme.primary,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: theme.textMain,
        height: 1.4,
      ),
      decoration: InputDecoration(
        floatingLabelBehavior: widget.floatingLabelBehavior,
        label: Text.rich(
          TextSpan(
            text: cleanLabel,
            children: [
              if (showStar)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
        hintText: widget.hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: theme.textSecondary.withValues(alpha: 0.5),
        ),
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.textSecondary,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.primary,
        ),
        prefixIcon: Icon(
          widget.prefixIcon,
          size: 18,
          color: theme.textSecondary.withValues(alpha: 0.85),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: _toggleObscure,
              )
            : widget.suffixWidget ??
                (widget.suffixIcon != null
                    ? IconButton(
                        icon: widget.suffixIcon!,
                        onPressed: widget.onSuffixTap,
                      )
                    : null),
        filled: true,
        fillColor: theme.cardColor,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: border(idleBorder),
        focusedBorder: border(AppColors.brand, 1.8),
        disabledBorder: border(idleBorder.withValues(alpha: 0.3)),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.8),
      ),
    );
  }
}
