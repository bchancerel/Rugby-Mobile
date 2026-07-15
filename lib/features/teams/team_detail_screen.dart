import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_inline_alert.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/core/widgets/app_refresh_status.dart';
import 'package:rugby_jam_mobile/core/widgets/app_skeleton_block.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/favorites/data/favorites_models.dart';
import 'package:rugby_jam_mobile/features/favorites/data/favorites_repository.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_tracking.dart';
import 'package:rugby_jam_mobile/features/teams/data/teams_models.dart';
import 'package:rugby_jam_mobile/features/teams/data/teams_repository.dart';

String _formatNullableInt(int? value) => value?.toString() ?? '-';

String _formatSignedInt(int? value) {
  if (value == null) {
    return '-';
  }

  if (value > 0) {
    return '+$value';
  }

  return value.toString();
}

String _formatWinRate(RugbyTeamStatisticsRecord record) {
  final winRate = record.winRate;
  return winRate == null ? '-' : '$winRate%';
}

bool _hasAnyStatistic(RugbyTeamStatisticsRecord record) {
  return record.played != null ||
      record.win != null ||
      record.draw != null ||
      record.loss != null ||
      record.pointsFor != null ||
      record.pointsAgainst != null;
}

String? _teamRouteForFixture(RugbyFixture fixture, RugbyFixtureTeam team) {
  final teamId = team.id;
  if (teamId == null) {
    return null;
  }

  final leagueId = fixture.league.id;
  final season = fixture.league.season;
  if (leagueId == null || season == null) {
    return '${AppRoutes.teams}/$teamId';
  }

  return '${AppRoutes.teams}/$teamId?league=$leagueId&season=$season';
}

String _fixtureRoundLabel(RugbyFixture fixture) {
  final round = fixture.league.round;
  if (round == null || round.isEmpty) {
    return 'Match';
  }

  return 'Journee $round';
}

class TeamDetailScreen extends StatefulWidget {
  const TeamDetailScreen({
    required this.teamId,
    this.initialLeagueId,
    this.initialSeason,
    super.key,
  });

  final int teamId;
  final int? initialLeagueId;
  final int? initialSeason;

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _repository = TeamsRepository();
  final _favoritesRepository = FavoritesRepository();

  List<RugbyTeamContext> _contexts = const [];
  FavoriteCollection _teamFavorites = const FavoriteCollection.empty();
  RugbyTeamContext? _selectedContext;
  RugbyTeamStatistics? _statistics;
  List<RugbyFixture> _fixtures = const [];
  String _errorMessage = '';
  String _detailErrorMessage = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _detailLoading = false;
  bool _favoritePending = false;
  String? _loadedContextKey;

  @override
  void initState() {
    super.initState();
    SupporterTracking.trackTeamViewed(widget.teamId);
    _loadContexts();
  }

  @override
  void dispose() {
    _repository.close();
    _favoritesRepository.close();
    super.dispose();
  }

