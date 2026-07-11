import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';

class AppRefreshStatus extends StatelessWidget {
  const AppRefreshStatus({
    this.message = 'Actualisation...',
    this.showSpinner = false,
    this.decorated = false,
    this.textColor = AppColors.grayCool,
    this.fontWeight = FontWeight.w700,
    super.key,
  });

  final String message;
  final bool showSpinner;
  final bool decorated;
  final Color? textColor;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner) ...[
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: fontWeight,
              ),
        ),
      ],
    );

    if (!decorated) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FF4655)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: content,
      ),
    );
  }
}
