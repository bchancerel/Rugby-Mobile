import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';

class RoutePlaceholderScreen extends StatelessWidget {
  const RoutePlaceholderScreen({
    required this.title,
    required this.routeName,
    required this.icon,
    this.showBottomNav = false,
    super.key,
  });

  final String title;
  final String routeName;
  final IconData icon;
  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appBar = AppBar(
      backgroundColor: AppColors.appBackground,
      foregroundColor: AppColors.white,
      title: Text(title),
    );
    final body = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              routeName,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.grayCool,
              ),
            ),
          ],
        ),
      ),
    );

    if (showBottomNav) {
      return AppNavScaffold(
        currentRoute: routeName,
        appBar: appBar,
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: appBar,
      body: body,
    );
  }
}
