part of '../supporter_screen.dart';

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FF4655)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _SupporterLoadingState extends StatelessWidget {
  const _SupporterLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonPanel(height: 156),
        SizedBox(height: AppSpacing.lg),
        _SkeletonPanel(height: 360),
      ],
    );
  }
}

class _SupporterErrorState extends StatelessWidget {
  const _SupporterErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: _SupporterPanel(
          title: 'Supporter indisponible',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Reessayer',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  const _EmptyPanelMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x52020617),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SkeletonPanel extends StatefulWidget {
  const _SkeletonPanel({required this.height});

  final double height;

  @override
  State<_SkeletonPanel> createState() => _SkeletonPanelState();
}

class _SkeletonPanelState extends State<_SkeletonPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x7A020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: widget.height,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 0.28,
                    height: 12,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 0.62,
                    height: 22,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 1,
                    height: 14,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SkeletonBlock(
                    animationValue: _controller.value,
                    widthFactor: 0.72,
                    height: 14,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.animationValue,
    required this.widthFactor,
    required this.height,
  });

  final double animationValue;
  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final highlight = 0.08 + (animationValue * 0.10);

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0x14FFFFFF),
              Color.fromRGBO(255, 255, 255, highlight),
              const Color(0x14FFFFFF),
            ],
            stops: const [0.1, 0.48, 0.9],
          ),
        ),
        child: SizedBox(height: height),
      ),
    );
  }
}

String? _badgeAssetPath(String badgeKey) {
  return switch (badgeKey) {
    'FIRST_FAVORITE' => 'assets/images/badges/badge_1.png',
    'CALENDAR_SUBSCRIBER' => 'assets/images/badges/badge_2.png',
    'MATCH_DAY' => 'assets/images/badges/badge_3.png',
    'FINISHER' => 'assets/images/badges/badge_4.png',
    'LOYAL_SUPPORTER' => 'assets/images/badges/badge_5.png',
    'EXPLORER' => 'assets/images/badges/badge_6.png',
    'DERBY_HUNTER' => 'assets/images/badges/badge_7.png',
    'LIVE_REGULAR' => 'assets/images/badges/badge_8.png',
    'MATCH_ARCHIVIST' => 'assets/images/badges/badge_9.png',
    'TEAM_SCOUT' => 'assets/images/badges/badge_10.png',
    'COMPETITION_TOUR' => 'assets/images/badges/badge_11.png',
    'SUPER_FAVORITE' => 'assets/images/badges/badge_12.png',
    _ => null,
  };
}
