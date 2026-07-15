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
import 'package:rugby_jam_mobile/features/leagues/data/leagues_models.dart';
import 'package:rugby_jam_mobile/features/leagues/data/leagues_repository.dart';

part 'leagues/summary_sections.dart';
part 'leagues/filters.dart';
part 'leagues/catalog_sections.dart';
part 'leagues/state_widgets.dart';

class LeaguesScreen extends StatefulWidget {
  const LeaguesScreen({super.key});

  @override
  State<LeaguesScreen> createState() => _LeaguesScreenState();
}

class _LeaguesScreenState extends State<LeaguesScreen> {
  final _repository = LeaguesRepository();
  final _searchController = TextEditingController();

  List<RugbyLeague> _leagues = const [];
  String _errorMessage = '';
  String _selectedCountry = '';
  String _selectedType = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _currentSeasonOnly = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadLeagues();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _repository.close();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _loadLeagues({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _leagues.isNotEmpty) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final leagues = await _repository.fetchLeagues();

      if (!mounted) {
        return;
      }

      setState(() {
        _leagues = leagues;
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
        _errorMessage = 'Impossible de charger les competitions.';
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

  @override
  Widget build(BuildContext context) {
    final hasLeagues = _leagues.isNotEmpty;
    final countryOptions = findLeagueCountryOptions(_leagues);
    final typeOptions = findLeagueTypeOptions(_leagues);
    final selectedCountry =
        countryOptions.contains(_selectedCountry) ? _selectedCountry : '';
    final selectedType = typeOptions.contains(_selectedType) ? _selectedType : '';
    final filteredLeagues = filterLeagues(
      leagues: _leagues,
      query: _searchController.text,
      country: selectedCountry,
      type: selectedType,
      currentSeasonOnly: _currentSeasonOnly,
    );
    final majorLeagues = findMajorLeagues(_leagues);
    final countryGroups = groupLeaguesByCountry(filteredLeagues);

    return AppNavScaffold(
      currentRoute: AppRoutes.leagues,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadLeagues(fromRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _LeaguesHeader(),
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
                      message: 'Actualisation des competitions...',
                      showSpinner: true,
                      decorated: true,
                      textColor: null,
                      fontWeight: null,
                    ),
                  ),
                ),
              if (_loading && !hasLeagues)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(child: _LeaguesLoadingState()),
                )
              else if (_errorMessage.isNotEmpty && !hasLeagues)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LeaguesErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadLeagues(),
                  ),
                )
              else if (!hasLeagues)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LeaguesEmptyState(onRetry: () => _loadLeagues()),
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
                          AppInlineAlert(
                            message: _errorMessage,
                            backgroundColor: Color(0x1AFBBF24),
                            borderColor: Color(0x4DFBBF24),
                            borderRadius: 8,
                            textColor: AppColors.white,
                            fontWeight: FontWeight.w400,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _AnimatedLeagueSection(
                          index: 0,
                          child: _MajorLeaguesSection(leagues: majorLeagues),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AnimatedLeagueSection(
                          index: 1,
                          child: _LeaguesSummary(
                            totalLeagues: _leagues.length,
                            filteredCount: filteredLeagues.length,
                            countryCount: countryOptions.length,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _AnimatedLeagueSection(
                          index: 2,
                          child: _LeaguesFilters(
                            searchController: _searchController,
                            countryOptions: countryOptions,
                            typeOptions: typeOptions,
                            selectedCountry: selectedCountry,
                            selectedType: selectedType,
                            currentSeasonOnly: _currentSeasonOnly,
                            onCountryChanged: (value) {
                              setState(() {
                                _selectedCountry = value ?? '';
                              });
                            },
                            onTypeChanged: (value) {
                              setState(() {
                                _selectedType = value ?? '';
                              });
                            },
                            onCurrentSeasonChanged: (value) {
                              setState(() {
                                _currentSeasonOnly = value;
                              });
                            },
                            onReset: _resetFilters,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (filteredLeagues.isEmpty)
                          _AnimatedLeagueSection(
                            index: 3,
                            child: _NoFilteredLeagues(onReset: _resetFilters),
                          )
                        else
                          _AnimatedLeagueSection(
                            index: 3,
                            child: _CountryCatalogSection(
                              groups: countryGroups,
                            ),
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

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedCountry = '';
      _selectedType = '';
      _currentSeasonOnly = false;
    });
  }
}

