import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/ipa_sound.dart';

typedef IpaDownloadProgressCallback =
    void Function(IpaDownloadProgress progress);

class IpaDownloadProgress {
  const IpaDownloadProgress({required this.completed, required this.total});

  final int completed;
  final int total;

  double get fraction => total <= 0 ? 0 : completed / total;
}

/// Lazily downloads IPA files into app-private storage while preserving the
/// server's `/data/ipa` folder structure.
class IpaLocalDataSource {
  static const remoteBaseUrl = 'https://leximonenglish.giddychat.com/data/ipa';
  static const _manifestFile = 'manifest.json';
  static const _languages = ['en', 'es', 'fr', 'pt', 'ru'];

  static final _activeFileDownloads = <String, Future<File>>{};
  static Directory? _storageOverrideForTesting;

  /// Allows unit tests to provide a writable directory without registering
  /// the platform path_provider plugin.
  static void setStorageDirectoryForTesting(Directory? directory) {
    _storageOverrideForTesting = directory;
  }

  /// Keeps the existing API name while changing the implementation to lazy
  /// metadata loading. Media is downloaded by [ensureMediaReady] on demand.
  static Future<Directory> ensureReady({
    required List<String> symbols,
    String languageCode = 'en',
    http.Client? client,
    IpaDownloadProgressCallback? onProgress,
  }) => ensureMetadataReady(
    symbols: symbols,
    languageCode: languageCode,
    client: client,
    onProgress: onProgress,
  );

  static Future<Directory> ensureMetadataReady({
    required List<String> symbols,
    required String languageCode,
    http.Client? client,
    IpaDownloadProgressCallback? onProgress,
  }) async {
    final ipaDirectory = await _storageDirectory();
    final manifestFile = await _ensureFile(
      ipaDirectory,
      _manifestFile,
      client: client,
    );
    final config = _RemoteConfig.fromBytes(await manifestFile.readAsBytes());
    final language = _normalizeLanguage(languageCode);
    final files = <String>{
      _manifestFile,
      '${config.descriptionsDirectory}/$language.json',
      config.youtubeCatalog,
      for (final symbol in symbols) '${config.jsonDirectory}/$symbol.json',
    };
    return _ensureFiles(
      ipaDirectory,
      files,
      client: client,
      onProgress: onProgress,
    );
  }

  static Future<void> ensureMediaReady({
    required IpaSound sound,
    http.Client? client,
    IpaDownloadProgressCallback? onProgress,
  }) async {
    final mediaPaths = [
      sound.audioAsset,
      sound.photoAsset,
      ...sound.spellingWords.map((word) => word.audioAsset),
      ...sound.beginningWords.map((word) => word.audioAsset),
      ...sound.middleWords.map((word) => word.audioAsset),
      ...sound.endWords.map((word) => word.audioAsset),
    ];
    final localPaths = mediaPaths.where(_needsLocalMediaDownload).toList();
    if (localPaths.isEmpty) {
      onProgress?.call(const IpaDownloadProgress(completed: 1, total: 1));
      return;
    }

    final ipaDirectory = await _storageDirectory();
    final files = <String>{
      for (final path in localPaths) _relativeMediaPath(path, ipaDirectory),
    };
    await _ensureFiles(
      ipaDirectory,
      files,
      client: client,
      onProgress: onProgress,
    );
  }

  static Future<void> clearCacheForTesting() async {
    final ipaDirectory = await _storageDirectory();
    if (await ipaDirectory.exists()) {
      await ipaDirectory.delete(recursive: true);
    }
    _activeFileDownloads.clear();
  }

  static Future<Directory> _storageDirectory() async {
    final override = _storageOverrideForTesting;
    if (override != null) return override;

    final appSupportDirectory = await getApplicationSupportDirectory();
    return Directory('${appSupportDirectory.path}/data/ipa');
  }

