import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/matches/data/match_odds_models.dart';
import 'package:rugby_jam_mobile/features/matches/data/matches_repository.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_tracking.dart';

part 'match_detail/helpers.dart';
part 'match_detail/info_sections.dart';
part 'match_detail/odds_panel.dart';
part 'match_detail/scoreboard.dart';
part 'match_detail/state_widgets.dart';

class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({required this.matchId, super.key});

  final int matchId;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  static const _liveRefreshInterval = Duration(seconds: 15);

  final _repository = MatchesRepository();

  RugbyFixture? _fixture;
  RugbyMatchOdds? _odds;
  Timer? _liveRefreshTimer;
  Timer? _scoreCelebrationTimer;
  DateTime? _liveLastUpdatedAt;
  Set<String> _scoringSides = const {};
  String _errorMessage = '';
  String _oddsErrorMessage = '';
  bool _loading = true;
  bool _refreshing = false;
  bool _oddsLoading = false;
  bool _liveRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadFixture(probeAfterFetch: true);
  }

  @override
  void dispose() {
    _stopLiveRefresh();
    _stopScoreCelebration();
    _repository.close();
    super.dispose();
  }

  Future<void> _loadFixture({
    bool liveRefresh = false,
    bool showPending = true,
    bool probeAfterFetch = false,
  }) async {
    if (showPending) {
      setState(() {
        if (_fixture == null) {
          _loading = true;
        } else {
          _refreshing = true;
        }
        _errorMessage = '';
      });
    }

    try {
      final previousFixture = _fixture;
      final fixture = await _repository.fetchFixtureById(
        widget.matchId,
        live: liveRefresh,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fixture = fixture;
        if (liveRefresh || rugbyFixtureStatus(fixture).isLive) {
          _liveLastUpdatedAt = DateTime.now();
        }
        _errorMessage = '';
      });
      SupporterTracking.trackFixtureOpened(fixture);

      if (liveRefresh) {
        _detectScoreCelebration(previousFixture, fixture);
      }

      if (probeAfterFetch || liveRefresh) {
        _syncLiveRefresh(fixture);
      }

      if (_shouldShowFixtureOdds(fixture) && _odds == null) {
        _loadFixtureOdds(showPending: !liveRefresh);
      }
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_fixture == null || showPending) {
          _errorMessage = error.message;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_fixture == null || showPending) {
          _errorMessage = 'Impossible de charger ce match.';
        }
      });
    } finally {
      if (mounted && showPending) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
      }
    }
  }

  Future<void> _loadFixtureOdds({bool showPending = true}) async {
    if (_oddsLoading) {
      return;
    }

    if (showPending) {
      setState(() {
        _oddsLoading = true;
        _oddsErrorMessage = '';
      });
    } else {
      _oddsLoading = true;
      _oddsErrorMessage = '';
    }

    try {
      final odds = await _repository.fetchFixtureOdds(widget.matchId);

      if (!mounted) {
        return;
      }

      setState(() {
        _odds = odds;
        _oddsErrorMessage = '';
      });
    } on AuthApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _odds = null;
        _oddsErrorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _odds = null;
        _oddsErrorMessage = 'Impossible de charger les cotes.';
      });
    } finally {
      _oddsLoading = false;
      if (mounted && showPending) {
        setState(() {});
      }
    }
  }

  Future<void> _refreshLiveFixture() async {
    if (_liveRefreshInFlight) {
      return;
    }

    _liveRefreshInFlight = true;
    try {
      await _loadFixture(liveRefresh: true, showPending: false);
    } finally {
      _liveRefreshInFlight = false;
    }
  }

  void _syncLiveRefresh(RugbyFixture fixture) {
    if (_shouldAutoRefreshFixture(fixture)) {
      _startLiveRefresh();
      return;
    }

    _stopLiveRefresh();
    if (mounted) {
      setState(() {
        _liveLastUpdatedAt = null;
      });
    }
  }

  void _startLiveRefresh() {
    if (_liveRefreshTimer != null) {
      return;
    }

    _refreshLiveFixture();
    _liveRefreshTimer = Timer.periodic(
      _liveRefreshInterval,
      (_) => _refreshLiveFixture(),
    );
  }

  void _stopLiveRefresh() {
    _liveRefreshTimer?.cancel();
    _liveRefreshTimer = null;
  }

  void _detectScoreCelebration(
    RugbyFixture? previousFixture,
    RugbyFixture nextFixture,
  ) {
    if (previousFixture == null) {
      return;
    }

    final nextScoringSides = <String>{};
    final previousHome = previousFixture.score.home;
    final nextHome = nextFixture.score.home;
    final previousAway = previousFixture.score.away;
    final nextAway = nextFixture.score.away;

    if (previousHome != null && nextHome != null && nextHome > previousHome) {
      nextScoringSides.add('home');
    }

    if (previousAway != null && nextAway != null && nextAway > previousAway) {
      nextScoringSides.add('away');
    }

    if (nextScoringSides.isEmpty || !mounted) {
      return;
    }

    _stopScoreCelebration();
    setState(() {
      _scoringSides = nextScoringSides;
    });
    _scoreCelebrationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _scoringSides = const {};
      });
      _scoreCelebrationTimer = null;
    });
  }

  void _stopScoreCelebration() {
    _scoreCelebrationTimer?.cancel();
    _scoreCelebrationTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final fixture = _fixture;

    return AppNavScaffold(
      currentRoute: AppRoutes.matches,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadFixture(probeAfterFetch: true),
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
                  child: _MatchDetailBackButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.matches),
                  ),
                ),
              ),
              if (_refreshing && fixture != null)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: _MatchDetailRefreshStatus(),
                  ),
                ),
              if (_loading && fixture == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MatchDetailLoadingState(),
                )
              else if (_errorMessage.isNotEmpty && fixture == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _MatchDetailErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadFixture(probeAfterFetch: true),
                  ),
                )
              else if (fixture != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_errorMessage.isNotEmpty)
                        _MatchDetailInlineAlert(message: _errorMessage),
                      _MatchScoreboard(
                        fixture: fixture,
                        liveLastUpdatedAt: _liveLastUpdatedAt,
                        scoringSides: _scoringSides,
                      ),
                      if (_shouldShowFixtureOdds(fixture)) ...[
                        const SizedBox(height: AppSpacing.md),
                        _MatchOddsPanel(
                          fixture: fixture,
                          odds: _odds,
                          loading: _oddsLoading,
                          errorMessage: _oddsErrorMessage,
                          onRetry: _loadFixtureOdds,
                        ),
                      ],
                      if (_hasFixtureScore(fixture)) ...[
                        const SizedBox(height: AppSpacing.md),
                        _MatchScoreBreakdown(fixture: fixture),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _MatchInfoSection(fixture: fixture),
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
