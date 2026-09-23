import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import 'animated_fleet_panel.dart';

/// The frame both auth pages live in: the animated panel on the left, whichever
/// form is active on the right.
///
/// The panel is a `const` widget in a fixed slot, so switching between sign-in
/// and sign-up rebuilds only [child] — the scene keeps running and the two
/// pages read as one page changing its words rather than as a navigation.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.switchPrompt,
    required this.switchAction,
    required this.onSwitch,
    required this.child,
    this.showLegalFooter = true,
  });

  /// Below this the two columns cannot both be useful, so the panel is dropped
  /// and the form gets the whole width.
  static const double _twoColumnWidth = 1040;

  /// Widest the form is allowed to get. Sized so the two-column field rows on
  /// the sign-up page stay comfortable to scan.
  static const double _formWidth = 560;

  /// Inset around the whole page, and the gap between the two halves. The same
  /// number in both places is what makes the halves read as a matched pair.
  static const double _gutter = 20;

  /// "Already have an account?" / "Don't have an account?"
  final String switchPrompt;

  /// "Log in" / "Sign Up"
  final String switchAction;
  final VoidCallback? onSwitch;

  /// The active form. The only thing that changes between the two pages.
  final Widget child;

  /// The sign-up form is tall enough already; the design only carries these
  /// lines under the sign-in form.
  final bool showLegalFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _twoColumnWidth) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: _gutter),
                child: _formColumn(),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(_gutter),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Equal flex and one shared gutter: the panel and the form
                  // occupy the same width, so neither half looks borrowed from
                  // the other.
                  const Expanded(child: AnimatedFleetPanel()),
                  const SizedBox(width: _gutter),
                  Expanded(child: _formColumn()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _formColumn() {
    // Scrolls only when the window is genuinely too short for the form; at any
    // ordinary size the content fits and this never becomes scrollable.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 18),
      // Top-aligned, not centred: sign-up is the taller form, and centring
      // both would leave the shorter sign-in heading sitting lower down, so
      // the title would jump every time you toggle.
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _formWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              const SizedBox(height: 24),
              _SwitchLink(
                prompt: switchPrompt,
                action: switchAction,
                onPressed: onSwitch,
              ),
              if (showLegalFooter) ...[
                // The design leaves a lot of air above the footer — it reads
                // as a distinct block anchored near the bottom of the column,
                // not something trailing right off the switch link.
                const SizedBox(height: 56),
                const _LegalFooter(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign Up", under the buttons.
///
/// It lives in the shell rather than in either form so it lands in the same
/// place on both pages, which is what stops the bottom of the column from
/// twitching as you toggle.
class _SwitchLink extends StatelessWidget {
  const _SwitchLink({
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Wrap, not Row: on a narrow window the prompt and the action together are
    // wider than the column, and this drops the action onto its own line
    // instead of clipping it off the edge.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: const TextStyle(
            color: AuthColors.textSecondary,
            fontSize: 13.5,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AuthColors.brandBlue,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// The reassurance and copyright lines at the foot of the column.
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'FleetSafe is a secure system for authorized users only.\n'
          'All data is protected and monitored.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AuthColors.muted,
            fontSize: 11.5,
            height: 1.6,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '© 2026 FleetSafe. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AuthColors.muted, fontSize: 11.5),
        ),
      ],
    );
  }
}

/// The heading block every auth form opens with.
///
/// Both pages use it at the same sizes so the two headings occupy identical
/// height — a taller heading on one page would shove every field below it and
/// make the toggle look like a jump.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AuthColors.textPrimary,
            fontSize: 30,
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AuthColors.textSecondary,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// A section caption such as "Personal Information".
class AuthSectionTitle extends StatelessWidget {
  const AuthSectionTitle(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AuthColors.textPrimary,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Lays two fields side by side, stacking them when the column is narrow.
class AuthFieldRow extends StatelessWidget {
  const AuthFieldRow({super.key, required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(children: [left, const SizedBox(height: 14), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
