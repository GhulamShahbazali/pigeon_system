import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Tiny on-disk JSON cache for stale-while-revalidate (Facebook-style): show the
/// last-seen content instantly on cold start, then refresh in the background.
/// Uses path_provider (already a dependency) — no new package. Every read/write
/// is best-effort and never throws, so a missing/corrupt cache just means "no
/// cached content yet".
class JsonCacheService {
  Directory? _dir;

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/pf_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  File _fileFor(Directory dir, String key) {
    final safe = key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return File('${dir.path}/$safe.json');
  }

  /// Read a cached JSON list (e.g. a list of post/tournament maps). Null if none.
  Future<List<dynamic>?> readList(String key) async {
    try {
      final file = _fileFor(await _cacheDir(), key);
      if (!await file.exists()) return null;
      final decoded = jsonDecode(await file.readAsString());
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Persist a JSON list (each item must be json-encodable, e.g. model.toJson()).
  Future<void> writeList(String key, List<dynamic> data) async {
    try {
      final file = _fileFor(await _cacheDir(), key);
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      /* best-effort cache — ignore write failures */
    }
  }
}
