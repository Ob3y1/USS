import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';

class SupervisorHomeScreen extends StatelessWidget {
  const SupervisorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
         centerTitle: true,
        backgroundColor:  Color.fromARGB(255, 50, 50, 65),
        title: const Text('لوحة تحكم المراقب',
            style: TextStyle(color: Colors.white, fontSize: 24)),
        iconTheme: IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 500),
            ElevatedButton.icon(
              icon: const Icon(Icons.schedule, color: Colors.white),
              label: const Text('جدول المواعيد',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/supervisor_schedule');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text('مراقبة القاعة',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
              onPressed: () {
                Navigator.pushReplacementNamed(
                    context, '/supervisor_monitoring');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