  Future<void> _loadContexts({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _contexts.isNotEmpty) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final favoritesFuture = _loadTeamFavoritesSafely();
      final contexts = await _repository.fetchTeamContexts(widget.teamId);
      final favoritesResult = await favoritesFuture;

      final selectedContext = _findInitialContext(contexts) ??
          (contexts.isEmpty ? null : contexts.first);

      if (!mounted) {
        return;
      }

      setState(() {
        _contexts = contexts;
        if (favoritesResult.favorites != null) {
          _teamFavorites = favoritesResult.favorites!.teams;
        }
        _selectedContext = selectedContext;
        _statistics = null;
        _fixtures = const [];
        _errorMessage = favoritesResult.errorMessage;
        _detailErrorMessage = '';
        _loadedContextKey = null;
      });

      if (selectedContext != null) {
        _loadContextDetails(selectedContext);
      }
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
        _errorMessage = 'Impossible de charger cette equipe.';
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

  Future<_TeamFavoritesLoadResult> _loadTeamFavoritesSafely() async {
    try {
      final favorites = await _favoritesRepository.fetchFavorites();
      return _TeamFavoritesLoadResult(favorites: favorites);
    } on AuthApiException catch (error) {
      return _TeamFavoritesLoadResult(errorMessage: error.message);
    } catch (_) {
      return const _TeamFavoritesLoadResult(
        errorMessage: 'Impossible de charger les favoris.',
      );
    }
  }

  RugbyTeamContext? _findInitialContext(List<RugbyTeamContext> contexts) {
    final initialLeagueId = widget.initialLeagueId;
    final initialSeason = widget.initialSeason;

    if (initialLeagueId == null || initialSeason == null) {
      return null;
    }

    for (final context in contexts) {
      if (context.league.id == initialLeagueId &&
          context.league.season == initialSeason) {
        return context;
      }
    }

    return null;
  }

  Future<void> _loadContextDetails(RugbyTeamContext context) async {
    final leagueId = context.league.id;
    final season = context.league.season;
    if (leagueId == null || season == null) {
      return;
    }

    final contextKey = context.key;
    setState(() {
      _detailLoading = true;
      _detailErrorMessage = '';
      _loadedContextKey = contextKey;
    });

    try {
      final results = await Future.wait<Object>([
        _repository.fetchTeamStatistics(
          widget.teamId,
          leagueId: leagueId,
          season: season,
        ),
        _repository.fetchTeamFixtures(
          widget.teamId,
          leagueId: leagueId,
          season: season,
        ),
      ]);
      final statistics = results[0] as RugbyTeamStatistics;
      final fixtures = results[1] as List<RugbyFixture>;

      if (!mounted || _loadedContextKey != contextKey) {
        return;
      }

      setState(() {
        _statistics = statistics;
        _fixtures = fixtures;
      });
    } on AuthApiException catch (error) {
      if (!mounted || _loadedContextKey != contextKey) {
        return;
      }

      setState(() {
        _detailErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted || _loadedContextKey != contextKey) {
        return;
      }

      setState(() {
        _detailErrorMessage = 'Impossible de charger les details equipe.';
      });
    } finally {
      if (mounted && _loadedContextKey == contextKey) {
        setState(() {
          _detailLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeName = '${AppRoutes.teams}/${widget.teamId}';

    return AppNavScaffold(
      currentRoute: routeName,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadContexts(fromRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xxl,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: const _TeamDetailHeader(),
                ),
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
                    child: AppRefreshStatus(
                      message: 'Actualisation de l equipe...',
                      showSpinner: true,
                      decorated: true,
                      textColor: null,
                      fontWeight: null,
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  132,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const _TeamDetailLoadingState();
    }

    if (_errorMessage.isNotEmpty && _contexts.isEmpty) {
      return _TeamDetailErrorState(
        message: _errorMessage,
        onRetry: _loadContexts,
      );
    }

    if (_contexts.isEmpty) {
      return _TeamDetailEmptyState(onRetry: _loadContexts);
    }

    final selectedContext = _selectedContext ?? _contexts.first;
    final leagueGroups = _buildLeagueGroups(_contexts);
    final selectedLeagueGroup = _findSelectedLeagueGroup(
      leagueGroups,
      selectedContext,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_errorMessage.isNotEmpty) ...[
          AppInlineAlert(message: _errorMessage),
          const SizedBox(height: AppSpacing.md),
        ],
        _TeamContextSelector(
          groups: leagueGroups,
          selectedContext: selectedContext,
          selectedLeagueGroup: selectedLeagueGroup,
          onLeagueSelected: _selectLeague,
          onSeasonSelected: _selectSeason,
        ),
        const SizedBox(height: AppSpacing.md),
        _TeamHero(
          context: selectedContext,
          favorite: _findTeamFavorite(selectedContext),
          favoriteLimit: _teamFavorites.limit,
          favoriteCount: _teamFavorites.total,
          favoritePending: _favoritePending,
          onToggleFavorite: () => _toggleTeamFavorite(selectedContext),
        ),
        const SizedBox(height: AppSpacing.md),
        _TeamContextDetails(
          loading: _detailLoading,
          errorMessage: _detailErrorMessage,
          statistics: _statistics,
          fixtures: _fixtures,
          onRetry: () => _loadContextDetails(selectedContext),
        ),
      ],
    );
  }

  List<_TeamLeagueContextGroup> _buildLeagueGroups(
    List<RugbyTeamContext> contexts,
  ) {
    final groups = <int, List<RugbyTeamContext>>{};

    for (final context in contexts) {
      final leagueId = context.league.id;
      if (leagueId == null) {
        continue;
      }

      final currentContexts = groups[leagueId] ?? const <RugbyTeamContext>[];
      groups[leagueId] = [
        ...currentContexts,
        context,
      ]
        ..sort(
          (a, b) => (b.league.season ?? 0).compareTo(a.league.season ?? 0),
        );
    }

    return groups.values
        .where((contexts) => contexts.isNotEmpty)
        .map((contexts) => _TeamLeagueContextGroup(contexts: contexts))
        .toList()
      ..sort(
        (a, b) => a.league.displayName.compareTo(b.league.displayName),
      );
  }

  _TeamLeagueContextGroup? _findSelectedLeagueGroup(
    List<_TeamLeagueContextGroup> groups,
    RugbyTeamContext selectedContext,
  ) {
    for (final group in groups) {
      if (group.league.id == selectedContext.league.id) {
        return group;
      }
    }

    return null;
  }

  void _selectLeague(int leagueId) {
    final contexts = _contexts
        .where((context) => context.league.id == leagueId)
        .toList()
      ..sort((a, b) => (b.league.season ?? 0).compareTo(a.league.season ?? 0));

    if (contexts.isEmpty) {
      return;
    }

    _selectContext(contexts.first);
  }

  void _selectSeason(int season) {
    final selectedContext = _selectedContext;
    if (selectedContext == null) {
      return;
    }

    for (final context in _contexts) {
      if (context.league.id == selectedContext.league.id &&
          context.league.season == season) {
        _selectContext(context);
        return;
      }
    }
  }

  void _selectContext(RugbyTeamContext nextContext) {
    setState(() {
      _selectedContext = nextContext;
      _statistics = null;
      _fixtures = const [];
    });

    final leagueId = nextContext.league.id;
    final season = nextContext.league.season;
    if (leagueId == null || season == null) {
      _loadContextDetails(nextContext);
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      '${AppRoutes.teams}/${widget.teamId}?league=$leagueId&season=$season',
    );
  }

  Favorite? _findTeamFavorite(RugbyTeamContext context) {
    final teamId = context.team.id ?? widget.teamId;
    final entityId = teamId.toString();

    for (final favorite in _teamFavorites.data) {
      if (favorite.entityId == entityId) {
        return favorite;
      }
    }

    return null;
  }

  Future<void> _toggleTeamFavorite(RugbyTeamContext context) async {
    final teamId = context.team.id ?? widget.teamId;
    if (_favoritePending) {
      return;
    }

    final existingFavorite = _findTeamFavorite(context);
    final limitReached = existingFavorite == null &&
        _teamFavorites.total >= _teamFavorites.limit;

    if (limitReached) {
      setState(() {
        _detailErrorMessage =
            'Limite de ${_teamFavorites.limit} equipes favorites atteinte.';
      });
      return;
    }

    setState(() {
      _favoritePending = true;
      _detailErrorMessage = '';
    });

    try {
      if (existingFavorite == null) {
        await _favoritesRepository.addTeamFavorite(
          teamId: teamId,
          teamName: context.team.displayName,
        );
      } else {
        await _favoritesRepository.removeFavorite(existingFavorite.id);
      }

      final favorites = await _favoritesRepository.fetchFavorites();

      if (!mounted) {
        return;
      }

      setState(() {
        _teamFavorites = favorites.teams;
        _detailErrorMessage =
            existingFavorite == null ? 'Favori ajoute.' : 'Favori retire.';
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detailErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _detailErrorMessage = 'Impossible de mettre a jour ce favori.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _favoritePending = false;
        });
      }
    }
  }
}

class _TeamFavoritesLoadResult {
  const _TeamFavoritesLoadResult({
    this.favorites,
    this.errorMessage = '',
  });

  final FavoritesResponse? favorites;
  final String errorMessage;
}

class _TeamContextDetails extends StatelessWidget {
  const _TeamContextDetails({
    required this.loading,
    required this.errorMessage,
    required this.statistics,
    required this.fixtures,
    required this.onRetry,
  });

  final bool loading;
  final String errorMessage;
  final RugbyTeamStatistics? statistics;
  final List<RugbyFixture> fixtures;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Column(
        children: [
          AppSkeletonBlock(height: 180),
          SizedBox(height: AppSpacing.md),
          AppSkeletonBlock(height: 220),
        ],
      );
    }

    if (errorMessage.isNotEmpty) {
      return Column(
        children: [
          AppInlineAlert(message: errorMessage),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Reessayer',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TeamStatisticsSection(statistics: statistics),
        const SizedBox(height: AppSpacing.md),
        _TeamFixturesSection(fixtures: fixtures),
      ],
    );
  }
}

class _TeamStatisticsSection extends StatelessWidget {
  const _TeamStatisticsSection({required this.statistics});

  final RugbyTeamStatistics? statistics;

  @override
  Widget build(BuildContext context) {
    final data = statistics;
    final record = data?.all;

    return _TeamPanel(
      title: 'Statistiques',
      icon: Icons.bar_chart,
      child: record == null
          ? const _TeamPanelMessage(
              icon: Icons.insights,
              title: 'Statistiques indisponibles',
              message: 'Aucune statistique trouvee pour ce contexte.',
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Matchs',
                        value: _formatNullableInt(record.played),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Victoires',
                        value: _formatNullableInt(record.win),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Taux victoire',
                        value: _formatWinRate(record),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _TeamStatTile(
                        label: 'Diff points',
                        value: _formatSignedInt(record.pointsDiff),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _TeamPerformanceTable(statistics: data!),
              ],
            ),
    );
  }
}

class _TeamPerformanceTable extends StatelessWidget {
  const _TeamPerformanceTable({required this.statistics});

  final RugbyTeamStatistics statistics;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyStatistic(statistics.all)) {
      return const _TeamPanelMessage(
        icon: Icons.table_chart,
        title: 'Performance indisponible',
        message: 'Les statistiques detaillees ne sont pas encore disponibles.',
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
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
                    'Performance',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (statistics.form != null)
                  Text(
                    'Forme: ${statistics.form}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.grayCool,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _TeamPerformanceHeader(),
            _TeamPerformanceRow(label: 'Total', record: statistics.all),
            _TeamPerformanceRow(label: 'Domicile', record: statistics.home),
            _TeamPerformanceRow(label: 'Exterieur', record: statistics.away),
          ],
        ),
      ),
    );
  }
}

