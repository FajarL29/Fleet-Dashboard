/// The last data each page loaded, kept for the signed-in session.
///
/// Pages are rebuilt from scratch on every visit, so without this each one
/// opened on an empty skeleton and waited for the network again. With it a
/// page paints what it showed last time and refreshes behind it.
///
/// Scoped to the session by where it is provided, so the next person to sign
/// in never sees the previous one's data.
class PageDataCache {
  final Map<String, Object> _entries = {};

  T? read<T extends Object>(String key) {
    final value = _entries[key];
    return value is T ? value : null;
  }

  void write(String key, Object value) => _entries[key] = value;
}
