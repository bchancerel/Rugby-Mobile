import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_inline_alert.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/core/widgets/app_refresh_status.dart';
import 'package:rugby_jam_mobile/core/widgets/app_skeleton_block.dart';
import 'package:rugby_jam_mobile/core/widgets/app_state_panel.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/favorites/data/favorites_models.dart';
import 'package:rugby_jam_mobile/features/favorites/data/favorites_repository.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_repository.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_tracking.dart';

part 'league_detail/overview_widgets.dart';
part 'league_detail/standings_section.dart';
part 'league_detail/matches_section.dart';
part 'league_detail/bracket_section.dart';
part 'league_detail/state_widgets.dart';
part 'league_detail/fixture_rounds.dart';

String? _teamDetailRoute({
  required int? teamId,
  required int? leagueId,
  required int? season,
}) {
  if (teamId == null) {
    return null;
  }

  if (leagueId == null || season == null) {
    return '${AppRoutes.teams}/$teamId';
  }

  return '${AppRoutes.teams}/$teamId?league=$leagueId&season=$season';
}

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
  final _favoritesRepository = FavoritesRepository();

  RugbyLeagueOverview? _overview;
  FavoriteCollection _competitionFavorites = const FavoriteCollection.empty();
  String _errorMessage = '';
  int? _selectedSeason;
  _LeagueDetailTab _selectedTab = _LeagueDetailTab.standings;
  bool _loading = true;
  bool _refreshing = false;
  bool _favoritePending = false;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.initialSeason;
    SupporterTracking.trackCompetitionViewed(widget.leagueId);
    _loadOverview();
  }

  @override
  void dispose() {
    _repository.close();
    _favoritesRepository.close();
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
      final favoritesFuture = _loadCompetitionFavoritesSafely();
      final overview = await _repository.fetchLeagueOverview(
        widget.leagueId,
        season: _selectedSeason,
      );
      final favoritesResult = await favoritesFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _overview = overview;
        if (favoritesResult.favorites != null) {
          _competitionFavorites = favoritesResult.favorites!.competitions;
        }
        _errorMessage = favoritesResult.errorMessage;
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
                    child: AppRefreshStatus(),
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
                          AppInlineAlert(message: _errorMessage),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _LeagueHero(
                          overview: overview,
                          favorite: _findCompetitionFavorite(overview.league),
                          favoriteLimit: _competitionFavorites.limit,
                          favoriteCount: _competitionFavorites.total,
                          favoritePending: _favoritePending,
                          onToggleFavorite: () => _toggleCompetitionFavorite(
                            overview.league,
                          ),
                        ),
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

  Favorite? _findCompetitionFavorite(RugbyLeague league) {
    final id = league.id;
    if (id == null) {
      return null;
    }

    final entityId = id.toString();
    for (final favorite in _competitionFavorites.data) {
      if (favorite.entityId == entityId) {
        return favorite;
      }
    }

    return null;
  }

  Future<void> _toggleCompetitionFavorite(RugbyLeague league) async {
    final id = league.id;
    if (id == null || _favoritePending) {
      return;
    }

    final existingFavorite = _findCompetitionFavorite(league);
    final limitReached = existingFavorite == null &&
        _competitionFavorites.total >= _competitionFavorites.limit;

    if (limitReached) {
      _showSnackBar(
        'Limite de ${_competitionFavorites.limit} favoris atteinte.',
      );
      return;
    }

    setState(() {
      _favoritePending = true;
      _errorMessage = '';
    });

    try {
      if (existingFavorite == null) {
        await _favoritesRepository.addCompetitionFavorite(
          leagueId: id,
          leagueName: league.displayName,
        );
      } else {
        await _favoritesRepository.removeFavorite(existingFavorite.id);
      }

      final favorites = await _favoritesRepository.fetchFavorites();

      if (!mounted) {
        return;
      }

      setState(() {
        _competitionFavorites = favorites.competitions;
      });
      _showSnackBar(
        existingFavorite == null ? 'Favori ajoute.' : 'Favori retire.',
      );
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
      });
      _showSnackBar(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      const message = 'Impossible de mettre a jour ce favori.';
      setState(() {
        _errorMessage = message;
      });
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() {
          _favoritePending = false;
        });
      }
    }
  }

  Future<_CompetitionFavoritesLoadResult> _loadCompetitionFavoritesSafely()
      async {
    try {
      final favorites = await _favoritesRepository.fetchFavorites();
      return _CompetitionFavoritesLoadResult(favorites: favorites);
    } on AuthApiException catch (error) {
      return _CompetitionFavoritesLoadResult(errorMessage: error.message);
    } catch (_) {
      return const _CompetitionFavoritesLoadResult(
        errorMessage: 'Impossible de charger les favoris.',
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}

class _CompetitionFavoritesLoadResult {
  const _CompetitionFavoritesLoadResult({
    this.favorites,
    this.errorMessage = '',
  });

  final FavoritesResponse? favorites;
  final String errorMessage;
}
