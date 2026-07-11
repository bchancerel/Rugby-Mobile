part of 'package:rugby_jam_mobile/features/dashboard/dashboard_screen.dart';

class _UpcomingMatches extends StatelessWidget {
  const _UpcomingMatches({
    required this.matches,
    required this.onOpenRoute,
  });

  final List<RugbyFavoriteMatch> matches;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Prochains matchs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () => onOpenRoute(AppRoutes.matches),
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (matches.isEmpty)
          const _PanelMessage(
            icon: Icons.event_busy,
            title: 'Aucun prochain match',
            message: 'Ajoute des equipes favorites ou consulte le calendrier.',
          )
        else
          ...matches.map((match) => _MatchCard(match: match)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final RugbyFavoriteMatch match;

  @override
  Widget build(BuildContext context) {
    final fixture = match.nextFixture;
    if (fixture == null) {
      return const SizedBox.shrink();
    }

    final onTap = fixture.id == null
        ? null
        : () => Navigator.of(context).pushNamed(
              '${AppRoutes.matches}/${fixture.id}',
            );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: _PressableScale(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RemoteLogo(url: match.logo, icon: Icons.groups),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Text(
                              formatRugbyKickoff(fixture.date),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _FixtureStatusBadge(fixture: fixture),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _TeamName(team: fixture.teams.home)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          formatRugbyScore(fixture.score),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Expanded(
                        child: _TeamName(
                          team: fixture.teams.away,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    fixture.league.name ?? 'Competition',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  const _TeamName({
    required this.team,
    this.textAlign = TextAlign.left,
  });

  final RugbyFixtureTeam team;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      team.name ?? 'Equipe',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _RemoteLogo extends StatelessWidget {
  const _RemoteLogo({
    required this.url,
    required this.icon,
  });

  final String? url;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.white),
        child: SizedBox(
          width: 44,
          height: 44,
          child: imageUrl == null || imageUrl.isEmpty
              ? Icon(icon, color: AppColors.primary)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    icon,
                    color: AppColors.primary,
                  ),
                ),
        ),
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
            _StatusDot(color: status.color, pulse: status.isLive),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: status.textColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({
    required this.color,
    required this.pulse,
  });

  final Color color;
  final bool pulse;

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.pulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 8, height: 8),
    );

    if (!widget.pulse) {
      return dot;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.82 + (_controller.value * 0.46),
          child: child,
        );
      },
      child: dot,
    );
  }
}

