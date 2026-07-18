part of '../team_detail_screen.dart';

class _TeamDetailLoadingState extends StatelessWidget {
  const _TeamDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonBlock(height: 148),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(height: 92),
      ],
    );
  }
}

class _TeamDetailErrorState extends StatelessWidget {
  const _TeamDetailErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppInlineAlert(message: message),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Reessayer', icon: Icons.refresh, onPressed: onRetry),
      ],
    );
  }
}

class _TeamDetailEmptyState extends StatelessWidget {
  const _TeamDetailEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppInlineAlert(
          message: 'Aucun championnat trouve pour cette equipe.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(label: 'Actualiser', icon: Icons.refresh, onPressed: onRetry),
      ],
    );
  }
}
