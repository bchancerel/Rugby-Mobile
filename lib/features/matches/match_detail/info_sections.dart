part of '../match_detail_screen.dart';

class _MatchScoreBreakdown extends StatelessWidget {
  const _MatchScoreBreakdown({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final hasOvertime = _hasOvertime(fixture);

    return _MatchDetailSection(
      eyebrow: 'Details',
      title: 'Detail du score',
      child: Column(
        children: [
          _ScoreBreakdownRow(
            label: 'Periode',
            home: fixture.teams.home.name ?? 'Dom.',
            away: fixture.teams.away.name ?? 'Ext.',
            header: true,
          ),
          _ScoreBreakdownRow(
            label: 'Mi-temps',
            home: fixture.periods.first.home?.toString() ?? '-',
            away: fixture.periods.first.away?.toString() ?? '-',
          ),
          _ScoreBreakdownRow(
            label: 'Deuxieme periode',
            home: fixture.periods.second.home?.toString() ?? '-',
            away: fixture.periods.second.away?.toString() ?? '-',
          ),
          if (hasOvertime)
            _ScoreBreakdownRow(
              label: 'Prolongation',
              home: fixture.periods.overtime.home?.toString() ?? '-',
              away: fixture.periods.overtime.away?.toString() ?? '-',
            ),
          if (_hasPeriodScore(fixture.periods.secondOvertime))
            _ScoreBreakdownRow(
              label: 'Deuxieme prolongation',
              home: fixture.periods.secondOvertime.home?.toString() ?? '-',
              away: fixture.periods.secondOvertime.away?.toString() ?? '-',
            ),
          _ScoreBreakdownRow(
            label: 'Score final',
            home: fixture.score.home?.toString() ?? '-',
            away: fixture.score.away?.toString() ?? '-',
            finalRow: true,
          ),
        ],
      ),
    );
  }
}

class _ScoreBreakdownRow extends StatelessWidget {
  const _ScoreBreakdownRow({
    required this.label,
    required this.home,
    required this.away,
    this.header = false,
    this.finalRow = false,
  });

  final String label;
  final String home;
  final String away;
  final bool header;
  final bool finalRow;

  @override
  Widget build(BuildContext context) {
    final textColor = finalRow ? AppColors.white : AppColors.grayCool;
    final scoreColor = finalRow ? AppColors.primary : AppColors.white;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: finalRow ? const Color(0x24E63946) : Colors.transparent,
        border: Border(
          top: BorderSide(
            color: header ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: header ? AppColors.white : textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                home,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: header ? AppColors.grayCool : scoreColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                away,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: header ? AppColors.grayCool : scoreColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchInfoSection extends StatelessWidget {
  const _MatchInfoSection({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    return _MatchDetailSection(
      eyebrow: 'Informations',
      title: 'Informations',
      child: Column(
        children: [
          _InfoGridTile(
            icon: Icons.emoji_events,
            label: 'Competition',
            value: _formatNullableText(fixture.league.name),
          ),
          _InfoGridTile(
            icon: Icons.calendar_month,
            label: 'Saison',
            value: _formatNullableText(fixture.league.season),
          ),
          _InfoGridTile(
            icon: Icons.flag,
            label: 'Journee',
            value: _formatNullableText(fixture.league.round),
          ),
          _InfoGridTile(
            icon: Icons.sports_rugby,
            label: 'Statut',
            value: _matchStatusLabel(fixture),
          ),
          _InfoGridTile(
            icon: Icons.schedule,
            label: 'Coup d’envoi',
            value: _formatFullKickoff(fixture.date),
          ),
          _InfoGridTile(
            icon: Icons.public,
            label: 'Fuseau',
            value: _formatNullableText(fixture.timezone),
          ),
          _InfoGridTile(
            icon: Icons.home,
            label: fixture.teams.home.name ?? 'Domicile',
            value: _formatWinner(fixture.teams.home.winner),
          ),
          _InfoGridTile(
            icon: Icons.flight_takeoff,
            label: fixture.teams.away.name ?? 'Exterieur',
            value: _formatWinner(fixture.teams.away.winner),
          ),
          _InfoGridTile(
            icon: Icons.tag,
            label: 'Reference',
            value: _formatTimestamp(fixture.timestamp),
          ),
        ],
      ),
    );
  }
}

class _InfoGridTile extends StatelessWidget {
  const _InfoGridTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x66020617),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayCool,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
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

class _MatchDetailSection extends StatelessWidget {
  const _MatchDetailSection({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
