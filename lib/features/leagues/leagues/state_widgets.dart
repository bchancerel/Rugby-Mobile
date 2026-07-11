part of '../leagues_screen.dart';

class _NoFilteredLeagues extends StatelessWidget {
  const _NoFilteredLeagues({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _LeaguesPanel(
      title: 'Aucun resultat',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aucune competition ne correspond a ces filtres.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayLight,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Effacer les filtres',
            icon: Icons.filter_alt_off,
            variant: AppButtonVariant.secondary,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  String? hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon),
    filled: true,
    fillColor: const Color(0x5C020617),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primaryHover),
    ),
  );
}

class _LeaguesPanel extends StatelessWidget {
  const _LeaguesPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x7A020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x38000000),
            blurRadius: 32,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _LeaguesLoadingState extends StatelessWidget {
  const _LeaguesLoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppSkeletonBlock(
          height: 86,
          borderRadius: 8,
          color: Color(0x7A020617),
          borderColor: AppColors.border,
        ),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(
          height: 76,
          borderRadius: 8,
          color: Color(0x7A020617),
          borderColor: AppColors.border,
        ),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(
          height: 176,
          borderRadius: 8,
          color: Color(0x7A020617),
          borderColor: AppColors.border,
        ),
      ],
    );
  }
}

class _LeaguesErrorState extends StatelessWidget {
  const _LeaguesErrorState({
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
        child: _LeaguesPanel(
          title: 'Competitions indisponibles',
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

class _LeaguesEmptyState extends StatelessWidget {
  const _LeaguesEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: _LeaguesPanel(
          title: 'Aucune competition',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "L'API n'a renvoye aucune competition pour le moment.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Actualiser',
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
