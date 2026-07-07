import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';

class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    required this.currentRoute,
    super.key,
  });

  final String currentRoute;

  static const height = 78.0;

  static const _items = [
    _BottomNavItem(
      routeName: AppRoutes.dashboard,
      label: 'Accueil',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    _BottomNavItem(
      routeName: AppRoutes.leagues,
      label: 'Leagues',
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events,
    ),
    _BottomNavItem(
      routeName: AppRoutes.matches,
      label: 'Matchs',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
    ),
    _BottomNavItem(
      routeName: AppRoutes.supporter,
      label: 'Supporter',
      icon: Icons.workspace_premium_outlined,
      activeIcon: Icons.workspace_premium,
    ),
    _BottomNavItem(
      routeName: AppRoutes.user,
      label: 'Compte',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  static double _lastActiveIndex = 0;
  static const _indicatorInset = 4.0;
  static const _indicatorVerticalInset = 8.0;

  late double _animationStartIndex;
  late double _indicatorIndex;

  @override
  void initState() {
    super.initState();
    _animationStartIndex = _lastActiveIndex;
    _indicatorIndex = _lastActiveIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _indicatorIndex = _activeIndex.toDouble();
      });
    });
  }

  @override
  void didUpdateWidget(covariant AppBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      setState(() {
        _animationStartIndex = _indicatorIndex;
        _indicatorIndex = _activeIndex.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xE6020617),
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x88000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: AppBottomNav.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth / AppBottomNav._items.length;
                    final indicatorWidth = itemWidth - (_indicatorInset * 2);

                    return Stack(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: _animationStartIndex,
                            end: _indicatorIndex,
                          ),
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutCubic,
                          onEnd: () {
                            _lastActiveIndex = _indicatorIndex;
                            _animationStartIndex = _indicatorIndex;
                          },
                          builder: (context, value, child) {
                            final animationDistance =
                                (_indicatorIndex - _animationStartIndex).abs();
                            final animationProgress = animationDistance == 0
                                ? 1.0
                                : ((value - _animationStartIndex).abs() /
                                        animationDistance)
                                    .clamp(0.0, 1.0)
                                    .toDouble();
                            final stretchLimit =
                                (animationDistance * 11).clamp(10.0, 23.0)
                                    .toDouble();
                            final stretch = animationDistance == 0
                                ? 0.0
                                : math.sin(animationProgress * math.pi) *
                                    stretchLimit;
                            final direction =
                                (_indicatorIndex - _animationStartIndex).sign;
                            final left = (itemWidth * value) +
                                _indicatorInset -
                                (direction < 0 ? stretch : 0);

                            return Positioned(
                              top: _indicatorVerticalInset,
                              left: left,
                              child: _MovingIndicator(
                                width: indicatorWidth + stretch,
                                height: AppBottomNav.height -
                                    (_indicatorVerticalInset * 2),
                              ),
                            );
                          },
                        ),
                        Row(
                          children:
                              AppBottomNav._items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final active = index == activeIndex;

                            return Expanded(
                              child: _BottomNavButton(
                                item: item,
                                active: active,
                                horizontalPadding: _indicatorInset + 2,
                                onTap: active
                                    ? null
                                    : () => Navigator.of(context)
                                        .pushReplacementNamed(item.routeName),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int get _activeIndex {
    final index = AppBottomNav._items.indexWhere(
      (item) => _isActive(item.routeName),
    );

    if (index == -1) {
      return 0;
    }

    return index;
  }

  bool _isActive(String routeName) {
    if (widget.currentRoute == routeName) {
      return true;
    }

    if (routeName == AppRoutes.leagues) {
      return widget.currentRoute.startsWith('${AppRoutes.leagues}/');
    }

    if (routeName == AppRoutes.matches) {
      return widget.currentRoute.startsWith('${AppRoutes.matches}/');
    }

    if (routeName == AppRoutes.user) {
      return widget.currentRoute.startsWith('${AppRoutes.user}/');
    }

    return false;
  }
}

class _MovingIndicator extends StatelessWidget {
  const _MovingIndicator({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xB0131A2A),
                  Color(0x8A7F1D2D),
                  Color(0xAA020617),
                ],
                stops: [0, 0.52, 1],
              ),
              border: Border.all(color: const Color(0x7AFF4655)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55FF4655),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: SizedBox(width: width, height: height),
          ),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatefulWidget {
  const _BottomNavButton({
    required this.item,
    required this.active,
    required this.horizontalPadding,
    required this.onTap,
  });

  final _BottomNavItem item;
  final bool active;
  final double horizontalPadding;
  final VoidCallback? onTap;

  @override
  State<_BottomNavButton> createState() => _BottomNavButtonState();
}

class _BottomNavButtonState extends State<_BottomNavButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? AppColors.white : AppColors.grayCool;
    final iconColor = widget.active ? AppColors.primaryHover : color;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 30,
              child: Icon(
                widget.active ? widget.item.activeIcon : widget.item.icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.horizontalPadding,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: widget.active
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.routeName,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String routeName;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
