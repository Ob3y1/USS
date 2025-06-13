import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditSubjectPage extends StatefulWidget {
  final int subjectId;

  const EditSubjectPage({super.key, required this.subjectId});

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  Map<String, dynamic>? subjectData;
  bool isLoading = true;

  // Controllers لحفظ النصوص وتحديثها
  final TextEditingController nameController = TextEditingController();
  final TextEditingController studentNumberController = TextEditingController();

  int? selectedYear;
  String? selectedSpecialty;

  // قائمة الاختصاصات الكاملة التي سيتم جلبها من API
  List<dynamic> allSpecialties = [];

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await Future.wait([
      fetchSubjectData(),
      fetchAllSpecialties(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchSubjectData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
    };
    var dio = Dio();
    try {
      var response = await dio.get(
        'http://localhost:8000/api/subject/${widget.subjectId}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        var data = response.data;
        setState(() {
          subjectData = data;
          // تعبئة الكنترولرز بالقيم الحالية
          nameController.text = data['name'] ?? '';
          studentNumberController.text =
              data['student_number']?.toString() ?? '';
          selectedYear = data['year'];
          // بيانات الاختصاصات الحالية في المادة
          List<dynamic> specialtiesList = data['specialties'] ?? [];
          if (specialtiesList.isNotEmpty) {
            selectedSpecialty = specialtiesList[0]['name'];
          } else {
            selectedSpecialty = null;
          }
        });
      } else {
        print('خطأ في جلب بيانات المادة: ${response.statusMessage}');
      }
    } catch (e) {
      print('خطأ في الاتصال لجلب المادة: $e');
    }
  }

  Future<void> fetchAllSpecialties() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
    };
    var dio = Dio();
    try {
      var response = await dio.get(
        'http://localhost:8000/api/specialties',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        setState(() {
          allSpecialties = response.data;
        });
      } else {
        print('خطأ في جلب قائمة الاختصاصات: ${response.statusMessage}');
      }
    } catch (e) {
      print('خطأ في الاتصال لجلب الاختصاصات: $e');
    }
  }

  String mapYearToLevel(int? year) {
    switch (year) {
      case 1:
        return 'المستوى الأول';
      case 2:
        return 'المستوى الثاني';
      case 3:
        return 'المستوى الثالث';
      case 4:
        return 'المستوى الرابع';
      case 5:
        return 'المستوى الخامس';
      default:
        return 'غير معروف';
    }
  }

  // دالة حفظ التعديلات
  Future<void> saveSubjectData() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
    };

    var dio = Dio();

    var updatedData = {
      'name': nameController.text,
      'student_number': int.tryParse(studentNumberController.text) ?? 0,
      'year': selectedYear,
      // نرسل اسم التخصص المختار ضمن قائمة (لو API يتوقع قائمة أو اسم واحد)
      'specialties': selectedSpecialty != null ? [selectedSpecialty] : [],
    };

    try {
      var response = await dio.put(
        'http://localhost:8000/api/subject/${widget.subjectId}',
        data: json.encode(updatedData),
        options: Options(headers: headers, contentType: 'application/json'),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print(response);
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المادة بنجاح')),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الاتصال: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل المادة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isLoading ? null : saveSubjectData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المادة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: studentNumberController,
                    decoration: const InputDecoration(
                      labelText: 'عدد الطلاب',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'المستوى',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(5, (index) {
                      int year = index + 1;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(mapYearToLevel(year)),
                      );
                    }),
                    onChanged: (val) {
                      setState(() {
                        selectedYear = val;
                        // اذا غيرت المستوى وانتقل الى مستوى غير 5، نلغي التخصص المختار
                        if (val != 5) selectedSpecialty = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedYear == 5)
                    DropdownButtonFormField<String>(
                      value: selectedSpecialty,
                      decoration: const InputDecoration(
                        labelText: 'الاختصاص',
                        border: OutlineInputBorder(),
                      ),
                      items: allSpecialties.isNotEmpty
                          ? allSpecialties
                              .map<DropdownMenuItem<String>>((item) {
                              return DropdownMenuItem<String>(
                                value: item['name'],
                                child: Text(item['name']),
                              );
                            }).toList()
                          : [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('لا توجد اختصاصات'),
                              )
                            ],
                      onChanged: (val) {
                        setState(() {
                          selectedSpecialty = val;
                        });
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
