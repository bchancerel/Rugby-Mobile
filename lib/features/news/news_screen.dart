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
import 'package:rugby_jam_mobile/features/news/data/news_models.dart';
import 'package:rugby_jam_mobile/features/news/data/news_repository.dart';

part 'news/article_cards.dart';
part 'news/filters.dart';
part 'news/helpers.dart';
part 'news/state_widgets.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  static const _pageSize = 24;
  static const _sourceFilters = [
    _NewsSourceFilter(key: '', label: 'Toutes'),
    _NewsSourceFilter(key: 'rugbyrama', label: 'Rugbyrama'),
    _NewsSourceFilter(key: 'rugbypass', label: 'RugbyPass'),
    _NewsSourceFilter(key: 'planet-rugby', label: 'Planet Rugby'),
  ];

  final _repository = NewsRepository();
  final _imageErrors = <String>{};

  NewsResponse? _news;
  String _selectedSource = '';
  String _errorMessage = '';
  bool _transfersOnly = false;
  bool _loading = false;
  bool _refreshing = false;
  bool _loadingMore = false;

  List<NewsArticle> get _articles => _news?.items ?? const [];
  List<NewsSourceStatus> get _sources => _news?.sources ?? const [];
  NewsArticle? get _leadArticle => _articles.isEmpty ? null : _articles.first;
  List<NewsArticle> get _secondaryArticles =>
      _articles.length <= 1 ? const [] : _articles.skip(1).toList();
  int get _totalArticles => _news?.total ?? _articles.length;
  int get _availableSourcesCount =>
      _sources.where((source) => source.isOk).length;
  List<NewsSourceStatus> get _sourceErrors =>
      _sources.where((source) => !source.isOk).toList();

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  @override
  void dispose() {
    _repository.close();
    super.dispose();
  }

  Future<void> _loadNews({
    bool fromRefresh = false,
    bool append = false,
  }) async {
    if (_loading || _refreshing || _loadingMore) {
      return;
    }

    setState(() {
      if (append) {
        _loadingMore = true;
      } else if (fromRefresh && _articles.isNotEmpty) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _errorMessage = '';
    });

    try {
      final news = await _repository.fetchNews(
        source: _selectedSource.isEmpty ? null : _selectedSource,
        transfersOnly: _transfersOnly,
        limit: _pageSize,
        offset: append ? _articles.length : 0,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _news = append && _news != null
            ? NewsResponse(
                items: _mergeArticles(_news!.items, news.items),
                updatedAt: news.updatedAt,
                sources: news.sources,
                total: news.total,
                limit: news.limit,
                offset: news.offset,
                hasMore: news.hasMore,
              )
            : news;
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
        _errorMessage = 'Actualites indisponibles.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _selectSource(String source) {
    if (_selectedSource == source) {
      return;
    }

    setState(() {
      _selectedSource = source;
      _news = null;
      _imageErrors.clear();
    });
    _loadNews();
  }

  void _toggleTransfersOnly() {
    setState(() {
      _transfersOnly = !_transfersOnly;
      _news = null;
      _imageErrors.clear();
    });
    _loadNews();
  }

  void _markImageBroken(String id) {
    if (!mounted) {
      return;
    }

    setState(() {
      _imageErrors.add(id);
    });
  }

  bool _shouldShowImage(NewsArticle article) {
    return article.imageUrl != null && !_imageErrors.contains(article.id);
  }

  @override
  Widget build(BuildContext context) {
    final hasArticles = _articles.isNotEmpty;

    return AppNavScaffold(
      currentRoute: AppRoutes.actualites,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadNews(fromRefresh: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _NewsHeader(
                  totalArticles: _totalArticles,
                  availableSourcesCount: _availableSourcesCount,
                ),
              ),
              SliverToBoxAdapter(
                child: _NewsFilters(
                  sourceFilters: _sourceFilters,
                  selectedSource: _selectedSource,
                  transfersOnly: _transfersOnly,
                  updatedAt: _news?.updatedAt,
                  onSourceSelected: _selectSource,
                  onTransfersToggle: _toggleTransfersOnly,
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
                      message: 'Actualisation des actualites...',
                      showSpinner: true,
                      decorated: true,
                      textColor: null,
                      fontWeight: null,
                    ),
                  ),
                ),
              if (_loading && !hasArticles)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    132,
                  ),
                  sliver: SliverToBoxAdapter(child: _NewsLoadingState()),
                )
              else if (_errorMessage.isNotEmpty && !hasArticles)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NewsErrorState(
                    message: _errorMessage,
                    onRetry: () => _loadNews(),
                  ),
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
                    delegate: SliverChildListDelegate([
                      if (_errorMessage.isNotEmpty) ...[
                        AppInlineAlert(
                          message:
                              'Les derniers articles charges restent affiches. $_errorMessage',
                          backgroundColor: const Color(0x1AFBBF24),
                          borderColor: const Color(0x4DFBBF24),
                          borderRadius: 8,
                          textColor: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_sources.isNotEmpty) ...[
                        _NewsSourceStatusStrip(sources: _sources),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_sourceErrors.isNotEmpty) ...[
                        AppInlineAlert(
                          message:
                              '${_sourceErrors.length} source${_pluralSuffix(_sourceErrors.length)} indisponible${_pluralSuffix(_sourceErrors.length)}. $_availableSourcesCount source${_pluralSuffix(_availableSourcesCount)} encore disponible${_pluralSuffix(_availableSourcesCount)}.',
                          backgroundColor: const Color(0x1AFBBF24),
                          borderColor: const Color(0x4DFBBF24),
                          borderRadius: 8,
                          textColor: AppColors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (!hasArticles)
                        _NewsEmptyState(
                          transfersOnly: _transfersOnly,
                          onRetry: () => _loadNews(),
                        )
                      else ...[
                        if (_leadArticle != null) ...[
                          _LeadNewsCard(
                            article: _leadArticle!,
                            showImage: _shouldShowImage(_leadArticle!),
                            onImageError: _markImageBroken,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        for (final article in _secondaryArticles) ...[
                          _CompactNewsCard(
                            article: article,
                            showImage: _shouldShowImage(article),
                            onImageError: _markImageBroken,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        _NewsLoadMore(
                          visible: _news?.hasMore ?? false,
                          loading: _loadingMore,
                          shown: _articles.length,
                          total: _totalArticles,
                          onPressed: () => _loadNews(append: true),
                        ),
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
