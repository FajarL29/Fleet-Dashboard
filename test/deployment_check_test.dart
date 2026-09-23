import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_dashboard/services/deployment_check.dart';

void main() {
  // These run on the VM, where kIsWeb is false and there is no page scheme,
  // so the mixed-content rules do not apply. What this pins down is that the
  // check stays quiet off the web rather than inventing a problem — the same
  // build runs on macOS, where plain http is perfectly legal.
  test('no false alarm outside the browser', () {
    expect(DeploymentCheck.problem, isNull);
  });

  test('reporting is safe to call and does not throw', () {
    expect(DeploymentCheck.report, returnsNormally);
  });
}
