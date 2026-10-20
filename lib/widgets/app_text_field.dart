import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Professional Material outlined text field with a leading icon.
///
/// Native InputDecorator handles the animated border/fill/label transitions
/// and the error message below the field — same visual language as
/// [SearchField] in common.dart.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixSvg,
    this.prefixIcon,
    this.prefixText,
    this.prefixTextStyle,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.focusNode,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? prefixSvg;
  final IconData? prefixIcon;
  final String? prefixText;
  final TextStyle? prefixTextStyle;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final GestureTapCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _internalFocus = FocusNode();
  bool _focused = false;

  FocusNode get _focus => widget.focusNode ?? _internalFocus;
  bool get _hasPrefixIcon =>
      widget.prefixSvg != null || widget.prefixIcon != null;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    if (widget.focusNode == null) _internalFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused != _focus.hasFocus && mounted) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  OutlineInputBorder _outline(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      cursorColor: AppColors.brand,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: theme.textMain,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.textSecondary,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: theme.textSecondary.withValues(alpha: 0.7),
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.danger,
        ),
        filled: true,
        fillColor: _focused ? theme.cardColor : theme.surfaceColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.maxLines > 1 ? 14 : 16,
        ),
        prefixIcon: _hasPrefixIcon ? _leadingIcon(theme) : null,
        prefixText: widget.prefixText,
        prefixStyle: widget.prefixTextStyle ??
            GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
        suffixIcon: widget.suffix,
        enabledBorder: _outline(theme.surfaceMutedColor, 1),
        focusedBorder: _outline(AppColors.brand, 1.5),
        errorBorder: _outline(AppColors.danger, 1),
        focusedErrorBorder: _outline(AppColors.danger, 1.5),
        hoverColor: AppColors.brand.withValues(alpha: 0.04),
      ),
    );
  }

  Widget _leadingIcon(ThemeData theme) {
    final color = _focused ? AppColors.brand : theme.textSecondary;

    final Widget glyph = widget.prefixSvg != null
        ? SvgPicture.asset(
            widget.prefixSvg!,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Icon(widget.prefixIcon, size: 20, color: color);

    // Outer fixed box keeps the slot at the standard 48x48; Center loosens
    // constraints so the glyph renders at 20x20 instead of filling the slot.
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: SizedBox(width: 20, height: 20, child: glyph),
      ),
    );
  }
}
