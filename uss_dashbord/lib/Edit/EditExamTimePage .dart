import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditExamTimePage extends StatefulWidget {
  final Map<String, dynamic> examTime;

  const EditExamTimePage({super.key, required this.examTime});

  @override
  State<EditExamTimePage> createState() => _EditExamTimePageState();
}

class _EditExamTimePageState extends State<EditExamTimePage> {
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _timeController = TextEditingController(text: widget.examTime['time']);
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    String newTime = _timeController.text;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var dio = Dio();
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var data = {
      'time': newTime,
    };

    try {
      var response = await dio.put(
        'http://localhost:8000/api/exam-times/${widget.examTime['id']}',
        data: json.encode(data),
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
        Navigator.pop(context, true); // إعادة true لإعلام الصفحة السابقة
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في حفظ التعديلات')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        title: const Text(
          'تعديل وقت الامتحان',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              style: const TextStyle(color: Colors.white),
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'الوقت',
                labelStyle: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveChanges,
              child: const Text(
                'حفظ التعديلات',
                style: const TextStyle(color: Colors.lightBlueAccent),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
