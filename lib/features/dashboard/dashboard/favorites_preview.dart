part of 'package:rugby_jam_mobile/features/dashboard/dashboard_screen.dart';

class _FavoritesPreview extends StatelessWidget {
  const _FavoritesPreview({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final competitions = data.favorites.competitions.data.take(4).toList();
    final teams = data.favorites.teams.data.take(4).toList();
    final competitionLogos = {
      for (final favoriteMatch in data.matchesHome.favoriteMatches)
        if (favoriteMatch.type == 'competition')
          favoriteMatch.entityId: favoriteMatch.logo,
    };
    final teamContexts = _buildFavoriteTeamContexts(
      data.matchesHome.favoriteMatches,
    );
    final alertMatches = _buildDashboardAlertMatches(
      data.matchesHome.favoriteMatches,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Favoris', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        if (teams.isNotEmpty) ...[
          _DashboardAlertsPanel(matches: alertMatches),
          const SizedBox(height: AppSpacing.md),
        ],
        if (competitions.isNotEmpty) ...[
          _FavoriteStrip(
            title: 'Championnats',
            favorites: competitions,
            icon: Icons.emoji_events,
            logoBuilder: (favorite) => competitionLogos[favorite.entityId],
            routeBuilder: (favorite) =>
                '${AppRoutes.leagues}/${favorite.entityId}',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (teams.isNotEmpty)
          _FavoriteStrip(
            title: 'Equipes',
            favorites: teams,
            icon: Icons.groups,
            logoBuilder: (favorite) => teamContexts[favorite.entityId]?.logo,
            subtitleBuilder: (favorite) =>
                teamContexts[favorite.entityId]?.subtitle,
            showLogoFrame: false,
            routeBuilder: (favorite) =>
                teamContexts[favorite.entityId]?.routeName ??
                '${AppRoutes.teams}/${favorite.entityId}',
          ),
      ],
    );
  }
}

List<RugbyFavoriteMatch> _buildDashboardAlertMatches(
  List<RugbyFavoriteMatch> favoriteMatches,
) {
  final matches =
      favoriteMatches
          .where((match) => match.type == 'team' && match.nextFixture != null)
          .toList()
        ..sort(
          (a, b) => a.nextFixture!.sortTime.compareTo(b.nextFixture!.sortTime),
        );

  return matches.take(3).toList();
}

Map<String, _FavoriteTeamContext> _buildFavoriteTeamContexts(
  List<RugbyFavoriteMatch> favoriteMatches,
) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final contexts = <String, _FavoriteTeamContext>{};

  for (final favoriteMatch in favoriteMatches) {
    if (favoriteMatch.type != 'team') {
      continue;
    }

    final fixture = _pickFavoriteTeamContextFixture(favoriteMatch, now);
    contexts[favoriteMatch.entityId] = _FavoriteTeamContext(
      logo: _favoriteTeamLogo(favoriteMatch, fixture),
      routeName: _favoriteTeamRoute(favoriteMatch.entityId, fixture),
      subtitle: _favoriteTeamSubtitle(fixture),
    );
  }

  return contexts;
}

RugbyFixture? _pickFavoriteTeamContextFixture(
  RugbyFavoriteMatch favoriteMatch,
  int now,
) {
  final candidates = [favoriteMatch.nextFixture, favoriteMatch.lastFixture]
      .whereType<RugbyFixture>()
      .where((fixture) {
        return fixture.league.id != null && fixture.league.season != null;
      })
      .toList();

  if (candidates.isEmpty) {
    return null;
  }

  candidates.sort((a, b) {
    final distanceCompare = (a.sortTime - now).abs().compareTo(
      (b.sortTime - now).abs(),
    );

    if (distanceCompare != 0) {
      return distanceCompare;
    }

    return b.sortTime.compareTo(a.sortTime);
  });

  return candidates.first;
}

String? _favoriteTeamLogo(
  RugbyFavoriteMatch favoriteMatch,
  RugbyFixture? fixture,
) {
  final logo = favoriteMatch.logo;
  if (logo != null && logo.isNotEmpty) {
    return logo;
  }

  final teamId = int.tryParse(favoriteMatch.entityId);
  if (teamId == null || fixture == null) {
    return logo;
  }

  if (fixture.teams.home.id == teamId) {
    return fixture.teams.home.logo;
  }

  if (fixture.teams.away.id == teamId) {
    return fixture.teams.away.logo;
  }

  return logo;
}

String _favoriteTeamRoute(String teamId, RugbyFixture? fixture) {
  final leagueId = fixture?.league.id;
  final season = fixture?.league.season;

  if (leagueId == null || season == null) {
    return '${AppRoutes.teams}/$teamId';
  }

  return '${AppRoutes.teams}/$teamId?league=$leagueId&season=$season';
}

String? _favoriteTeamSubtitle(RugbyFixture? fixture) {
  if (fixture == null) {
    return null;
  }

  final leagueName = fixture.league.name;
  final season = fixture.league.season;

  if (leagueName == null || leagueName.isEmpty) {
    return season == null ? null : 'Saison $season';
  }

  return season == null ? leagueName : '$leagueName / Saison $season';
}

class _FavoriteTeamContext {
  const _FavoriteTeamContext({
    required this.logo,
    required this.routeName,
    required this.subtitle,
  });

  final String? logo;
  final String routeName;
  final String? subtitle;
}

class _DashboardAlertsPanel extends StatefulWidget {
  const _DashboardAlertsPanel({required this.matches});

  final List<RugbyFavoriteMatch> matches;

