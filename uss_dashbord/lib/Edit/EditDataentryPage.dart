import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubjectDetailsPage extends StatefulWidget {
  final int subjectId;

  const SubjectDetailsPage({super.key, required this.subjectId});

  @override
  // ignore: library_private_types_in_public_api
  _SubjectDetailsPageState createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  Map<String, dynamic>? subjectData;
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();
  final TextEditingController yearController = TextEditingController();

  List<Map<String, dynamic>> allSpecialties = [];
  List<int> selectedSpecialties = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await fetchSpecialties();
    await showsubject();
  }

  Future<void> fetchSpecialties() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();

    try {
      var response = await dio.get(
        'http://localhost:8000/api/dash1',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['specialties'] != null) {
          setState(() {
            allSpecialties =
                List<Map<String, dynamic>>.from(data['specialties']);
          });
        } else {
          print('لا توجد بيانات تخصصات');
        }
      } else {
        print('خطأ في جلب التخصصات: ${response.statusMessage}');
      }
    } catch (e) {
      print('خطأ في الاتصال لجلب التخصصات: $e');
    }
  }

  Future<void> showsubject() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();

    try {
      var response = await dio.get(
        'http://localhost:8000/api/subject/${widget.subjectId}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          subjectData = data;
          nameController.text = data['name'];
          studentNumberController.text = data['student_number'].toString();
          yearController.text = data['year'].toString();

          selectedSpecialties = List<int>.from(
              data['specialties'].map((spec) => spec['id'] as int));
          isLoading = false;
        });
      } else {
        print('خطأ: ${response.statusMessage}');
      }
    } catch (e) {
      print('خطأ في الاتصال: $e');
    }
  }

  Future<void> saveChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final data = json.encode({
      'name': nameController.text,
      'student_number': studentNumberController.text,
      'year': yearController.text,
      'specialties': selectedSpecialties, // نرسل قائمة الأرقام فقط
    });

    var dio = Dio();
    var response = await dio.put(
      'http://localhost:8000/api/subjects/${widget.subjectId}',
      data: data,
      options: Options(headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }),
    );

    if (response.statusCode == 200) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل في حفظ التعديلات: ${response.statusMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'تعديل بيانات المادة',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blue),
        backgroundColor: Colors.white, // خلفية بيضاء
        elevation: 1, // ظل خفيف للتمييز
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'اسم المادة',
                labelStyle: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentNumberController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'عدد الطلاب',
                labelStyle: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                labelText: 'المستوى الدراسي',
                labelStyle: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'التخصصات المرتبطة:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: allSpecialties.map<Widget>((spec) {
                final id = spec['id'] as int;
                return FilterChip(
                  label: Text(
                    spec['name'],
                    style: TextStyle(
                      color: selectedSpecialties.contains(id)
                          ? Colors.black87
                          : Colors.black,
                    ),
                  ),
                  selected: selectedSpecialties.contains(id),
                  selectedColor: Colors.lightBlueAccent,
                  backgroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedSpecialties.add(id);
                      } else {
                        selectedSpecialties.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: saveChanges,
              child: const Text(
                'حفظ التعديلات',
                style: const TextStyle(color: Colors.lightBlueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