class _TeamPerformanceHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _TeamPerformanceGrid(
      cells: [
        _TeamPerformanceCell(
          text: 'Zone',
          color: AppColors.grayCool,
          fontWeight: FontWeight.w900,
        ),
        for (final label in const ['J', 'G', 'N', 'P', '+', '-', 'Diff'])
          _TeamPerformanceCell(
            text: label,
            color: AppColors.grayCool,
            fontWeight: FontWeight.w900,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _TeamPerformanceRow extends StatelessWidget {
  const _TeamPerformanceRow({
    required this.label,
    required this.record,
  });

  final String label;
  final RugbyTeamStatisticsRecord record;

  @override
  Widget build(BuildContext context) {
    return _TeamPerformanceGrid(
      cells: [
        _TeamPerformanceCell(text: label),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.played),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.win),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.draw),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.loss),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.pointsFor),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatNullableInt(record.pointsAgainst),
          textAlign: TextAlign.center,
        ),
        _TeamPerformanceCell(
          text: _formatSignedInt(record.pointsDiff),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TeamPerformanceGrid extends StatelessWidget {
  const _TeamPerformanceGrid({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(flex: 2, child: cells[0]),
          for (final cell in cells.skip(1))
            Expanded(
              child: cell,
            ),
        ],
      ),
    );
  }
}

