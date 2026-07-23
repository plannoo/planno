/// Non-web fallback. A native save (path_provider + open_file) isn't wired yet,
/// so surface a clear message instead of silently doing nothing.
Future<void> saveFile(List<int> bytes, String filename, String mimeType) async {
  throw UnsupportedError(
      'Downloading files is currently supported in the web app only.');
}
