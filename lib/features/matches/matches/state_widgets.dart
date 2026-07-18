part of '../matches_screen.dart';

class _MatchesRefreshStatus extends StatelessWidget {
  const _MatchesRefreshStatus();

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
              'Mise a jour des matchs...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchesLoadingState extends StatefulWidget {
  const _MatchesLoadingState();

  @override
  State<_MatchesLoadingState> createState() => _MatchesLoadingStateState();
}

class _MatchesLoadingStateState extends State<_MatchesLoadingState>
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
                widthFactor: 0.48,
                height: 18,
              ),
              const SizedBox(height: AppSpacing.md),
              _SkeletonPanel(animationValue: _controller.value),
              const SizedBox(height: AppSpacing.sm),
              _SkeletonPanel(animationValue: _controller.value),
              const SizedBox(height: AppSpacing.sm),
              _SkeletonPanel(animationValue: _controller.value),
            ],
          );
        },
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
              widthFactor: 0.42,
              height: 14,
            ),
            const SizedBox(height: AppSpacing.md),
            _SkeletonBlock(
              animationValue: animationValue,
              widthFactor: 0.88,
              height: 18,
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

class _MatchesErrorState extends StatelessWidget {
  const _MatchesErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: _PanelMessage(
          icon: Icons.error_outline,
          title: 'Matchs indisponibles',
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

class _MatchesEmptyState extends StatelessWidget {
  const _MatchesEmptyState({
    required this.selectedDate,
    required this.selectedFilter,
    required this.onClearFilter,
  });

  final DateTime selectedDate;
  final _MatchFilter selectedFilter;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = selectedFilter != _MatchFilter.all;

    return _PanelMessage(
      icon: Icons.event_busy,
      title: filtered ? 'Aucun match dans ce filtre' : 'Aucun match',
      message: filtered
          ? 'Change de filtre ou regarde une autre date.'
          : 'Aucun match trouve pour ${_formatLongDate(selectedDate)}.',
      action: filtered
          ? AppButton(
              label: 'Voir tous les matchs',
              icon: Icons.filter_alt_off,
              variant: AppButtonVariant.secondary,
              onPressed: onClearFilter,
            )
          : null,
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
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

class _MatchesInlineAlert extends StatelessWidget {
  const _MatchesInlineAlert({required this.message});

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
