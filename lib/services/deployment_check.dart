import 'package:flutter/foundation.dart';

import 'api_config.dart';

/// Configuration problems that cannot possibly work, detected before they turn
/// into an unreadable network error.
///
/// Every one of these fails as a bare "Failed to fetch" in the browser, with
/// no hint of the cause. Naming them is the difference between a five-minute
/// fix and an afternoon.
class DeploymentCheck {
  const DeploymentCheck._();

  /// The scheme the app itself was served over.
  ///
  /// On web this is the page's scheme. On native there is no page, and
  /// [Uri.base] describes the working directory instead — so the mixed-content
  /// rules below simply do not apply and the checks return null.
  static String? get _pageScheme => kIsWeb ? Uri.base.scheme : null;

  /// A blocking misconfiguration, or null when nothing is obviously wrong.
  ///
  /// "Obviously" is the point: this only reports things that are certain, so a
  /// message from here is always worth acting on.
  static String? get problem {
    final page = _pageScheme;
    if (page != 'https') return null;

    // A browser refuses plaintext subresources on a secure page. Both of these
    // fail silently from the app's side — the request never leaves.
    if (kApiBaseUrl.startsWith('http://')) {
      return 'This page is served over HTTPS but the API is plain HTTP '
          '($kApiBaseUrl). Browsers block that as mixed content, so no '
          'request ever leaves. The API needs to be served over HTTPS.';
    }

    if (kGpsSocketUrl.startsWith('ws://')) {
      return 'This page is served over HTTPS but the GPS socket is plain ws '
          '($kGpsSocketUrl). Browsers block that, so live positions will '
          'never arrive. It needs wss://.';
    }

    return null;
  }

  /// Logs any problem once at startup, so it is visible before a user has to
  /// discover it by failing to sign in.
  static void report() {
    final found = problem;
    if (found != null) {
      debugPrint('[Deployment] $found');
    }
  }
}
