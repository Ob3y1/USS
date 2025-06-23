import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
         centerTitle: true,
        backgroundColor: Color.fromARGB(255, 50, 50, 65),
        title: const Text(
          'الإحصائيات',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text(
          'عرض الإحصائيات لحالات الغش المكشوفة هنا',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
