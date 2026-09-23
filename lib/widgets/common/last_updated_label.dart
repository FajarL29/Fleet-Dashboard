import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

/// "Last updated Wednesday, 19 August 2026 - 09.20 WIB", with the weekday
/// emphasised. Shared by the light pages' headers.
class LastUpdatedLabel extends StatelessWidget {
  const LastUpdatedLabel({super.key, required this.timestamp});

  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      color: AppColors.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w400,
    );

    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Last updated '),
          TextSpan(
            text: DateFormat('EEEE').format(timestamp),
            style: base.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text:
                ', ${DateFormat('d MMMM yyyy').format(timestamp)}'
                ' - ${DateFormat('HH.mm').format(timestamp)} WIB',
          ),
        ],
      ),
      style: base,
    );
  }
}
