import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/report/report_content.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkNavy,
      child: const SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              // child: Header(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: ReportContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
