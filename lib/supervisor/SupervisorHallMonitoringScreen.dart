import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SupervisorHallMonitoringScreen extends StatelessWidget {
  const SupervisorHallMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // مثال واجهة مراقبة القاعة (يمكن استبداله ببث فيديو أو خريطة الكاميرا)
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
         centerTitle: true,
        backgroundColor: Color.fromARGB(255, 50, 50, 65),
        title: const Text(
          'مراقبة القاعة',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'شاشة مراقبة القاعة الامتحانية مباشر',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
