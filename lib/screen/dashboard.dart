import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List specialties = [];
  List workingdays = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          error = 'لم يتم تسجيل الدخول. لا يوجد توكن.';
          isLoading = false;
        });
        return;
      }

      var dio = Dio();
      var response = await dio.get(
        'http://localhost:8000/api/dash1',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        setState(() {
          specialties = response.data['specialties'];
          workingdays = response.data['workingdays'];
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'فشل في تحميل البيانات';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ أثناء الاتصال بالخادم: $e';
        isLoading = false;
      });
    }
  }

  Future<void> addSpecialty(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var data = json.encode({
        "name": name,
      });

      var dio = Dio();
      var response = await dio.request(
        'http://localhost:8000/api/addspecialties',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 201) {
        // إعادة تحميل التخصصات من الخادم
        await fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة التخصص بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإضافة: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> updateSpecialty(int id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var dio = Dio();
      var response = await dio.put(
        'http://localhost:8000/api/specialties/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: json.encode({"name": name}),
      );

      if (response.statusCode == 200) {
        await fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل التخصص بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التعديل: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء التعديل: $e')),
      );
    }
  }

  Future<void> deleteSpecialty(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var dio = Dio();
      var response = await dio.delete(
        'http://localhost:8000/api/specialties/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف التخصص')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحذف: $e')),
      );
    }
  }

  void showSpecialtyDialog({int? id, String? initialName}) {
    final controller = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'إضافة تخصص' : 'تعديل التخصص'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اسم التخصص'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (id == null) {
                addSpecialty(controller.text);
              } else {
                updateSpecialty(id, controller.text);
              }
            },
            child: Text(id == null ? 'إضافة' : 'تعديل'),
          ),
        ],
      ),
    );
  }

  Future<void> addWorkingDay(String day) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var data = json.encode({
        "day": day,
      });

      var dio = Dio();
      var response = await dio.request(
        'http://localhost:8000/api/addWorkingDay',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 201) {
        await fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة يوم الدوام بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الإضافة: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> updateWorkingDay(int id, String day) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      var data = json.encode({
        "id": id,
        "day": day,
      });

      var dio = Dio();
      var response = await dio.request(
        'http://localhost:8000/api/working-days/$id',
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        await fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل اليوم بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التعديل: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  Future<void> deleteWorkingDay(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      var headers = {'Authorization': 'Bearer $token'};

      var dio = Dio();
      var response = await dio.delete(
        'http://localhost:8000/api/working-days/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        await fetchDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف يوم الدوام بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحذف: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')),
      );
    }
  }

  void showWorkingDayDialog({int? id, String? initialDay}) {
    final controller = TextEditingController(text: initialDay);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'إضافة يوم دوام' : 'تعديل يوم الدوام'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'اليوم'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (id == null) {
                addWorkingDay(controller.text);
              } else {
                updateWorkingDay(id, controller.text);
              }
            },
            child: Text(id == null ? 'إضافة' : 'تعديل'),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20)),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.blue),
          onPressed: onAdd,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
        title: const Text('لوحة تحكم مدير النظام',
            style: TextStyle(color: Colors.white, fontSize: 24)),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Text(error!,
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 18)),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        sectionTitle('التخصصات:', () => showSpecialtyDialog()),
                        const SizedBox(height: 8),
                        ...specialties.map((spec) => Card(
                              color: Colors.grey[850],
                              child: ListTile(
                                title: Text(
                                  spec["name"],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text('ID: ${spec["id"]}',
                                    style:
                                        const TextStyle(color: Colors.white60)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => showSpecialtyDialog(
                                          id: spec["id"],
                                          initialName: spec["name"]),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          deleteSpecialty(spec["id"]),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 24),
                        sectionTitle(
                            'أيام الدوام:', () => showWorkingDayDialog()),
                        const SizedBox(height: 8),
                        ...workingdays.map((day) => Card(
                              color: Colors.grey[850],
                              child: ListTile(
                                title: Text(
                                  day["day"],
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text('ID: ${day["id"]}',
                                    style:
                                        const TextStyle(color: Colors.white60)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () => showWorkingDayDialog(
                                          id: day["id"],
                                          initialDay: day["day"]),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          deleteWorkingDay(day["id"]),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
      ),
    );
  }
}
