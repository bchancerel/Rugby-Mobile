import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';

class AuthMessage extends StatelessWidget {
  const AuthMessage({
    required this.message,
    this.isError = false,
    super.key,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isError ? const Color(0x1FFF4655) : const Color(0x1F3FB984),
        border: Border.all(
          color: isError ? const Color(0x61FF4655) : const Color(0x613FB984),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError ? const Color(0xFFFFD5D9) : AppColors.grayLight,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
