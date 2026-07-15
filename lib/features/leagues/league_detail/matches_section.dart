part of '../league_detail_screen.dart';

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
          .map(rugbyFixtureKickoffTime)
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
          ? () {
              SupporterTracking.trackFixtureOpened(fixture);
              Navigator.of(context).pushNamed(
                '${AppRoutes.matches}/${fixture.id}',
              );
            }
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
                      formatRugbyKickoff(fixture.date),
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
                      team: fixture.teams.home,
                      routeName: _teamDetailRoute(
                        teamId: fixture.teams.home.id,
                        leagueId: fixture.league.id,
                        season: fixture.league.season,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      formatRugbyScore(fixture.score),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  Expanded(
                    child: _FixtureTeamColumn(
                      team: fixture.teams.away,
                      routeName: _teamDetailRoute(
                        teamId: fixture.teams.away.id,
                        leagueId: fixture.league.id,
                        season: fixture.league.season,
                      ),
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
    required this.team,
    required this.routeName,
    this.alignEnd = false,
  });

  final RugbyFixtureTeam team;
  final String? routeName;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _TeamLogo(url: team.logo),
        const SizedBox(height: AppSpacing.xs),
        Text(
          team.name ?? (alignEnd ? 'Exterieur' : 'Domicile'),
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

