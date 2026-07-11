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
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_repository.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';

part 'league_detail/overview_widgets.dart';
part 'league_detail/standings_section.dart';
part 'league_detail/matches_section.dart';
part 'league_detail/bracket_section.dart';
part 'league_detail/state_widgets.dart';
part 'league_detail/fixture_rounds.dart';

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
