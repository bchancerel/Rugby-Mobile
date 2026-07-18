part of '../matches_screen.dart';

class _LeagueMatchGroup extends StatelessWidget {
  const _LeagueMatchGroup({required this.group});

  final _LeagueFixtureGroup group;

  @override
  Widget build(BuildContext context) {
    final countLabel = group.fixtures.length <= 1 ? 'match' : 'matchs';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              _RemoteLogo(url: group.logo, icon: Icons.emoji_events, size: 26),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${group.fixtures.length} $countLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grayCool,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        for (final fixture in group.fixtures) ...[
          _MatchCard(fixture: fixture),
          if (fixture != group.fixtures.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final canOpenMatch = fixture.id != null;
    final kickoffLabel = _formatMatchTime(fixture);

    return _PressableScale(
      onTap: canOpenMatch
          ? () {
              SupporterTracking.trackFixtureOpened(fixture);
              Navigator.of(
                context,
              ).pushNamed('${AppRoutes.matches}/${fixture.id}');
            }
          : null,
      child: DecoratedBox(
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
              Row(
                children: [
                  _FixtureStatusBadge(fixture: fixture),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    kickoffLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (canOpenMatch)
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.grayCool,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _TeamLine(
                      team: fixture.teams.home,
                      routeName: _teamRouteForFixture(
                        fixture,
                        fixture.teams.home,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 58,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          formatRugbyScore(fixture.score),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _TeamLine(
                      team: fixture.teams.away,
                      routeName: _teamRouteForFixture(
                        fixture,
                        fixture.teams.away,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              if (fixture.league.round != null &&
                  fixture.league.round!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  fixture.league.round!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.grayCool),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.team,
    required this.routeName,
    this.textAlign = TextAlign.left,
  });

  final RugbyFixtureTeam team;
  final String? routeName;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final alignEnd = textAlign == TextAlign.right;
    final content = Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!alignEnd) ...[
          _RemoteLogo(url: team.logo, icon: Icons.shield_outlined, size: 36),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            team.name ?? 'Equipe',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
        ),
        if (alignEnd) ...[
          const SizedBox(width: AppSpacing.sm),
          _RemoteLogo(url: team.logo, icon: Icons.shield_outlined, size: 36),
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
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatefulWidget {
  const _StatusDot({required this.color, required this.pulse});

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
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
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
          ? Icon(icon, color: AppColors.primary, size: size * 0.76)
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return Icon(icon, color: AppColors.primary, size: size * 0.76);
              },
            ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  const _PressableScale({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
