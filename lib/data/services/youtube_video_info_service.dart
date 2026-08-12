import 'dart:convert';

import 'package:http/http.dart' as http;

class YoutubeVideoInfo {
  const YoutubeVideoInfo({
    required this.title,
    required this.author,
    required this.thumbnailUrl,
  });

  final String title;
  final String author;
  final String thumbnailUrl;
}

class YoutubeVideoInfoService {
  const YoutubeVideoInfoService({this.client});

  final http.Client? client;

  Future<YoutubeVideoInfo> load(String videoId) async {
    final watchUrl = Uri.https('www.youtube.com', '/watch', {'v': videoId});
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': watchUrl.toString(),
      'format': 'json',
    });
    final response = await (client?.get(uri) ?? http.get(uri));
    if (response.statusCode != 200) {
      throw StateError('YouTube metadata returned ${response.statusCode}.');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return YoutubeVideoInfo(
      title: json['title'] as String? ?? '',
      author: json['author_name'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
    );
  }
}
