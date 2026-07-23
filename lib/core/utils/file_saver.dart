// Saves/downloads raw file bytes. Web triggers a browser download; other
// platforms throw until a native save path is wired.
export 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart';
