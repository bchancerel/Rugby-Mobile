import 'package:flutter/material.dart';

class AppSkeletonBlock extends StatelessWidget {
  const AppSkeletonBlock({
    required this.height,
    this.borderRadius = 22,
    this.color,
    this.borderColor,
    super.key,
  });

  final double height;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final solidColor = color;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: solidColor,
            border: borderColor == null ? null : Border.all(color: borderColor!),
            gradient: solidColor == null
                ? const LinearGradient(
                    colors: [
                      Color(0xFF0A1424),
                      Color(0xFF111827),
                      Color(0xFF0A1424),
                    ],
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
