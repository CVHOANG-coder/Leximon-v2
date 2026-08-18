/// Returns the app's canonical language key for either an app or asset alias.
///
/// The app keeps the legacy keys on the right for compatibility with its
/// existing catalogues, while newer lesson payloads may use the key on the
/// left.
String canonicalLanguageCode(String languageCode) {
  final normalized = languageCode.trim().replaceAll('_', '-');
  return switch (normalized.toLowerCase()) {
    'es' => 'es-ES',
    'es-419' => 'es-US',
    'es-es' => 'es-ES',
    'es-us' => 'es-US',
    'id' => 'in',
    'he' => 'iw',
    'no' => 'nb',
    'tl' => 'fil',
    'zh-cn' => 'zh',
    'zh-hans' => 'zh',
    'zh-tw' => 'zh-TW',
    'zh-hk' => 'zh-TW',
    'zh-mo' => 'zh-TW',
    'in' => 'in',
    'iw' => 'iw',
    'nb' => 'nb',
    'fil' => 'fil',
    'zh' => 'zh',
    _ => normalized,
  };
}
