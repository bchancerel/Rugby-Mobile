part of 'package:rugby_jam_mobile/features/dashboard/dashboard_screen.dart';

class _RefreshStatus extends StatelessWidget {
  const _RefreshStatus();

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Mise a jour du dashboard...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatefulWidget {
  const _EmptyDashboard({required this.onOpenRoute});

  final ValueChanged<String> onOpenRoute;

  @override
  State<_EmptyDashboard> createState() => _EmptyDashboardState();
}

class _EmptyDashboardState extends State<_EmptyDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelMessage(
      leading: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.94 + (_controller.value * 0.12),
            child: child,
          );
        },
        child: const Icon(
          Icons.star_border,
          color: AppColors.primaryHover,
          size: 36,
        ),
      ),
      title: 'Prepare ton dashboard',
      message: 'Ajoute des championnats et des equipes en favoris.',
      action: AppButton(
        label: 'Parcourir les championnats',
        icon: Icons.emoji_events,
        onPressed: () => widget.onOpenRoute(AppRoutes.leagues),
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.title,
    required this.message,
    this.icon,
    this.leading,
    this.action,
  });

  final IconData? icon;
  final Widget? leading;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}

class _DashboardLoadingState extends StatefulWidget {
  const _DashboardLoadingState();

  @override
  State<_DashboardLoadingState> createState() => _DashboardLoadingStateState();
}

class _DashboardLoadingStateState extends State<_DashboardLoadingState>
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBlock(
                animationValue: _controller.value,
                widthFactor: 0.42,
                height: 20,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _SkeletonCard(animationValue: _controller.value),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SkeletonCard(animationValue: _controller.value),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _SkeletonCard(animationValue: _controller.value),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SkeletonPanel(animationValue: _controller.value),
              const SizedBox(height: AppSpacing.md),
              _SkeletonPanel(animationValue: _controller.value),
            ],
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.32,
              height: 22,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.74,
              height: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.animationValue});

  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.56,
              height: 16,
            ),
            const SizedBox(height: AppSpacing.md),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.88,
              height: 14,
            ),
            const SizedBox(height: AppSpacing.sm),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.64,
              height: 14,
            ),
          ],
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

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: _PanelMessage(
          icon: Icons.error_outline,
          title: 'Dashboard indisponible',
          message: message,
          action: AppButton(
            label: 'Reessayer',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ),
      ),
    );
  }
}

