part of '../match_detail_screen.dart';

class _MatchDetailBackButton extends StatelessWidget {
  const _MatchDetailBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back),
        color: AppColors.white,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xA6020617),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _MatchScoreboard extends StatelessWidget {
  const _MatchScoreboard({
    required this.fixture,
    required this.liveLastUpdatedAt,
    required this.scoringSides,
  });

  final RugbyFixture fixture;
  final DateTime? liveLastUpdatedAt;
  final Set<String> scoringSides;

  @override
  Widget build(BuildContext context) {
    final status = rugbyFixtureStatus(fixture);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _MatchCompetitionHeader(fixture: fixture),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(color: Color(0x66020617)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _formatLongKickoffDate(fixture.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grayCool,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      fixture.league.round ?? 'Match',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _FixtureStatusBadge(fixture: fixture),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _MatchDetailTeam(
                          fixture: fixture,
                          team: fixture.teams.home,
                          isScoring: scoringSides.contains('home'),
                        ),
                      ),
                      _MatchDetailScore(
                        fixture: fixture,
                        liveLastUpdatedAt: liveLastUpdatedAt,
                      ),
                      Expanded(
                        child: _MatchDetailTeam(
                          fixture: fixture,
                          team: fixture.teams.away,
                          away: true,
                          isScoring: scoringSides.contains('away'),
                        ),
                      ),
                    ],
                  ),
                  if (status.isLive) ...[
                    const SizedBox(height: AppSpacing.md),
                    _LiveRefreshNotice(updatedAt: liveLastUpdatedAt),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCompetitionHeader extends StatelessWidget {
  const _MatchCompetitionHeader({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final routeName = _leagueDetailRoute(fixture);
    final content = Row(
      children: [
        _RemoteLogo(
          url: fixture.league.logo,
          icon: Icons.emoji_events,
          size: 48,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fixture.league.name ?? 'Competition',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              if (fixture.league.season != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Saison ${fixture.league.season}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grayCool,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (routeName != null)
          const Icon(Icons.chevron_right, color: AppColors.grayCool),
      ],
    );

    if (routeName == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pushNamed(routeName),
      child: content,
    );
  }
}

class _MatchDetailTeam extends StatelessWidget {
  const _MatchDetailTeam({
    required this.fixture,
    required this.team,
    this.away = false,
    this.isScoring = false,
  });

  final RugbyFixture fixture;
  final RugbyFixtureTeam team;
  final bool away;
  final bool isScoring;

  @override
  Widget build(BuildContext context) {
    final routeName = _teamDetailRoute(fixture, team);
    final content = Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(isScoring ? 6 : 0),
          decoration: BoxDecoration(
            color: isScoring ? const Color(0x33E63946) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isScoring
                ? const [
                    BoxShadow(
                      color: Color(0x99E63946),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : const [],
          ),
          child: _RemoteLogo(
            url: team.logo,
            icon: Icons.shield_outlined,
            size: 72,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          team.name ?? (away ? 'Exterieur' : 'Domicile'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _teamRoleLabel(away),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.grayCool,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );

    if (routeName == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pushNamed(routeName),
      child: content,
    );
  }
}

class _MatchDetailScore extends StatelessWidget {
  const _MatchDetailScore({
    required this.fixture,
    required this.liveLastUpdatedAt,
  });

  final RugbyFixture fixture;
  final DateTime? liveLastUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final hasScore = fixture.score.home != null && fixture.score.away != null;
    final statusLabel = _matchStatusLabel(fixture);

    return SizedBox(
      width: 92,
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40E63946),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: SizedBox(
              width: 86,
              height: 58,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    hasScore
                        ? '${fixture.score.home} - ${fixture.score.away}'
                        : _formatKickoffTime(fixture.date),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.blackBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.grayCool,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (fixture.status.elapsed != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              "${fixture.status.elapsed}'",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveRefreshNotice extends StatelessWidget {
  const _LiveRefreshNotice({required this.updatedAt});

  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final label = _formatLiveLastUpdated(updatedAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x2EE63946),
        border: Border.all(color: const Color(0x66FF4655)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync, color: Color(0xFFFECACA), size: 16),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label == null
                    ? 'Actualisation automatique'
                    : 'Actualise a $label',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFFECACA),
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

class _RemoteLogo extends StatelessWidget {
  const _RemoteLogo({
    required this.url,
    required this.icon,
    required this.size,
  });

  final String? url;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return SizedBox(
      width: size,
      height: size,
      child: imageUrl == null || imageUrl.isEmpty
          ? Icon(icon, color: AppColors.primary, size: size * 0.72)
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return Icon(icon, color: AppColors.primary, size: size * 0.72);
              },
            ),
    );
  }
}

class _FixtureStatusBadge extends StatelessWidget {
  const _FixtureStatusBadge({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final status = rugbyFixtureStatus(fixture);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.background,
        border: Border.all(color: status.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status.isLive ? Icons.circle : Icons.sports_rugby,
              color: status.color,
              size: status.isLive ? 8 : 14,
            ),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: status.textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