class _TeamPerformanceCell extends StatelessWidget {
  const _TeamPerformanceCell({
    required this.text,
    this.color = AppColors.white,
    this.fontWeight = FontWeight.w800,
    this.textAlign = TextAlign.left,
  });

  final String text;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: fontWeight,
          ),
    );
  }
}

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
  const _TeamStatTile({
    required this.label,
    required this.value,
  });

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
                            Navigator.of(context).pushNamed(
                              '${AppRoutes.matches}/${fixture.id}',
                            );
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
  const _TeamFixtureScoreButton({
    required this.score,
    required this.onTap,
  });

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
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
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
          ? const Icon(
              Icons.shield_outlined,
              color: AppColors.red,
              size: 22,
            )
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

class _TeamPanelMessage extends StatelessWidget {
  const _TeamPanelMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.redAccent, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grayCool,
                          fontWeight: FontWeight.w700,
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

class _TeamDetailHeader extends StatelessWidget {
  const _TeamDetailHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }

            navigator.pushReplacementNamed(AppRoutes.dashboard);
          },
          icon: const Icon(Icons.arrow_back),
          color: AppColors.white,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xA6020617),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
      ],
    );
  }
}

class _TeamLeagueContextGroup {
  const _TeamLeagueContextGroup({required this.contexts});

  final List<RugbyTeamContext> contexts;

  RugbyTeamLeague get league => contexts.first.league;
}

class _TeamContextSelector extends StatelessWidget {
  const _TeamContextSelector({
    required this.groups,
    required this.selectedContext,
    required this.selectedLeagueGroup,
    required this.onLeagueSelected,
    required this.onSeasonSelected,
  });

