part of '../news_screen.dart';

class _NewsLoadingState extends StatelessWidget {
  const _NewsLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeletonBlock(height: 220, borderRadius: 8),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(height: 92, borderRadius: 8),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBlock(height: 92, borderRadius: 8),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonBlock(height: 92, borderRadius: 8),
      ],
    );
  }
}

class _NewsErrorState extends StatelessWidget {
  const _NewsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.newspaper, color: AppColors.primary, size: 44),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Actualites indisponibles',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayCool,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Reessayer',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _NewsEmptyState extends StatelessWidget {
  const _NewsEmptyState({
    required this.transfersOnly,
    required this.onRetry,
  });

  final bool transfersOnly;
  final VoidCallback onRetry;

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
          children: [
            const Icon(Icons.search_off, color: AppColors.primary, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(
              transfersOnly
                  ? 'Aucun article transfert disponible.'
                  : 'Aucun article disponible.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tu peux relancer une actualisation dans quelques instants.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grayCool,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Actualiser',
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
