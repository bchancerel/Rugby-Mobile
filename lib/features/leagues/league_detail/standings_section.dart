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
          _StandingGroupSection(
            group: entry.value,
            overview: overview,
          ),
          if (entry.key != groups.length - 1)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StandingGroupSection extends StatelessWidget {
  const _StandingGroupSection({
    required this.group,
    required this.overview,
  });

  final RugbyStandingGroup group;
  final RugbyLeagueOverview overview;

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
            for (final row in group.rows)
              _StandingRow(
                row: row,
                overview: overview,
              ),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({
    required this.row,
    required this.overview,
  });

  final RugbyStanding row;
  final RugbyLeagueOverview overview;

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
              Expanded(
                child: _StandingTeamCell(
                  row: row,
                  routeName: _teamDetailRoute(
                    teamId: row.team.id,
                    leagueId: overview.league.id,
                    season: overview.season,
                  ),
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

}

class _StandingTeamCell extends StatelessWidget {
  const _StandingTeamCell({
    required this.row,
    required this.routeName,
  });

  final RugbyStanding row;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final teamIdentity = Row(
      children: [
        _TeamLogo(url: row.team.logo),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            row.team.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (routeName == null)
          teamIdentity
        else
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pushNamed(routeName!),
            child: teamIdentity,
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
    return SizedBox(
      width: 34,
      height: 34,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: url == null
            ? const Icon(
                Icons.shield_outlined,
                color: AppColors.red,
                size: 20,
              )
            : Image.network(
                url!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.shield_outlined,
                    color: AppColors.red,
                    size: 20,
                  );
                },
              ),
      ),
    );
  }
}

