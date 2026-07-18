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

part 'team_detail/context_details.dart';
part 'team_detail/statistics_section.dart';
part 'team_detail/fixtures_section.dart';
part 'team_detail/layout_widgets.dart';
part 'team_detail/state_widgets.dart';

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

      final selectedContext =
          _findInitialContext(contexts) ??
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
                sliver: SliverToBoxAdapter(child: _buildBody()),
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
      ]..sort((a, b) => (b.league.season ?? 0).compareTo(a.league.season ?? 0));
    }

    return groups.values
        .where((contexts) => contexts.isNotEmpty)
        .map((contexts) => _TeamLeagueContextGroup(contexts: contexts))
        .toList()
      ..sort((a, b) => a.league.displayName.compareTo(b.league.displayName));
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
    final contexts =
        _contexts.where((context) => context.league.id == leagueId).toList()
          ..sort(
            (a, b) => (b.league.season ?? 0).compareTo(a.league.season ?? 0),
          );

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
    final limitReached =
        existingFavorite == null &&
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
        _detailErrorMessage = existingFavorite == null
            ? 'Favori ajoute.'
            : 'Favori retire.';
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
