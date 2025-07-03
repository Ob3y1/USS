import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditExamDayPage extends StatefulWidget {
  final Map<String, dynamic> examDay;

  const EditExamDayPage({super.key, required this.examDay});

  @override
  State<EditExamDayPage> createState() => _EditExamDayPageState();
}

class _EditExamDayPageState extends State<EditExamDayPage> {
  late TextEditingController dayController;
  late TextEditingController dateController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    dayController = TextEditingController(text: widget.examDay['day'] ?? '');
    dateController = TextEditingController(text: widget.examDay['date'] ?? '');
  }

  @override
  void dispose() {
    dayController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> saveChanges() async {
    setState(() {
      isSaving = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final data = {
      "day": dayController.text.trim(),
      "date": dateController.text.trim(),
    };

    try {
      final dio = Dio();
      final response = await dio.put(
        'http://localhost:8000/api/exam-days/${widget.examDay['id']}',
        options: Options(headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
        Navigator.pop(context, true); // الرجوع مع إعلام الصفحة السابقة بالتحديث
      } else {
        print(response);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل في حفظ التعديلات: ${response.statusMessage}')),
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'خطأ أثناء الحفظ';
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          errorMessage = errors.values
              .expand((list) => (list as List).map((msg) => msg.toString()))
              .join('\n');
        } else if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ غير متوقع: $e')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل يوم الامتحان')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: dayController,
              decoration: const InputDecoration(
                labelText: 'اليوم',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'التاريخ',
                hintText: 'YYYY/MM/DD',
              ),
            ),
            const SizedBox(height: 24),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveChanges,
                    child: const Text('حفظ التعديلات'),
                  ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}