  final List<_TeamLeagueContextGroup> groups;
  final RugbyTeamContext selectedContext;
  final _TeamLeagueContextGroup? selectedLeagueGroup;
  final ValueChanged<int> onLeagueSelected;
  final ValueChanged<int> onSeasonSelected;

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
                const Icon(
                  Icons.tune,
                  color: AppColors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Championnat et saison',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _TeamContextDropdown<int>(
              label: 'Championnat',
              value: selectedContext.league.id,
              items: groups
                  .map(
                    (group) => DropdownMenuItem<int>(
                      value: group.league.id!,
                      child: Text(group.league.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (leagueId) {
                if (leagueId != null) {
                  onLeagueSelected(leagueId);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _TeamContextDropdown<int>(
              label: 'Saison',
              value: selectedContext.league.season,
              items: (selectedLeagueGroup?.contexts ??
                      const <RugbyTeamContext>[])
                  .map(
                    (context) => DropdownMenuItem<int>(
                      value: context.league.season!,
                      child: Text(
                        '${context.league.season} - ${context.fixturesCount} matchs',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (season) {
                if (season != null) {
                  onSeasonSelected(season);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamContextDropdown<T> extends StatelessWidget {
  const _TeamContextDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66111827),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.grayCool,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: items.any((item) => item.value == value) ? value : null,
                  isExpanded: true,
                  dropdownColor: AppColors.night,
                  iconEnabledColor: AppColors.white,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                  items: items,
                  onChanged: items.isEmpty ? null : onChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({
    required this.context,
    required this.favorite,
    required this.favoriteLimit,
    required this.favoriteCount,
    required this.favoritePending,
    required this.onToggleFavorite,
  });

  final RugbyTeamContext context;
  final Favorite? favorite;
  final int favoriteLimit;
  final int favoriteCount;
  final bool favoritePending;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext buildContext) {
    final favoriteActive = favorite != null;
    final limitReached = !favoriteActive && favoriteCount >= favoriteLimit;

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
            children: [
              _TeamLogo(url: context.team.logo),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.team.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(buildContext)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontFamily: 'RugbyJamImpact',
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${context.league.displayName} / Saison ${context.league.season}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(buildContext).textTheme.bodyMedium?.copyWith(
                                color: AppColors.grayCool,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (context.league.id != null &&
                            context.league.season != null)
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(buildContext).pushNamed(
                                '${AppRoutes.leagues}/${context.league.id}?season=${context.league.season}',
                              );
                            },
                            icon: const Icon(Icons.emoji_events, size: 18),
                            label: const Text('Voir le championnat'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.white,
                              backgroundColor: const Color(0xA6020617),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              textStyle: Theme.of(buildContext)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                        _TeamFavoriteButton(
                          active: favoriteActive,
                          pending: favoritePending,
                          limitReached: limitReached,
                          onPressed: onToggleFavorite,
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

class _TeamFavoriteButton extends StatelessWidget {
  const _TeamFavoriteButton({
    required this.active,
    required this.pending,
    required this.limitReached,
    required this.onPressed,
  });

  final bool active;
  final bool pending;
  final bool limitReached;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = active
        ? 'Retirer des favoris'
        : limitReached
            ? 'Limite de favoris atteinte'
            : 'Ajouter aux favoris';

    return TextButton.icon(
      onPressed: pending ? null : onPressed,
      icon: pending
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : Icon(active ? Icons.star : Icons.star_border),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: active ? const Color(0xFFFFD166) : AppColors.white,
        disabledForegroundColor: AppColors.grayCool,
        backgroundColor: const Color(0xA6020617),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: const BorderSide(color: AppColors.border),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return SizedBox(
      width: 72,
      height: 72,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: imageUrl == null
            ? const Icon(
                Icons.shield_outlined,
                color: AppColors.red,
                size: 42,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Icon(
                    Icons.shield_outlined,
                    color: AppColors.red,
                    size: 42,
                  );
                },
              ),
      ),
    );
  }
}

class _TeamDetailLoadingState extends StatelessWidget {
  const _TeamDetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppSkeletonBlock(height: 148),
        SizedBox(height: AppSpacing.md),
        AppSkeletonBlock(height: 92),
      ],
    );
  }
}

class _TeamDetailErrorState extends StatelessWidget {
  const _TeamDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppInlineAlert(message: message),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Reessayer',
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _TeamDetailEmptyState extends StatelessWidget {
  const _TeamDetailEmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppInlineAlert(
          message: 'Aucun championnat trouve pour cette equipe.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Actualiser',
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
