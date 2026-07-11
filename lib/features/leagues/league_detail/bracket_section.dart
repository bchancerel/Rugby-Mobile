part of '../league_detail_screen.dart';

class _BracketRoundTile extends StatelessWidget {
  const _BracketRoundTile({
    required this.round,
    required this.initiallyExpanded,
  });

  final _FixtureRound round;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xA6020617),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          iconColor: AppColors.white,
          collapsedIconColor: AppColors.grayCool,
          title: Text(
            round.label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          subtitle: Text(
            '${round.fixtures.length} matchs',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.grayCool,
                  fontWeight: FontWeight.w800,
                ),
          ),
          children: [
            for (final fixture in round.fixtures) ...[
              _BracketMatchCard(fixture: fixture),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  const _BracketMatchCard({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final canOpenMatch = fixture.id != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canOpenMatch
          ? () => Navigator.of(context).pushNamed(
                '${AppRoutes.matches}/${fixture.id}',
              )
          : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x4D111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  _FixtureStatusBadge(fixture: fixture),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      formatRugbyKickoff(fixture.date),
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
              const SizedBox(height: AppSpacing.md),
              _BracketTeamLine(
                name: fixture.teams.home.name ?? 'Domicile',
                score: fixture.score.home,
              ),
              const SizedBox(height: AppSpacing.xs),
              _BracketTeamLine(
                name: fixture.teams.away.name ?? 'Exterieur',
                score: fixture.score.away,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BracketTeamLine extends StatelessWidget {
  const _BracketTeamLine({
    required this.name,
    required this.score,
  });

  final String name;
  final int? score;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          score?.toString() ?? '-',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

