part of '../team_detail_screen.dart';

class _TeamFixturesSection extends StatelessWidget {
  const _TeamFixturesSection({required this.fixtures});

  final List<RugbyFixture> fixtures;

  @override
  Widget build(BuildContext context) {
    return _TeamPanel(
      title: 'Matchs',
      icon: Icons.sports_rugby,
      trailing: Text(
        '${fixtures.length} match${fixtures.length > 1 ? 's' : ''}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.grayCool,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: fixtures.isEmpty
          ? const _TeamPanelMessage(
              icon: Icons.event_busy,
              title: 'Aucun match',
              message: 'Aucun match trouve pour cette equipe sur ce contexte.',
            )
          : Column(
              children: [
                for (final fixture in fixtures) ...[
                  _TeamFixtureCard(fixture: fixture),
                  if (fixture != fixtures.last)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _TeamPanel extends StatelessWidget {
  const _TeamPanel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.redAccent, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _TeamStatTile extends StatelessWidget {
  const _TeamStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.grayCool,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

class _TeamFixtureCard extends StatelessWidget {
  const _TeamFixtureCard({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final canOpenMatch = fixture.id != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                _TeamFixtureStatusBadge(fixture: fixture),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _fixtureRoundLabel(fixture),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    formatRugbyKickoff(fixture.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _TeamFixtureTeamLine(
                    team: fixture.teams.home,
                    routeName: _teamRouteForFixture(
                      fixture,
                      fixture.teams.home,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: _TeamFixtureScoreButton(
                    score: formatRugbyScore(fixture.score),
                    onTap: canOpenMatch
                        ? () {
                            SupporterTracking.trackFixtureOpened(fixture);
                            Navigator.of(
                              context,
                            ).pushNamed('${AppRoutes.matches}/${fixture.id}');
                          }
                        : null,
                  ),
                ),
                Expanded(
                  child: _TeamFixtureTeamLine(
                    team: fixture.teams.away,
                    routeName: _teamRouteForFixture(
                      fixture,
                      fixture.teams.away,
                    ),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamFixtureScoreButton extends StatelessWidget {
  const _TeamFixtureScoreButton({required this.score, required this.onTap});

  final String score;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xA6020617),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: 68,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              score,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamFixtureTeamLine extends StatelessWidget {
  const _TeamFixtureTeamLine({
    required this.team,
    required this.routeName,
    this.alignEnd = false,
  });

  final RugbyFixtureTeam team;
  final String? routeName;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          _FixtureTeamLogo(url: team.logo),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            team.name ?? 'Equipe',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: alignEnd ? TextAlign.right : TextAlign.left,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: AppSpacing.xs),
          _FixtureTeamLogo(url: team.logo),
        ],
      ],
    );

    if (routeName == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pushNamed(routeName!),
      child: content,
    );
  }
}

class _FixtureTeamLogo extends StatelessWidget {
  const _FixtureTeamLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return SizedBox(
      width: 28,
      height: 28,
      child: imageUrl == null || imageUrl.isEmpty
          ? const Icon(Icons.shield_outlined, color: AppColors.red, size: 22)
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const Icon(
                  Icons.shield_outlined,
                  color: AppColors.red,
                  size: 22,
                );
              },
            ),
    );
  }
}

class _TeamFixtureStatusBadge extends StatelessWidget {
  const _TeamFixtureStatusBadge({required this.fixture});

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
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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
