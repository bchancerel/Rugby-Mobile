import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/widgets/app_bottom_nav.dart';

class AppNavScaffold extends StatelessWidget {
  const AppNavScaffold({
    required this.currentRoute,
    required this.body,
    this.appBar,
    super.key,
  });

  final String currentRoute;
  final Widget body;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: appBar,
      bottomNavigationBar: AppBottomNav(currentRoute: currentRoute),
      body: body,
    );
  }
}
