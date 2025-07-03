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
      appBar: AppBar(title: const Text('تعديل وقت الامتحان')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _timeController,
              decoration: const InputDecoration(labelText: 'الوقت'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: saveChanges,
                  child: const Text('حفظ التعديلات'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
