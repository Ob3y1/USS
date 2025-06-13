import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';

class ExamScheduleGeneratorScreen extends StatelessWidget {
  const ExamScheduleGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
         centerTitle: true,
        backgroundColor: Color.fromARGB(255, 50, 50, 65),
        title: const Text('توليد البرنامج الامتحاني',
            style: TextStyle(color: Colors.white, fontSize: 24)),
        iconTheme: IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 400), // المسافة من الأعلى
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم توليد البرنامج الامتحاني',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'توليد البرنامج',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
