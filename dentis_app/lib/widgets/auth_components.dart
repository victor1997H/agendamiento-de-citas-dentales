import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import 'auth_background.dart';

class AuthScaffold extends StatelessWidget {
  final bool loading;
  final double overlayOpacity;
  final EdgeInsets padding;
  final double maxWidth;
  final bool autofillGroup;
  final Widget child;

  const AuthScaffold({
    super.key,
    required this.loading,
    required this.child,
    this.overlayOpacity = .18,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
    this.maxWidth = 440,
    this.autofillGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: autofillGroup ? AutofillGroup(child: child) : child,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackground(overlayOpacity: overlayOpacity),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: padding,
                child: content,
              ),
            ),
          ),
          if (loading)
            Container(
              color: colors.isLight
                  ? Colors.white.withValues(alpha: .55)
                  : Colors.black.withValues(alpha: .45),
              child: Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double darkOpacity;

  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
    this.radius = 28,
    this.darkOpacity = .84,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.isLight
            ? colors.panel.withValues(alpha: .94)
            : AppTheme.primaryDark.withValues(alpha: darkOpacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border),
        boxShadow: [
          colors.softShadow ??
              BoxShadow(
                color: Colors.black.withValues(alpha: .28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
        ],
      ),
      child: child,
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final double markSize;
  final double titleSize;
  final TextAlign textAlign;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.markSize = 82,
    this.titleSize = 26,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        AuthBrandMark(
          size: markSize,
          toothColor: colors.isLight ? colors.primary : AppTheme.primaryDark,
          shineColor:
              Colors.white.withValues(alpha: colors.isLight ? .70 : .45),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            color: colors.text,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: textAlign,
          style: TextStyle(
            color: colors.muted,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(
              color: colors.isLight
                  ? colors.field.withValues(alpha: .86)
                  : Colors.white.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: TextStyle(color: colors.muted, fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String? label;
  final String? hintText;
  final bool obscure;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;
  final VoidCallback? onTogglePassword;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final int? maxLength;
  final bool autocorrect;
  final bool? enableSuggestions;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.icon,
    this.label,
    this.hintText,
    this.obscure = false,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTogglePassword,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.autocorrect = false,
    this.enableSuggestions,
    this.fontSize = 16,
    this.fontWeight = FontWeight.normal,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions ?? !isPassword,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted?.call(),
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      maxLength: maxLength,
      cursorColor: colors.primary,
      style: TextStyle(
        color: colors.text,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
      decoration: InputDecoration(
        counterText: maxLength == null ? null : "",
        filled: true,
        fillColor: colors.isLight
            ? colors.field.withValues(alpha: .94)
            : AppTheme.darkPanel.withValues(alpha: .94),
        prefixIcon: Icon(icon, color: colors.muted),
        suffixIcon: isPassword
            ? IconButton(
                tooltip: obscure ? "Mostrar contraseña" : "Ocultar contraseña",
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: colors.muted,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        labelText: label,
        labelStyle: TextStyle(color: colors.muted),
        floatingLabelStyle: TextStyle(color: colors.primary),
        hintText: hintText,
        hintStyle: TextStyle(
          color: colors.muted.withValues(alpha: .35),
          letterSpacing: letterSpacing,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 1.3),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primary.withValues(alpha: .52),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
