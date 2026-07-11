part of '../league_detail_screen.dart';

class _StandingsSection extends StatelessWidget {
  const _StandingsSection({required this.overview});

  final RugbyLeagueOverview overview;

  @override
  Widget build(BuildContext context) {
    final groups = overview.standings
        .where((group) => group.rows.isNotEmpty)
        .toList(growable: false);

    if (groups.isEmpty) {
      return const _ComingSoonPanel(
        key: ValueKey('empty-standings'),
        icon: Icons.leaderboard,
        title: 'Classement indisponible',
        message: 'Aucun classement disponible pour cette saison.',
      );
    }

    return Column(
      key: const ValueKey('standings'),
      children: [
        for (final entry in groups.asMap().entries) ...[
          _StandingGroupSection(group: entry.value),
          if (entry.key != groups.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StandingGroupSection extends StatelessWidget {
  const _StandingGroupSection({required this.group});

  final RugbyStandingGroup group;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _SummaryPill(
                  label: '${group.rows.length} equipes',
                  value: '',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final row in group.rows) _StandingRow(row: row),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.row});

  final RugbyStanding row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x4D111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  row.rank?.toString() ?? '-',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TeamLogo(url: row.team.logo),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.team.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _standingMeta(row),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.grayCool,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${row.points ?? 0}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    'pts',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.grayCool,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _standingMeta(RugbyStanding row) {
    final played = row.all.played ?? 0;
    final wins = row.all.win ?? 0;
    final draws = row.all.draw ?? 0;
    final losses = row.all.loss ?? 0;
    final diff = row.pointsDiff ?? 0;
    final diffLabel = diff > 0 ? '+$diff' : diff.toString();

    return '$played J / $wins V / $draws N / $losses D / Diff $diffLabel';
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: url == null
              ? const Icon(
                  Icons.shield_outlined,
                  color: AppColors.red,
                  size: 18,
                )
              : Image.network(
                  url!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_outlined,
                      color: AppColors.red,
                      size: 18,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

