import 'package:exam_dashboard/Log/log_in.dart';
import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:exam_dashboard/screen/CheatingIncidents.dart';
import 'package:exam_dashboard/screen/schedule_page.dart';
import 'package:exam_dashboard/screen/search.dart';
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
    final token = prefs.getString('token');
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // إذا لم يوجد توكن نعتبره غير مسجل الدخول
    if (token == null || token.isEmpty) {
      await prefs.setBool('isLoggedIn', false);
      return false;
    }

    return isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(), // الوضع الفاتح الافتراضي
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
                ? const AdminDashboardScreen()
                : const LoginScreen();
          }
        },
      ),
      routes: {
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/data_input': (context) => const AdminDataEntryScreen(),
        '/linear': (context) => const SchedulePage(),
        '/statistics': (context) => const AdminStatisticsScreen(),
        '/user_management': (context) => UserManagementScreen(),
        // '/supervisor_dashboard': (context) => const SupervisorHomeScreen(),
        // '/supervisor_schedule': (context) => SupervisorScheduleScreen(),
        // '/supervisor_monitoring': (context) =>
        //     const SupervisorHallMonitoringScreen(),
        '/login': (context) => const LoginScreen(),
        '/exam_schedule_generator': (context) => FullSchedulePage(),
        '/search_dashboard': (context) => SearchDataScreen(),
        '/CheatingListScreen': (context) => CheatingListScreen(),
      },
    );
  }
}