  @override
  State<_DashboardAlertsPanel> createState() => _DashboardAlertsPanelState();
}

class _DashboardAlertsPanelState extends State<_DashboardAlertsPanel> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0x59FBBF24)),
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x24FBBF24), Color(0x1000D47E)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x24FBBF24),
                    border: Border.all(color: const Color(0x66FBBF24)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 4,
                    ),
                    child: Text(
                      'ALERT',
                      style: TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'A surveiller',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.matches.isEmpty)
              Text(
                'Aucun prochain match trouve pour tes equipes favorites.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.grayCool),
              )
            else
              ...widget.matches.map(
                (match) => _DashboardAlertRow(match: match, now: _now),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAlertRow extends StatelessWidget {
  const _DashboardAlertRow({required this.match, required this.now});

  final RugbyFavoriteMatch match;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final fixture = match.nextFixture;
    if (fixture == null) {
      return const SizedBox.shrink();
    }

    final routeName = fixture.id == null
        ? AppRoutes.matches
        : '${AppRoutes.matches}/${fixture.id}';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: _PressableScale(
        onTap: () {
          SupporterTracking.trackFixtureOpened(fixture);
          Navigator.of(context).pushNamed(routeName);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x4D020617),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                _FavoriteLogo(
                  url: match.logo,
                  icon: Icons.groups,
                  showFrame: false,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dashboardAlertTitle(match, fixture),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dashboardAlertSubtitle(fixture),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grayCool,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _CountdownPill(label: _formatDashboardCountdown(fixture, now)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x26FBBF24),
        border: Border.all(color: const Color(0x66FBBF24)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFFDE68A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _dashboardAlertTitle(RugbyFavoriteMatch match, RugbyFixture fixture) {
  final favoriteTeamName = match.label;
  final homeName = fixture.teams.home.name;
  final awayName = fixture.teams.away.name;

  if (homeName == null || awayName == null) {
    return '$favoriteTeamName joue bientot';
  }

  return '$homeName - $awayName';
}

String _dashboardAlertSubtitle(RugbyFixture fixture) {
  final league = fixture.league.name ?? 'Competition';
  return '$league - ${formatRugbyKickoff(fixture.date)}';
}

String _formatDashboardCountdown(RugbyFixture fixture, DateTime now) {
  final kickoffTime = rugbyFixtureKickoffTime(fixture);
  if (kickoffTime == null) {
    return 'Bientot';
  }

  final kickoff = DateTime.fromMillisecondsSinceEpoch(kickoffTime).toLocal();
  final diff = kickoff.difference(now);
  if (diff.isNegative) {
    return diff.abs() < const Duration(hours: 4) ? 'Live' : 'Termine';
  }

  if (diff >= const Duration(days: 7)) {
    return _formatDashboardCountdownDate(kickoff);
  }

  if (diff >= const Duration(hours: 24)) {
    return 'J-${_ceilDurationUnit(diff, const Duration(days: 1))}';
  }

  if (diff >= const Duration(hours: 1)) {
    return 'H-${_ceilDurationUnit(diff, const Duration(hours: 1))}';
  }

  if (diff >= const Duration(minutes: 1)) {
    return 'Dans ${_ceilDurationUnit(diff, const Duration(minutes: 1))} min';
  }

  return 'Maintenant';
}

int _ceilDurationUnit(Duration duration, Duration unit) {
  return (duration.inMilliseconds / unit.inMilliseconds).ceil();
}

String _formatDashboardCountdownDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

class _FavoriteStrip extends StatelessWidget {
  const _FavoriteStrip({
    required this.title,
    required this.favorites,
    required this.icon,
    required this.routeBuilder,
    this.showLogoFrame = true,
    this.logoBuilder,
    this.subtitleBuilder,
  });

  final String title;
  final List<Favorite> favorites;
  final IconData icon;
  final String Function(Favorite favorite) routeBuilder;
  final bool showLogoFrame;
  final String? Function(Favorite favorite)? logoBuilder;
  final String? Function(Favorite favorite)? subtitleBuilder;

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
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            ...favorites.map(
              (favorite) => _FavoriteRow(
                icon: icon,
                logo: logoBuilder?.call(favorite),
                showLogoFrame: showLogoFrame,
                hasLogoSlot: logoBuilder != null,
                label: favorite.entityName ?? favorite.entityId,
                subtitle: subtitleBuilder?.call(favorite),
                onTap: () =>
                    Navigator.of(context).pushNamed(routeBuilder(favorite)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteRow extends StatelessWidget {
  const _FavoriteRow({
    required this.icon,
    required this.logo,
    required this.showLogoFrame,
    required this.hasLogoSlot,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String? logo;
  final bool showLogoFrame;
  final bool hasLogoSlot;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 24,
        leading: hasLogoSlot
            ? _FavoriteLogo(url: logo, icon: icon, showFrame: showLogoFrame)
            : Icon(icon, color: AppColors.primary),
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.grayCool),
              ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _FavoriteLogo extends StatelessWidget {
  const _FavoriteLogo({
    required this.url,
    required this.icon,
    required this.showFrame,
  });

  final String? url;
  final IconData icon;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: showFrame ? const Color(0xE6CBD5E1) : Colors.transparent,
        border: Border.all(
          color: showFrame ? const Color(0x4DFFFFFF) : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: imageUrl == null || imageUrl.isEmpty
              ? Icon(icon, color: AppColors.primary, size: 20)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(icon, color: AppColors.primary, size: 20);
                  },
                ),
        ),
      ),
    );
  }
}
