/// What a signed-in person is allowed to do.
///
/// Parsed from the `role` the login response carries. The API returns
/// "Admin" or "User"; anything else — a new role nobody taught the app about,
/// a null, a typo — resolves to [UserRole.user], the least privileged one.
/// Guessing upward on an unrecognised value would hand out access nobody
/// granted.
enum UserRole {
  /// Full access, including changes to the fleet registry and settings.
  admin,

  /// Reads everything operational, changes nothing.
  user;

  static UserRole parse(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'admin' || 'administrator' => UserRole.admin,
      _ => UserRole.user,
    };
  }

  /// What to show in the account bar.
  String get label => switch (this) {
    UserRole.admin => 'Admin',
    UserRole.user => 'Managerial',
  };

  // --- What each role may do -------------------------------------------
  //
  // Named after the action rather than the role, so a call site reads as
  // "if you may edit the fleet" instead of "if you are an admin" — which is
  // what keeps a third role from meaning a hunt through every widget.

  /// Add, edit or deactivate a vehicle in the registry.
  bool get canManageFleet => this == UserRole.admin;

  /// Open the Settings page.
  bool get canOpenSettings => this == UserRole.admin;

  /// Export report data out of the system.
  ///
  /// Left open to both for now: reporting upward is the managerial job, and
  /// closing it would stop that. Worth revisiting if exports start carrying
  /// driver health data.
  bool get canExportReports => true;

  /// See raw vital-sign readings rather than just a status.
  ///
  /// Driver heart rate and SpO₂ are personal health data. The masked view for
  /// everyone else is not built yet — it needs thresholds from whoever owns
  /// driver welfare, not numbers invented here.
  bool get canSeeRawVitalSigns => this == UserRole.admin;
}
