part of '../matches_screen.dart';

class _MatchesHeader extends StatelessWidget {
  const _MatchesHeader({
    required this.selectedDate,
    required this.fixturesCount,
  });

  final DateTime selectedDate;
  final int fixturesCount;

  @override
  Widget build(BuildContext context) {
    final countLabel = fixturesCount <= 1 ? 'match' : 'matchs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Matchs',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            fontFamily: 'RugbyJamImpact',
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            height: 0.9,
            shadows: const [
              Shadow(color: Color(0xCC8C1020), offset: Offset(0, 7)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${_formatLongDate(selectedDate)} / $fixturesCount $countLabel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.grayCool,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.dates,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final date = dates[index];
          final selected = _isSameDay(date, selectedDate);

          return _DateChip(
            date: date,
            selected: selected,
            onTap: () => onSelected(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: 66,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primaryHover : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x40E63946),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDateChipLabel(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? AppColors.white : AppColors.grayCool,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date.day.toString().padLeft(2, '0'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchFilterTabs extends StatelessWidget {
  const _MatchFilterTabs({
    required this.fixtures,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<RugbyFixture> fixtures;
  final _MatchFilter selectedFilter;
  final ValueChanged<_MatchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: _MatchFilter.values.map((filter) {
            final selected = selectedFilter == filter;
            final count = _filterFixtures(fixtures, filter).length;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0x2EE63946)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${_filterLabel(filter)} $count',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? AppColors.white : AppColors.grayCool,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
