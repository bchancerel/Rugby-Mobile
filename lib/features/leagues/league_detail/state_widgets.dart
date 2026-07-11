part of '../league_detail_screen.dart';

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.redAccent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayCool,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueDetailLoadingState extends StatelessWidget {
  const _LeagueDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonBlock(height: 180),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(height: 86),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(height: 220),
      ],
    );
  }
}

class _LeagueDetailErrorState extends StatelessWidget {
  const _LeagueDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        132,
      ),
      child: AppStatePanel(
        title: 'Competition indisponible',
        message: message,
        actionLabel: 'Reessayer',
        onAction: onRetry,
      ),
    );
  }
}

class _LeagueDetailEmptyState extends StatelessWidget {
  const _LeagueDetailEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        132,
      ),
      child: AppStatePanel(
        title: 'Competition introuvable',
        message: 'Aucune donnee disponible pour cette competition.',
        actionLabel: 'Recharger',
        onAction: onRetry,
      ),
    );
  }
}

