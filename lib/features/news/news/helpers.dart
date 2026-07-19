part of '../news_screen.dart';

List<NewsArticle> _mergeArticles(
  List<NewsArticle> currentArticles,
  List<NewsArticle> nextArticles,
) {
  final seen = currentArticles.map((article) => article.id).toSet();

  return [
    ...currentArticles,
    ...nextArticles.where((article) => !seen.contains(article.id)),
  ];
}

String _formatArticleDate(String? value) {
  if (value == null || value.isEmpty) {
    return 'Date inconnue';
  }

  final date = DateTime.tryParse(value);
  if (date == null) {
    return 'Date inconnue';
  }

  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month - $hour:$minute';
}

String _formatUpdatedAt(String? value) {
  if (value == null || value.isEmpty) {
    return 'pas encore';
  }

  final date = DateTime.tryParse(value);
  if (date == null) {
    return 'pas encore';
  }

  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month - $hour:$minute';
}

String _pluralSuffix(int count) {
  return count > 1 ? 's' : '';
}

class _NewsSourceFilter {
  const _NewsSourceFilter({required this.key, required this.label});

  final String key;
  final String label;
}
