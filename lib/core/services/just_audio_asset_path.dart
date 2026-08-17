/// Encodes a Flutter asset key before passing it to `just_audio`.
///
/// `just_audio` builds an `asset:///` URI and then decodes its path segments
/// before loading the Flutter asset. Encoding once here preserves literal URI
/// characters in filenames, such as the `%2f` in `flour%2fflower.mp3`.
String justAudioAssetPath(String assetKey) {
  final protectedPercentSigns = assetKey.replaceAll('%', '%25');
  return Uri(path: protectedPercentSigns).toString();
}

bool isRemoteMediaUrl(String source) {
  final uri = Uri.tryParse(source);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

bool isLocalFilePath(String source) => source.startsWith('/');
