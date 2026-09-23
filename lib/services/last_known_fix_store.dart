import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/live_gps_fix.dart';

/// Remembers where each device was last seen, across restarts.
///
/// A rig that stops transmitting used to disappear from the map the moment the
/// app was relaunched — the fixes only ever lived in bloc state. Keeping the
/// last one on disk means the marker comes back where it was, still plainly
/// marked as a remembered position, instead of leaving nothing at all.
///
/// Every operation is best-effort. A missing, unreadable or half-written file
/// is not an error worth surfacing: it only means the map waits for the next
/// live fix, which is exactly what used to happen anyway.
class LastKnownFixStore {
  const LastKnownFixStore();

  static const String _fileName = 'last_known_gps_fixes.json';

  /// How long a remembered position is worth restoring.
  ///
  /// Past this the vehicle has been somewhere else for a long time and the dot
  /// says nothing useful — better an empty map than a year-old ghost.
  static const Duration maxRestoreAge = Duration(days: 7);

  Future<File?> _file() async {
    // No filesystem on web, and `path_provider` throws there rather than
    // returning null.
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/$_fileName');
    } catch (error) {
      debugPrint('[GPS] last-known store unavailable: $error');
      return null;
    }
  }

  /// The fixes saved by a previous run, dropping anything older than
  /// [maxRestoreAge].
  Future<Map<String, LiveGpsFix>> load({DateTime? now}) async {
    try {
      final file = await _file();
      if (file == null || !file.existsSync()) return const {};

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const {};

      final at = now ?? DateTime.now();
      final restored = <String, LiveGpsFix>{};
      for (final entry in decoded.entries) {
        final fix = LiveGpsFix.tryFromJson(entry.value);
        if (fix == null || fix.age(now: at) > maxRestoreAge) continue;
        restored['${entry.key}'] = fix;
      }
      if (restored.isNotEmpty) {
        debugPrint('[GPS] restored ${restored.length} last-known position(s)');
      }
      return restored;
    } catch (error) {
      debugPrint('[GPS] could not read last-known positions: $error');
      return const {};
    }
  }

  Future<void> save(Map<String, LiveGpsFix> fixes) async {
    try {
      final file = await _file();
      if (file == null) return;
      await file.writeAsString(
        jsonEncode({
          for (final entry in fixes.entries) entry.key: entry.value.toJson(),
        }),
        flush: true,
      );
    } catch (error) {
      debugPrint('[GPS] could not save last-known positions: $error');
    }
  }
}
