class NewsResponse {
  const NewsResponse({
    required this.items,
    required this.updatedAt,
    required this.sources,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final List<NewsArticle> items;
  final String? updatedAt;
  final List<NewsSourceStatus> sources;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      items: _readList(json['items'], NewsArticle.fromJson),
      updatedAt: _readNullableString(json['updatedAt']),
      sources: _readList(json['sources'], NewsSourceStatus.fromJson),
      total: _readInt(json['total']),
      limit: _readInt(json['limit']),
      offset: _readInt(json['offset']),
      hasMore: _readBool(json['hasMore']),
    );
  }
}

class NewsArticle {
  const NewsArticle({
    required this.id,
    required this.title,
    required this.source,
    required this.sourceLabel,
    required this.url,
    this.publishedAt,
    this.excerpt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String source;
  final String sourceLabel;
  final String url;
  final String? publishedAt;
  final String? excerpt;
  final String? imageUrl;

  static NewsArticle? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    final id = _readString(json['id']);
    final title = _readString(json['title']);
    final url = _readString(json['url']);
    if (id.isEmpty || title.isEmpty || url.isEmpty) {
      return null;
    }

    return NewsArticle(
      id: id,
      title: title,
      source: _readString(json['source']),
      sourceLabel: _readString(json['sourceLabel'], fallback: 'Source'),
      url: url,
      publishedAt: _readNullableString(json['publishedAt']),
      excerpt: _readNullableString(json['excerpt']),
      imageUrl: _readNullableString(json['imageUrl']),
    );
  }
}

class NewsSourceStatus {
  const NewsSourceStatus({
    required this.source,
    required this.sourceLabel,
    required this.status,
    required this.articlesCount,
    this.error,
  });

  final String source;
  final String sourceLabel;
  final String status;
  final int articlesCount;
  final String? error;

  bool get isOk => status == 'ok';

  static NewsSourceStatus? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }

    return NewsSourceStatus(
      source: _readString(json['source']),
      sourceLabel: _readString(json['sourceLabel'], fallback: 'Source'),
      status: _readString(json['status']),
      articlesCount: _readInt(json['articlesCount']),
      error: _readNullableString(json['error']),
    );
  }
}

List<T> _readList<T>(Object? value, T? Function(Object? json) mapper) {
  if (value is! List) {
    return const [];
  }

  return value.map(mapper).whereType<T>().toList();
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }

  if (value is num) {
    return value.toString();
  }

  return fallback;
}

String? _readNullableString(Object? value) {
  final string = _readString(value);
  return string.isEmpty ? null : string;
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

bool _readBool(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is String) {
    return value.toLowerCase() == 'true';
  }

  return false;
}
