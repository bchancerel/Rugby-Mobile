import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rugby_jam_mobile/core/navigation/app_routes.dart';
import 'package:rugby_jam_mobile/core/theme/app_colors.dart';
import 'package:rugby_jam_mobile/core/theme/app_spacing.dart';
import 'package:rugby_jam_mobile/core/widgets/app_button.dart';
import 'package:rugby_jam_mobile/core/widgets/app_nav_scaffold.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_api_client.dart';
import 'package:rugby_jam_mobile/features/auth/data/auth_session_manager.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_models.dart';
import 'package:rugby_jam_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:rugby_jam_mobile/features/favorites/data/favorites_models.dart';
import 'package:rugby_jam_mobile/features/rugby/rugby_fixture_utils.dart';
import 'package:rugby_jam_mobile/features/supporter/data/supporter_tracking.dart';

part 'dashboard/header_summary.dart';
part 'dashboard/favorites_preview.dart';
part 'dashboard/upcoming_matches.dart';
part 'dashboard/interaction_widgets.dart';
part 'dashboard/state_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = DashboardRepository();

  DashboardData? _data;
  String _errorMessage = '';
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadDashboard({bool fromRefresh = false}) async {
    setState(() {
      if (fromRefresh && _data != null) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final data = await _repository.fetchDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        _data = data;
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
        _errorMessage = 'Une erreur est survenue.';
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

  void _openRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return AppNavScaffold(
      currentRoute: AppRoutes.dashboard,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboard(fromRefresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: const _DashboardHeader(),
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
                    child: _RefreshStatus(),
                  ),
                ),
              if (_loading && data == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DashboardLoadingState(),
                )
              else if (_errorMessage.isNotEmpty && data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _DashboardErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadDashboard(),
                  ),
                )
              else if (data != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        if (_errorMessage.isNotEmpty)
                          _InlineAlert(message: _errorMessage),
                        _SummaryRow(data: data),
                        const SizedBox(height: AppSpacing.lg),
                        if (!data.hasFavorites)
                          _EmptyDashboard(onOpenRoute: _openRoute)
                        else ...[
                          _FavoritesPreview(data: data),
                          const SizedBox(height: AppSpacing.lg),
                          _UpcomingMatches(
                            matches: data.teamUpcomingMatches,
                            onOpenRoute: _openRoute,
                          ),
                        ],
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
