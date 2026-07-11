import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';

class AppInlineAlert extends StatelessWidget {
  const AppInlineAlert({
    required this.message,
    this.backgroundColor = const Color(0x33E63946),
    this.borderColor = const Color(0x88E63946),
    this.borderRadius = 18,
    this.textColor = AppColors.white,
    this.fontWeight = FontWeight.w700,
    super.key,
  });

  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Color textColor;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: fontWeight,
              ),
        ),
      ),
    );
  }
}
