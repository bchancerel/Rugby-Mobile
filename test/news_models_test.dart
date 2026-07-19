import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_jam_mobile/features/news/data/news_models.dart';

void main() {
  group('NewsResponse', () {
    test('parses articles, source statuses and pagination metadata', () {
      final response = NewsResponse.fromJson({
        'updatedAt': '2026-06-17T12:00:00.000Z',
        'total': '2',
        'limit': 24,
        'offset': 0,
        'hasMore': true,
        'sources': [
          {
            'source': 'rugbyrama',
            'sourceLabel': 'Rugbyrama',
            'status': 'ok',
            'articlesCount': 2,
            'error': null,
          },
          {
            'source': 'rugbypass',
            'sourceLabel': 'RugbyPass',
            'status': 'error',
            'articlesCount': 0,
            'error': 'Feed unreachable',
          },
        ],
        'items': [
          {
            'id': 'article-1',
            'title': 'Toulouse prepare sa finale',
            'source': 'rugbyrama',
            'sourceLabel': 'Rugbyrama',
            'url': 'https://www.rugbyrama.fr/article-1',
            'publishedAt': '2026-06-17T10:00:00.000Z',
            'excerpt': 'Le Stade Toulousain affine ses derniers reglages.',
            'imageUrl': 'https://example.com/article.jpg',
          },
          {
            'id': 'article-2',
            'title': 'Mercato: une arrivee se precise',
            'source': 'rugbypass',
            'sourceLabel': 'RugbyPass',
            'url': 'https://www.rugbypass.com/news/article-2',
            'publishedAt': null,
            'excerpt': null,
            'imageUrl': null,
          },
        ],
      });

      expect(response.updatedAt, '2026-06-17T12:00:00.000Z');
      expect(response.total, 2);
      expect(response.limit, 24);
      expect(response.offset, 0);
      expect(response.hasMore, isTrue);
      expect(response.items, hasLength(2));
      expect(response.items.first.title, 'Toulouse prepare sa finale');
      expect(response.items.last.imageUrl, isNull);
      expect(response.sources, hasLength(2));
      expect(response.sources.first.isOk, isTrue);
      expect(response.sources.last.isOk, isFalse);
      expect(response.sources.last.error, 'Feed unreachable');
    });

    test('drops malformed articles and falls back to empty values', () {
      final response = NewsResponse.fromJson({
        'items': [
          {
            'id': 'article-1',
            'title': 'Article valide',
            'url': 'https://example.com/article-1',
          },
          {
            'id': 'missing-url',
            'title': 'Article invalide',
          },
        ],
        'sources': 'invalid',
        'total': 'not-a-number',
        'limit': null,
        'offset': null,
        'hasMore': 'false',
      });

      expect(response.items, hasLength(1));
      expect(response.items.first.sourceLabel, 'Source');
      expect(response.sources, isEmpty);
      expect(response.total, 0);
      expect(response.limit, 0);
      expect(response.offset, 0);
      expect(response.hasMore, isFalse);
    });
  });
}
