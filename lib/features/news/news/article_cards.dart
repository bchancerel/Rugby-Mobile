part of '../news_screen.dart';

class _NewsSourceStatusStrip extends StatelessWidget {
  const _NewsSourceStatusStrip({required this.sources});

  final List<NewsSourceStatus> sources;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final source in sources) ...[
            _NewsSourceStatusPill(source: source),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _NewsSourceStatusPill extends StatelessWidget {
  const _NewsSourceStatusPill({required this.source});

  final NewsSourceStatus source;

  @override
  Widget build(BuildContext context) {
    final ok = source.isOk;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ok ? AppColors.surface : const Color(0x1AFBBF24),
        border: Border.all(
          color: ok ? AppColors.border : const Color(0x4DFBBF24),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.sourceLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.grayCool,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              ok ? '${source.articlesCount} articles' : 'Indisponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ok ? AppColors.white : const Color(0xFFFDE68A),
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeadNewsCard extends StatelessWidget {
  const _LeadNewsCard({
    required this.article,
    required this.showImage,
    required this.onImageError,
  });

  final NewsArticle article;
  final bool showImage;
  final ValueChanged<String> onImageError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0x66FF4655)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NewsCardMedia(
              article: article,
              showImage: showImage,
              height: 210,
              onImageError: onImageError,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NewsArticleMeta(article: article),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    article.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                  ),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      article.excerpt!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grayCool,
                            height: 1.35,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactNewsCard extends StatelessWidget {
  const _CompactNewsCard({
    required this.article,
    required this.showImage,
    required this.onImageError,
  });

  final NewsArticle article;
  final bool showImage;
  final ValueChanged<String> onImageError;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _NewsCardMedia(
                article: article,
                showImage: showImage,
                width: 96,
                height: 82,
                onImageError: onImageError,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NewsArticleMeta(article: article),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                  ),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      article.excerpt!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grayCool,
                            height: 1.3,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsCardMedia extends StatelessWidget {
  const _NewsCardMedia({
    required this.article,
    required this.showImage,
    required this.height,
    required this.onImageError,
    this.width,
  });

  final NewsArticle article;
  final bool showImage;
  final double height;
  final double? width;
  final ValueChanged<String> onImageError;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x55FF4655),
              Color(0x33111827),
            ],
          ),
        ),
        child: showImage
            ? Image.network(
                article.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    onImageError(article.id);
                  });
                  return _NewsImageFallback(label: article.sourceLabel);
                },
              )
            : _NewsImageFallback(label: article.sourceLabel),
      ),
    );
  }
}

class _NewsImageFallback extends StatelessWidget {
  const _NewsImageFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label.length <= 2 ? label : label.substring(0, 2);

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _NewsArticleMeta extends StatelessWidget {
  const _NewsArticleMeta({required this.article});

  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            article.sourceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primaryHover,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          _formatArticleDate(article.publishedAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.grayCool,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _NewsLoadMore extends StatelessWidget {
  const _NewsLoadMore({
    required this.visible,
    required this.loading,
    required this.shown,
    required this.total,
    required this.onPressed,
  });

  final bool visible;
  final bool loading;
  final int shown;
  final int total;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        children: [
          Text(
            '$shown / $total articles affiches',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.grayCool,
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (visible) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: loading ? 'Chargement...' : 'Charger plus',
              icon: Icons.add,
              onPressed: loading ? null : onPressed,
            ),
          ],
        ],
      ),
    );
  }
}
