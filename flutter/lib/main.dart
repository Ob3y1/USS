import 'package:exam_dashboard/Log/log_in.dart';
import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_dashboard/screen/admin_statistics.dart';
import 'package:exam_dashboard/screen/admin_user_management.dart';
import 'package:exam_dashboard/screen/data_entry.dart';
import 'package:exam_dashboard/screen/schedule_generator.dart';
import 'package:exam_dashboard/supervisor/SupervisorHallMonitoringScreen.dart';
import 'package:exam_dashboard/supervisor/SupervisorScheduleScreen.dart';
import 'package:exam_dashboard/supervisor/supervisor_home_screen.dart';
import 'package:exam_dashboard/screen/dashboard.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => UserCubit(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            bool loggedIn = snapshot.data ?? false;
            return loggedIn
                ? const AdminStatisticsScreen()
                : const LoginScreen();
          }
        },
      ),
      routes: {
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/data_input': (context) => const AdminDataEntryScreen(),
        '/exam_schedule_generator': (context) =>
            const ExamScheduleGeneratorScreen(),
        '/statistics': (context) => const AdminStatisticsScreen(),
        '/user_management': (context) => UserManagementScreen(),
        '/supervisor_dashboard': (context) => const SupervisorHomeScreen(),
        '/supervisor_schedule': (context) => SupervisorScheduleScreen(),
        '/supervisor_monitoring': (context) =>
            const SupervisorHallMonitoringScreen(),
        '/login': (context) => const LoginScreen(),
        
      },
    );
  }
}
