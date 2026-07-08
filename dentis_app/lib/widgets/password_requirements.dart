import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class PasswordRequirements extends StatelessWidget {
  final String password;
  final bool visible;

  const PasswordRequirements({
    super.key,
    required this.password,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final missing = <String>[
      if (password.length < 8) "Mínimo 8",
      if (!RegExp(r'[A-Z]').hasMatch(password)) "Mayúscula",
      if (!RegExp(r'[a-z]').hasMatch(password)) "Minúscula",
      if (!password.contains(".")) "Punto",
    ];

    if (missing.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: _RequirementChip(
          label: "Contraseña segura",
          icon: Icons.check_rounded,
          active: true,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: missing
            .map(
              (label) => _RequirementChip(
                label: label,
                icon: Icons.add_rounded,
                active: false,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;

  const _RequirementChip({
    required this.label,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = active
        ? const Color(0xff2FA884)
        : colors.muted.withValues(alpha: colors.isLight ? .95 : .80);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xff70C49A).withValues(alpha: .15)
            : colors.field.withValues(alpha: colors.isLight ? .85 : .35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? const Color(0xff2FA884).withValues(alpha: .35)
              : colors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
