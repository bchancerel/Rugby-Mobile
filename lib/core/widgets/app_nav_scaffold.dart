import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
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
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: SafeArea(
              child: _ProfileShortcut(currentRoute: currentRoute),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShortcut extends StatefulWidget {
  const _ProfileShortcut({required this.currentRoute});

  final String currentRoute;

  @override
  State<_ProfileShortcut> createState() => _ProfileShortcutState();
}

class _ProfileShortcutState extends State<_ProfileShortcut> {
  bool _pressed = false;

  bool get _active {
    return widget.currentRoute == AppRoutes.user ||
        widget.currentRoute.startsWith('${AppRoutes.user}/');
  }

  void _setPressed(bool value) {
    if (_pressed == value || _active) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _active ? AppColors.white : AppColors.grayCool;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _active
          ? null
          : () => Navigator.of(context).pushReplacementNamed(AppRoutes.user),
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _active
                      ? const [
                          Color(0xB0131A2A),
                          Color(0x8A7F1D2D),
                          Color(0xAA020617),
                        ]
                      : const [
                          Color(0xD6020617),
                          Color(0xB0131A2A),
                        ],
                ),
                border: Border.all(
                  color: _active ? const Color(0x7AFF4655) : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  _active ? Icons.person : Icons.person_outline,
                  color: iconColor,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
