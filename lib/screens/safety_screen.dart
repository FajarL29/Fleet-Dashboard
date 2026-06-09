import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../theme/app_theme.dart';
import '../widgets/safety/safety_content.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkNavy,
      child: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          buildWhen: (prev, curr) =>
              prev.selectedVehicle != curr.selectedVehicle,
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: SafetyContent(
                initialSelectedVehicle: state.selectedVehicle,
              ),
            );
          },
        ),
      ),
    );
  }
}
