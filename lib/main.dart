//import 'package:fleet_dashboard/core/services/gps_socket_service.dart';
import 'package:fleet_dashboard/data/services/gps_socket_service.dart';
import 'package:fleet_dashboard/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:fleet_dashboard/features/dashboard/bloc/dashboard_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
//import 'providers/dashboard_provider.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider( // Ganti dari MultiProvider ke MultiBlocProvider
      providers: [
        BlocProvider<DashboardBloc>( // Tambahkan tipe data <DashboardBloc> agar jelas
          create: (context) => DashboardBloc(GpsSocketService())
            ..add(StartGpsTracking('1210')),
        ),
      ],
      child: MaterialApp(
        title: 'Fleet Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DashboardScreen(),
      ),
    );
  }
}