  static Future<Directory> _ensureFiles(
    Directory ipaDirectory,
    Iterable<String> files, {
    http.Client? client,
    IpaDownloadProgressCallback? onProgress,
  }) async {
    final requestedFiles = files.toSet().toList(growable: false);
    var completed = 0;
    final total = requestedFiles.length;
    void report() => onProgress?.call(
      IpaDownloadProgress(completed: completed, total: total),
    );

    report();
    for (final relativePath in requestedFiles) {
      await _ensureFile(ipaDirectory, relativePath, client: client);
      completed++;
      report();
    }
    return ipaDirectory;
  }

  static Future<File> _ensureFile(
    Directory root,
    String relativePath, {
    http.Client? client,
  }) async {
    final file = File('${root.path}/$relativePath');
    if (await file.exists()) return file;

    final activeDownload = _activeFileDownloads[relativePath];
    if (activeDownload != null) return activeDownload;

    final download = _downloadFile(root, relativePath, client: client);
    _activeFileDownloads[relativePath] = download;
    try {
      return await download;
    } finally {
      if (identical(_activeFileDownloads[relativePath], download)) {
        _activeFileDownloads.remove(relativePath);
      }
    }
  }

  static Future<File> _downloadFile(
    Directory root,
    String relativePath, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    final closeClient = client == null;
    try {
      final file = File('${root.path}/$relativePath');
      if (await file.exists()) return file;
      final bytes = await _getBytes(httpClient, relativePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } finally {
      if (closeClient) httpClient.close();
    }
  }

  static Future<List<int>> _getBytes(
    http.Client client,
    String relativePath,
  ) async {
    final response = await client
        .get(_remoteUri(relativePath))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw IpaDownloadException(
        relativePath: relativePath,
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  static Uri _remoteUri(String relativePath) {
    return Uri(
      scheme: 'https',
      host: 'leximonenglish.giddychat.com',
      pathSegments: ['data', 'ipa', ...relativePath.split('/')],
    );
  }

  static bool _needsLocalMediaDownload(String path) {
    if (path.isEmpty) return false;
    final parsed = Uri.tryParse(path);
    if (parsed?.hasScheme == true) return false;
    return path.startsWith('/') || path.startsWith('AmericanSounds/');
  }

  static String _relativeMediaPath(String path, Directory root) {
    if (path.startsWith('${root.path}/')) {
      return path.substring(root.path.length + 1);
    }
    const legacyPrefix = 'AmericanSounds/';
    if (path.startsWith(legacyPrefix)) {
      return path.substring(legacyPrefix.length);
    }
    return path.replaceFirst(RegExp(r'^/'), '');
  }

  static String _normalizeLanguage(String languageCode) {
    final normalized = languageCode.trim().toLowerCase().split(RegExp('[-_]'));
    return _languages.contains(normalized.first) ? normalized.first : 'en';
  }
}

class IpaDownloadException implements Exception {
  const IpaDownloadException({
    required this.relativePath,
    required this.statusCode,
  });

  final String relativePath;
  final int statusCode;

  @override
  String toString() =>
      'Could not download IPA file "$relativePath" (HTTP $statusCode).';
}

class _RemoteConfig {
  const _RemoteConfig({
    required this.jsonDirectory,
    required this.descriptionsDirectory,
    required this.youtubeCatalog,
  });

  factory _RemoteConfig.fromBytes(List<int> bytes) {
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic>) {
      throw const FormatException('IPA manifest must contain a JSON object.');
    }

    String read(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty
          ? value.trim().replaceFirst(RegExp(r'^/'), '')
          : fallback;
    }

    return _RemoteConfig(
      jsonDirectory: read('jsonDirectory', 'json'),
      descriptionsDirectory: read('descriptionsDirectory', 'descriptions'),
      youtubeCatalog: read('youtubeCatalog', 'youtube_videos.json'),
    );
  }

  final String jsonDirectory;
  final String descriptionsDirectory;
  final String youtubeCatalog;
}
