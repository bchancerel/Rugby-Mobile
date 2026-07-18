import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/matches/data/matches_repository.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_tracking.dart';

part 'matches/date_controls.dart';
part 'matches/match_groups.dart';
part 'matches/state_widgets.dart';
part 'matches/helpers.dart';

enum _MatchFilter { all, live, upcoming, finished }

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _repository = MatchesRepository();
  final _dates = _buildDateRange(DateTime.now());

  DateTime _selectedDate = _dateOnly(DateTime.now());
  _MatchFilter _selectedFilter = _MatchFilter.all;
  List<RugbyFixture> _fixtures = const [];
  String _errorMessage = '';
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadFixtures();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadFixtures({bool fromRefresh = false}) async {
    final requestedDate = _selectedDate;

    setState(() {
      if (fromRefresh && _fixtures.isNotEmpty) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final fixtures = await _repository.fetchFixturesForDate(requestedDate);

      if (!mounted || !_isSameDay(requestedDate, _selectedDate)) {
        return;
      }

      setState(() {
        _fixtures = fixtures;
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
        _errorMessage = 'Impossible de charger les matchs.';
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

  void _selectDate(DateTime date) {
    final selected = _dateOnly(date);
    if (_isSameDay(selected, _selectedDate)) {
      return;
    }

    setState(() {
      _selectedDate = selected;
      _fixtures = const [];
    });
    _loadFixtures();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFixtures = _filterFixtures(_fixtures, _selectedFilter);
    final groupedFixtures = _groupFixturesByLeague(filteredFixtures);

    return AppNavScaffold(
      currentRoute: AppRoutes.matches,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadFixtures(fromRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    76,
                    AppSpacing.md,
                  ),
                  child: _MatchesHeader(
                    selectedDate: _selectedDate,
                    fixturesCount: filteredFixtures.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _DateStrip(
                  dates: _dates,
                  selectedDate: _selectedDate,
                  onSelected: _selectDate,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: _MatchFilterTabs(
                    fixtures: _fixtures,
                    selectedFilter: _selectedFilter,
                    onSelected: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
              ),
              if (_refreshing)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _MatchesRefreshStatus(),
                  ),
                ),
              if (_loading && _fixtures.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MatchesLoadingState(),
                )
              else if (_errorMessage.isNotEmpty && _fixtures.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MatchesErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadFixtures(),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_errorMessage.isNotEmpty)
                        _MatchesInlineAlert(message: _errorMessage),
                      if (filteredFixtures.isEmpty)
                        _MatchesEmptyState(
                          selectedDate: _selectedDate,
                          selectedFilter: _selectedFilter,
                          onClearFilter: () {
                            setState(() {
                              _selectedFilter = _MatchFilter.all;
                            });
                          },
                        )
                      else
                        for (final group in groupedFixtures) ...[
                          _LeagueMatchGroup(group: group),
                          const SizedBox(height: AppSpacing.md),
                        ],
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
