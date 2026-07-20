class ThumbnailGenerator {
  const ThumbnailGenerator();

  String generate(String sourceUrl) {
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) {
      return '$sourceUrl.thumbnail.jpg';
    }

    final query = Map<String, String>.from(uri.queryParameters);
    query['thumbnail'] = '1';
    query['width'] = '640';
    query['height'] = '360';
    return uri.replace(queryParameters: query).toString();
  }
}
