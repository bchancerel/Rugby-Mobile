import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_repository.dart';

enum _LeagueDetailTab {
  standings,
  matches,
  bracket,
}

class LeagueDetailScreen extends StatefulWidget {
  const LeagueDetailScreen({
    required this.leagueId,
    this.initialSeason,
    super.key,
  });

  final int leagueId;
  final int? initialSeason;

  @override
  State<LeagueDetailScreen> createState() => _LeagueDetailScreenState();
}

class _LeagueDetailScreenState extends State<LeagueDetailScreen> {
  final _repository = LeaguesRepository();

  RugbyLeagueOverview? _overview;
  String _errorMessage = '';
  int? _selectedSeason;
  _LeagueDetailTab _selectedTab = _LeagueDetailTab.standings;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.initialSeason;
    _loadOverview();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadOverview({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _overview != null) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final overview = await _repository.fetchLeagueOverview(
        widget.leagueId,
        season: _selectedSeason,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = overview;
        _selectedSeason ??= overview?.season;
        if (overview != null &&
            _selectedTab == _LeagueDetailTab.bracket &&
            !_hasBracketRounds(overview.fixtures, overview.rounds)) {
          _selectedTab = _LeagueDetailTab.standings;
        }
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Impossible de charger cette competition.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  void _selectSeason(int season) {
    if (_selectedSeason == season) {
      return;
    }

    setState(() {
      _selectedSeason = season;
    });
    _loadOverview(fromRefresh: true);
  }

  void _selectTab(_LeagueDetailTab tab) {
    if (_selectedTab == tab) {
      return;
    }

    setState(() {
      _selectedTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final routeName = '${AppRoutes.leagues}/${widget.leagueId}';
    final overview = _overview;
    final hasOverview = overview != null;
    final availableTabs = overview == null
        ? _LeagueDetailTab.values
        : _availableLeagueDetailTabs(overview);
    final selectedTab = availableTabs.contains(_selectedTab)
        ? _selectedTab
        : _LeagueDetailTab.standings;

    return AppNavScaffold(
      currentRoute: routeName,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadOverview(fromRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: const _LeagueDetailHeader(),
              ),
              if (_refreshing)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: _RefreshStatus(),
                  ),
                ),
              if (_loading && !hasOverview)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _LeagueDetailLoadingState(),
                  ),
                )
              else if (_errorMessage.isNotEmpty && !hasOverview)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LeagueDetailErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadOverview(),
                  ),
                )
              else if (!hasOverview)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LeagueDetailEmptyState(onRetry: () => _loadOverview()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (_errorMessage.isNotEmpty) ...[
                          _InlineAlert(message: _errorMessage),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _LeagueHero(overview: overview),
                        const SizedBox(height: AppSpacing.md),
                        _SeasonSelector(
                          seasons: overview.seasonOptions,
                          selectedSeason: _selectedSeason ?? overview.season,
                          onSelected: _selectSeason,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _LeagueDetailTabs(
                          tabs: availableTabs,
                          selectedTab: selectedTab,
                          onSelected: _selectTab,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _LeagueDetailContent(
                          overview: overview,
                          selectedTab: selectedTab,
                        ),
                      ],
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

class _LeagueDetailHeader extends StatelessWidget {
  const _LeagueDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        88,
        AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: IconButton(
          onPressed: () => Navigator.of(context).pushReplacementNamed(
            AppRoutes.leagues,
          ),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xA6020617),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _LeagueHero extends StatelessWidget {
  const _LeagueHero({required this.overview});

  final RugbyLeagueOverview overview;

  @override
  Widget build(BuildContext context) {
    final standingsCount = overview.standings.fold<int>(
      0,
      (total, group) => total + group.rows.length,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xE6020617),
              Color(0xF0111827),
              Color(0xCC7F1D2D),
            ],
          ),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LeagueLogo(url: overview.league.logo, size: 88),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overview.league.country.displayName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.redAccent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      overview.league.displayName,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontFamily: 'RugbyJamImpact',
                                color: AppColors.white,
                                height: 0.9,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xCC8C1020),
                                    offset: Offset(0, 7),
                                  ),
                                ],
                              ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _SummaryPill(
                          label: overview.league.type ?? 'Competition',
                          value: '',
                        ),
                        _SummaryPill(
                          label: overview.season == null
                              ? 'Saison'
                              : 'Saison ${overview.season}',
                          value: '',
                        ),
                        _SummaryPill(
                          label: '$standingsCount equipes',
                          value: '',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? label : '$value $label';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _LeagueLogo extends StatelessWidget {
  const _LeagueLogo({
    required this.url,
    required this.size,
  });

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: url == null
              ? const Icon(
                  Icons.emoji_events,
                  color: AppColors.red,
                  size: 34,
                )
              : Image.network(
                  url!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.emoji_events,
                      color: AppColors.red,
                      size: 34,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SeasonSelector extends StatelessWidget {
  const _SeasonSelector({
    required this.seasons,
    required this.selectedSeason,
    required this.onSelected,
  });

  final List<int> seasons;
  final int? selectedSeason;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (seasons.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month,
              color: AppColors.redAccent,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Saison',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: seasons.contains(selectedSeason) ? selectedSeason : null,
                hint: const Text('Choisir'),
                dropdownColor: AppColors.night,
                iconEnabledColor: AppColors.white,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                items: seasons
                    .map(
                      (season) => DropdownMenuItem<int>(
                        value: season,
                        child: Text(season.toString()),
                      ),
                    )
                    .toList(),
                onChanged: (season) {
                  if (season != null) {
                    onSelected(season);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueDetailTabs extends StatelessWidget {
  const _LeagueDetailTabs({
    required this.tabs,
    required this.selectedTab,
    required this.onSelected,
  });

  final List<_LeagueDetailTab> tabs;
  final _LeagueDetailTab selectedTab;
  final ValueChanged<_LeagueDetailTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: tabs.map((tab) {
            final selected = selectedTab == tab;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x66E63946),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    _tabLabel(tab),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? AppColors.white : AppColors.grayCool,
                          fontWeight: FontWeight.w900,
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

  String _tabLabel(_LeagueDetailTab tab) {
    return switch (tab) {
      _LeagueDetailTab.standings => 'Classement',
      _LeagueDetailTab.matches => 'Matchs',
      _LeagueDetailTab.bracket => 'Tableau',
    };
  }
}

class _LeagueDetailContent extends StatelessWidget {
  const _LeagueDetailContent({
    required this.overview,
    required this.selectedTab,
  });

  final RugbyLeagueOverview overview;
  final _LeagueDetailTab selectedTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (selectedTab) {
        _LeagueDetailTab.standings => _StandingsSection(overview: overview),
        _LeagueDetailTab.matches => _MatchesSection(
            key: ValueKey('matches-${overview.season ?? 'all'}'),
            fixtures: overview.fixtures,
            rounds: overview.rounds,
          ),
        _LeagueDetailTab.bracket => _BracketSection(
            key: ValueKey('bracket-${overview.season ?? 'all'}'),
            fixtures: overview.fixtures,
            rounds: overview.rounds,
          ),
      },
    );
  }
}

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

class _MatchesSection extends StatefulWidget {
  const _MatchesSection({
    required this.fixtures,
    required this.rounds,
    super.key,
  });

  final List<RugbyFixture> fixtures;
  final List<String> rounds;

  @override
  State<_MatchesSection> createState() => _MatchesSectionState();
}

class _MatchesSectionState extends State<_MatchesSection> {
  static const _upcomingRoundThreshold = Duration(hours: 48);

  int _selectedRoundIndex = 0;
  bool _shouldAutoSelectRound = true;

  @override
  Widget build(BuildContext context) {
    final rounds = _buildMatchRounds(widget.fixtures, widget.rounds);

    if (rounds.isEmpty) {
      return const _ComingSoonPanel(
        key: ValueKey('empty-matches'),
        icon: Icons.sports_rugby,
        title: 'Matchs indisponibles',
        message: 'Aucun match disponible pour cette saison.',
      );
    }

    if (_shouldAutoSelectRound) {
      _selectedRoundIndex = _findDefaultMatchRoundIndex(rounds);
      _shouldAutoSelectRound = false;
    }

    var selectedIndex = _selectedRoundIndex;
    if (selectedIndex < 0) {
      selectedIndex = 0;
    } else if (selectedIndex >= rounds.length) {
      selectedIndex = rounds.length - 1;
    }
    final selectedRound = rounds[selectedIndex];

    return Column(
      key: const ValueKey('matches'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RoundSelector(
          rounds: rounds,
          selectedIndex: selectedIndex,
          onSelected: (index) {
            setState(() {
              _shouldAutoSelectRound = false;
              _selectedRoundIndex = index;
            });
          },
          onPrevious: selectedIndex == 0
              ? null
              : () {
                  setState(() {
                    _shouldAutoSelectRound = false;
                    _selectedRoundIndex = selectedIndex - 1;
                  });
                },
          onNext: selectedIndex >= rounds.length - 1
              ? null
              : () {
                  setState(() {
                    _shouldAutoSelectRound = false;
                    _selectedRoundIndex = selectedIndex + 1;
                  });
                },
        ),
        const SizedBox(height: AppSpacing.md),
        for (final fixture in selectedRound.fixtures) ...[
          _MatchCard(fixture: fixture),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  int _findDefaultMatchRoundIndex(List<_FixtureRound> rounds) {
    if (rounds.isEmpty) {
      return 0;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final nextRound = _closestRound(
      rounds: rounds,
      test: (kickoff) => kickoff >= now,
      ascending: true,
    );

    if (nextRound != null &&
        nextRound.kickoff - now <= _upcomingRoundThreshold.inMilliseconds) {
      return nextRound.index;
    }

    final lastPlayedRound = _closestRound(
      rounds: rounds,
      test: (kickoff) => kickoff < now,
      ascending: false,
    );

    return lastPlayedRound?.index ?? nextRound?.index ?? 0;
  }

  _RoundKickoff? _closestRound({
    required List<_FixtureRound> rounds,
    required bool Function(int kickoff) test,
    required bool ascending,
  }) {
    final candidates = <_RoundKickoff>[];

    for (final entry in rounds.asMap().entries) {
      final kickoffs = entry.value.fixtures
          .map(_fixtureKickoffTime)
          .whereType<int>()
          .where(test)
          .toList()
        ..sort();

      if (kickoffs.isEmpty) {
        continue;
      }

      candidates.add(
        _RoundKickoff(
          index: entry.key,
          kickoff: ascending ? kickoffs.first : kickoffs.last,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) => ascending
        ? a.kickoff.compareTo(b.kickoff)
        : b.kickoff.compareTo(a.kickoff));
    return candidates.first;
  }
}

class _BracketSection extends StatelessWidget {
  const _BracketSection({
    required this.fixtures,
    required this.rounds,
    super.key,
  });

  final List<RugbyFixture> fixtures;
  final List<String> rounds;

  @override
  Widget build(BuildContext context) {
    final bracketRounds = _buildBracketRounds(fixtures, rounds);

    if (bracketRounds.isEmpty) {
      return const _ComingSoonPanel(
        key: ValueKey('empty-bracket'),
        icon: Icons.account_tree,
        title: 'Tableau indisponible',
        message: 'Aucune phase finale detectee pour cette saison.',
      );
    }

    return Column(
      key: const ValueKey('bracket'),
      children: [
        for (final entry in bracketRounds.asMap().entries) ...[
          _BracketRoundTile(
            round: entry.value,
            initiallyExpanded: entry.key == 0,
          ),
          if (entry.key != bracketRounds.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RoundSelector extends StatelessWidget {
  const _RoundSelector({
    required this.rounds,
    required this.selectedIndex,
    required this.onSelected,
    required this.onPrevious,
    required this.onNext,
  });

  final List<_FixtureRound> rounds;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final selectedRound = rounds[selectedIndex];

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
                    selectedRound.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                _SummaryPill(
                  label: '${selectedRound.fixtures.length} matchs',
                  value: '',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.chevron_left,
                  onPressed: onPrevious,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x66111827),
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedIndex,
                          isExpanded: true,
                          dropdownColor: AppColors.night,
                          iconEnabledColor: AppColors.white,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                          items: rounds.asMap().entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.key,
                              child: Text(entry.value.label),
                            );
                          }).toList(),
                          onChanged: (index) {
                            if (index != null) {
                              onSelected(index);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _RoundIconButton(
                  icon: Icons.chevron_right,
                  onPressed: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.white,
      disabledColor: AppColors.grayCool.withOpacity(0.35),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x66111827),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.fixture});

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
          color: const Color(0xA6020617),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(20),
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
                      _formatKickoff(fixture.date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.grayCool,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
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
                    child: _FixtureTeamColumn(
                      name: fixture.teams.home.name ?? 'Domicile',
                      logo: fixture.teams.home.logo,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      _formatScore(fixture.score),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Expanded(
                    child: _FixtureTeamColumn(
                      name: fixture.teams.away.name ?? 'Exterieur',
                      logo: fixture.teams.away.logo,
                      alignEnd: true,
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

class _FixtureTeamColumn extends StatelessWidget {
  const _FixtureTeamColumn({
    required this.name,
    required this.logo,
    this.alignEnd = false,
  });

  final String name;
  final String? logo;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _TeamLogo(url: logo),
        const SizedBox(height: AppSpacing.xs),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
        ),
      ],
    );
  }
}

class _FixtureStatusBadge extends StatelessWidget {
  const _FixtureStatusBadge({required this.fixture});

  final RugbyFixture fixture;

  @override
  Widget build(BuildContext context) {
    final status = _fixtureStatus(fixture);

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
                      _formatKickoff(fixture.date),
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

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.redAccent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayCool,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueDetailLoadingState extends StatelessWidget {
  const _LeagueDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonBlock(height: 180),
        SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 86),
        SizedBox(height: AppSpacing.md),
        _SkeletonBlock(height: 220),
      ],
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A1424),
                Color(0xFF111827),
                Color(0xFF0A1424),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeagueDetailErrorState extends StatelessWidget {
  const _LeagueDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        132,
      ),
      child: _StatePanel(
        title: 'Competition indisponible',
        message: message,
        actionLabel: 'Reessayer',
        onAction: onRetry,
      ),
    );
  }
}

class _LeagueDetailEmptyState extends StatelessWidget {
  const _LeagueDetailEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        132,
      ),
      child: _StatePanel(
        title: 'Competition introuvable',
        message: 'Aucune donnee disponible pour cette competition.',
        actionLabel: 'Recharger',
        onAction: onRetry,
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xA6020617),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.grayCool,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: actionLabel,
              icon: Icons.refresh,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshStatus extends StatelessWidget {
  const _RefreshStatus();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Actualisation...',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.grayCool,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x33E63946),
        border: Border.all(color: const Color(0x88E63946)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _FixtureRound {
  const _FixtureRound({
    required this.name,
    required this.label,
    required this.fixtures,
  });

  final String name;
  final String label;
  final List<RugbyFixture> fixtures;
}

class _RoundKickoff {
  const _RoundKickoff({
    required this.index,
    required this.kickoff,
  });

  final int index;
  final int kickoff;
}

class _FixtureStatusInfo {
  const _FixtureStatusInfo({
    required this.label,
    required this.color,
    required this.textColor,
    required this.background,
    required this.border,
  });

  final String label;
  final Color color;
  final Color textColor;
  final Color background;
  final Color border;
}

List<_FixtureRound> _buildMatchRounds(
  List<RugbyFixture> fixtures,
  List<String> orderedRounds,
) {
  final groupedFixtures = <String, List<RugbyFixture>>{};

  for (final fixture in fixtures) {
    final roundName = fixture.league.round ?? 'Matchs';
    groupedFixtures.putIfAbsent(roundName, () => []).add(fixture);
  }

  final roundNames = [
    ...orderedRounds.where((roundName) => groupedFixtures.containsKey(roundName)),
    ...groupedFixtures.keys
        .where((roundName) => !orderedRounds.contains(roundName)),
  ];

  return roundNames.map((roundName) {
    final fixturesForRound = groupedFixtures[roundName] ?? const <RugbyFixture>[];
    final roundFixtures = [...fixturesForRound]
      ..sort((a, b) => a.sortTime.compareTo(b.sortTime));

    return _FixtureRound(
      name: roundName,
      label: _formatRoundLabel(roundName),
      fixtures: roundFixtures,
    );
  }).toList();
}

List<_FixtureRound> _buildBracketRounds(
  List<RugbyFixture> fixtures,
  List<String> orderedRounds,
) {
  return _buildMatchRounds(fixtures, orderedRounds)
      .where((round) => _isKnockoutRound(round.name))
      .toList();
}

List<_LeagueDetailTab> _availableLeagueDetailTabs(RugbyLeagueOverview overview) {
  return [
    _LeagueDetailTab.standings,
    _LeagueDetailTab.matches,
    if (_hasBracketRounds(overview.fixtures, overview.rounds))
      _LeagueDetailTab.bracket,
  ];
}

bool _hasBracketRounds(
  List<RugbyFixture> fixtures,
  List<String> orderedRounds,
) {
  return _buildBracketRounds(fixtures, orderedRounds).isNotEmpty;
}

int? _fixtureKickoffTime(RugbyFixture fixture) {
  if (fixture.timestamp != null) {
    return fixture.timestamp! * 1000;
  }

  final kickoff = fixture.date == null ? null : DateTime.tryParse(fixture.date!);
  return kickoff?.millisecondsSinceEpoch;
}

String _formatRoundLabel(String round) {
  final value = round.toLowerCase();
  final regularSeasonMatch =
      RegExp(r'regular season\s*-\s*(\d+)', caseSensitive: false)
              .firstMatch(round) ??
          RegExp(r'(?:round|journ.e|matchday)\s*[- ]\s*(\d+)',
                  caseSensitive: false)
              .firstMatch(round);

  if (regularSeasonMatch != null) {
    return 'Journee ${regularSeasonMatch.group(1)}';
  }

  if (value.contains('round of 16')) {
    return 'Huitiemes de finale';
  }

  if (value.contains('round of 8') || value.contains('quarter')) {
    return 'Quarts de finale';
  }

  if (value.contains('semi')) {
    return 'Demi-finales';
  }

  if (value.contains('final')) {
    return 'Finale';
  }

  if (value.contains('playoff') ||
      value.contains('play-off') ||
      value.contains('barrage')) {
    return 'Barrages';
  }

  return round;
}

bool _isKnockoutRound(String round) {
  final value = round.toLowerCase();
  const keywords = [
    'final',
    'semi',
    'quarter',
    'round of',
    'knockout',
    'playoff',
    'play-off',
    'barrage',
    'accession',
  ];

  return keywords.any((keyword) => value.contains(keyword));
}

String _formatScore(RugbyFixtureScore score) {
  if (score.home == null || score.away == null) {
    return 'vs';
  }

  return '${score.home} - ${score.away}';
}

String _formatKickoff(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date a venir';
  }

  final kickoff = DateTime.tryParse(value);
  if (kickoff == null) {
    return 'Date a venir';
  }

  final local = kickoff.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month - $hour:$minute';
}

_FixtureStatusInfo _fixtureStatus(RugbyFixture fixture) {
  if (fixture.score.home != null && fixture.score.away != null) {
    return const _FixtureStatusInfo(
      label: 'Termine',
      color: Color(0xFF22C55E),
      textColor: Color(0xFFC7F7DC),
      background: Color(0x1F3FB984),
      border: Color(0x663FB984),
    );
  }

  final kickoff = fixture.date == null ? null : DateTime.tryParse(fixture.date!);
  final localKickoff = kickoff?.toLocal();
  final now = DateTime.now();
  final isLiveWindow = localKickoff != null &&
      now.isAfter(localKickoff.subtract(const Duration(minutes: 30))) &&
      now.isBefore(localKickoff.add(const Duration(hours: 3, minutes: 30)));

  if (isLiveWindow) {
    return const _FixtureStatusInfo(
      label: 'Live',
      color: AppColors.live,
      textColor: Color(0xFFFECACA),
      background: Color(0x2EE63946),
      border: Color(0x66FF4655),
    );
  }

  return const _FixtureStatusInfo(
    label: 'A venir',
    color: Color(0xFFFBBF24),
    textColor: Color(0xFFFDE68A),
    background: Color(0x24FBBF24),
    border: Color(0x66FBBF24),
  );
}
