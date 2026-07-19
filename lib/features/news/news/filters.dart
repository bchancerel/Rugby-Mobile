part of '../news_screen.dart';

class _NewsHeader extends StatelessWidget {
  const _NewsHeader({
    required this.totalArticles,
    required this.availableSourcesCount,
  });

  final int totalArticles;
  final int availableSourcesCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        76,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fil info',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryHover,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('ACTUALITES', style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Les derniers articles rugby agreges depuis Rugbyrama, RugbyPass et Planet Rugby.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grayCool,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _NewsMetric(label: 'Articles', value: '$totalArticles'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NewsMetric(
                  label: 'Sources OK',
                  value: '$availableSourcesCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsMetric extends StatelessWidget {
  const _NewsMetric({required this.label, required this.value});

  final String label;
  final String value;

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
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.grayCool,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsFilters extends StatelessWidget {
  const _NewsFilters({
    required this.sourceFilters,
    required this.selectedSource,
    required this.transfersOnly,
    required this.updatedAt,
    required this.onSourceSelected,
    required this.onTransfersToggle,
  });

  final List<_NewsSourceFilter> sourceFilters;
  final String selectedSource;
  final bool transfersOnly;
  final String? updatedAt;
  final ValueChanged<String> onSourceSelected;
  final VoidCallback onTransfersToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x66020617),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Source',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = AppSpacing.sm;
                  final itemWidth = (constraints.maxWidth - gap) / 2;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final filter in sourceFilters)
                        SizedBox(
                          width: itemWidth,
                          child: _NewsSourceButton(
                            label: filter.label,
                            selected: selectedSource == filter.key,
                            onTap: () => onSourceSelected(filter.key),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _NewsTransfersSwitch(
                selected: transfersOnly,
                onTap: onTransfersToggle,
              ),
              const SizedBox(height: AppSpacing.md),
              _NewsUpdatedAt(value: updatedAt),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsSourceButton extends StatelessWidget {
  const _NewsSourceButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        constraints: const BoxConstraints(minHeight: 44),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0x66020617),
          border: Border.all(
            color: selected ? AppColors.primaryHover : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33FF4655),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : const [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                const Icon(Icons.check, color: AppColors.white, size: 16),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? AppColors.white : AppColors.grayCool,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsTransfersSwitch extends StatelessWidget {
  const _NewsTransfersSwitch({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x52020617),
          border: Border.all(
            color: selected ? const Color(0x7AFF4655) : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Icon(Icons.sync_alt, color: AppColors.grayCool, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Transferts uniquement',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x44FF4655),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ]
                      : const [],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment:
                      selected ? Alignment.centerRight : Alignment.centerLeft,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x55000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(width: 22, height: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsUpdatedAt extends StatelessWidget {
  const _NewsUpdatedAt({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x52020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppColors.grayCool, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Derniere mise a jour : ${_formatUpdatedAt(value)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
