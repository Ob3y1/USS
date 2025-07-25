import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:exam_dashboard/Edit/EditDataentryPage.dart';
import 'package:exam_dashboard/Edit/EditExamDayPage.dart';
import 'package:exam_dashboard/Edit/EditExamTimePage%20.dart';
import 'package:exam_dashboard/Edit/EditHallPage.dart';
import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminDataEntryScreen extends StatefulWidget {
  const AdminDataEntryScreen({super.key});

  @override
  State<AdminDataEntryScreen> createState() => _AdminDataEntryScreenState();
}

class _AdminDataEntryScreenState extends State<AdminDataEntryScreen> {
  List<Map<String, String>> examDays = [];
  List<Map<String, String>> specialties = [];

  String? selectedSpecialization;

  List<Map<String, dynamic>> halls = [];
  // Controllers للمواد
  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController subjectStudentsController =
      TextEditingController();
  bool isLoading = false;
  // قائمة المواد (المواد المخزنة)
  List<Map<String, String>> subjects = [];
  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  TextEditingController examDateController = TextEditingController();
  DateTime date = DateTime.now();
  String? selectedDay; // هنا نخزن اليوم بالإنجليزية مثلاً
  @override
  void initState() {
    super.initState();
    fetchSubjectsFromApi();
  }

  Future<void> fetchSubjectsFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      isLoading = true;
    });

    try {
      var dio = Dio();
      var headers = {'Authorization': 'Bearer $token'};
      var response = await dio.get(
        'http://localhost:8000/api/dash2',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        List subjectsFromApi = response.data['subjects'];
        List hallsFromApi = response.data['halls'];
        List examDaysFromApi = response.data['examDays'];
        List examTimesFromApi = response.data['examTimes'];
        List specialtiesFromApi = response.data['specialties'];

        setState(() {
          // معالجة المواد
          subjects = subjectsFromApi.map<Map<String, String>>((subject) {
            return {
              'id': subject['id'].toString(),
              'name': subject['name'] ?? '',
              'students': subject['student_number'].toString(),
              'level': mapYearToLevel(subject['year']),
              'specialization': subject['specialties'] != null &&
                      subject['specialties'].isNotEmpty
                  ? subject['specialties'][0]['name'] ?? ''
                  : '',
            };
          }).toList();

          // معالجة القاعات
          rooms = hallsFromApi.map<Map<String, String>>((hall) {
            return {
              'id': hall['id'].toString(),
              'name': hall['location'] ?? '',
              'capacity': hall['chair_number'].toString(),
              'camera': (hall['cameras'] as List<dynamic>)
                  .map((cam) => cam['address'].toString())
                  .join(', '),
            };
          }).toList();
          examDays = examDaysFromApi.map<Map<String, String>>((day) {
            return {
              'id': day['id'].toString(),
              'day': day['day'] ?? '',
              'date': day['date'] ?? '',
            };
          }).toList();
          examTimes = examTimesFromApi.map<Map<String, String>>((time) {
            return {
              'id': time['id'].toString(),
              'time': time['time'] ?? '',
            };
          }).toList();

          specialties =
              specialtiesFromApi.map<Map<String, String>>((specialty) {
            return {
              'id': specialty['id'].toString(),
              'name': specialty['name'] ?? '',
            };
          }).toList();

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to load subjects or halls: ${response.statusMessage}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSubjectById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      var headers = {
        'Authorization': 'Bearer $token',
      };
      var dio = Dio();
      var response = await dio.request(
        'http://localhost:8000/api/subject/$id',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        print('Error: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      print('Exception: $e');
      return null;
    }
  }

  // دالة مساعدة لتحويل الرقم إلى اسم المستوى
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
        return '';
    }
  }

  // قيم اختيار المستوى والاختصاص
  String? selectedLevel;

  // قائمة المستويات الخمسة
  final List<String> levels = [
    'المستوى الأول',
    'المستوى الثاني',
    'المستوى الثالث',
    'المستوى الرابع',
    'المستوى الخامس',
  ];

  // قائمة الاختصاصات التي تظهر فقط عند اختيار المستوى الخامس
  final List<String> specializations = [
    'اختصاص 1',
    'اختصاص 2',
    'اختصاص 3',
  ];

  void addSubject() {
    if (subjectNameController.text.isEmpty ||
        subjectStudentsController.text.isEmpty ||
        selectedLevel == null) {
      // يمكنك عرض رسالة خطأ أو تنبيه هنا
      return;
    }
    // إذا كان المستوى الخامس يجب اختيار اختصاص
    if (selectedLevel == 'المستوى الخامس' && selectedSpecialization == null) {
      // رسالة خطأ أو تنبيه
      return;
    }

    setState(() {
      subjects.add({
        'id': (subjects.length + 1).toString(),
        'name': subjectNameController.text,
        'students': subjectStudentsController.text,
        'level': selectedLevel!,
        'specialization':
            selectedLevel == 'المستوى الخامس' ? selectedSpecialization! : '',
      });

      // تنظيف الحقول
      subjectNameController.clear();
      subjectStudentsController.clear();
      selectedLevel = null;
      selectedSpecialization = null;
    });
  }

  // Controllers للقاعات
  final roomNameController = TextEditingController();
  final roomCapacityController = TextEditingController();
  List<TextEditingController> roomCameraControllers = [TextEditingController()];
  var rooms = <Map<String, String>>[];

  void addRoom() {
    setState(() {
      rooms.add({
        'id': (rooms.length + 1).toString(),
        'name': roomNameController.text,
        'capacity': roomCapacityController.text,
        // دمج عناوين الكاميرات في نص مفصول بفواصل
        'camera': roomCameraControllers
            .map((c) => c.text)
            .where((text) => text.isNotEmpty)
            .join(', '),
      });

      // مسح الحقول
      roomNameController.clear();
      roomCapacityController.clear();
      for (var c in roomCameraControllers) {
        c.dispose();
      }
      roomCameraControllers = [TextEditingController()];
    });
  }

  // Controllers للأوقات
  final examDayController = TextEditingController();

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, String>> examTimes = [];

  String _getWeekDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      default:
        return '';
    }
  }

  void addExamTime() {
    setState(() {
      examTimes.add({
        'id': (examTimes.length + 1).toString(),
        'day': _getWeekDayName(date.weekday),
        'date': examDateController.text,
      });
      examDateController.text = _formatDate(date);
    });
  }

  final examPeriodFromController = TextEditingController();
  final examPeriods = <Map<String, String>>[];
  void addExamPeriod() {
    setState(() {
      examPeriods.add({
        'id': (examPeriods.length + 1).toString(),
        'from': examPeriodFromController.text,
      });
      examPeriodFromController.clear();
    });
  }

  Widget buildSection({
    required String title,
    required List<Widget> fields,
    required VoidCallback onAdd,
    required List<DataColumn> columns,
    required List<DataRow> rows,
  }) {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// الإدخال
          Expanded(
            flex: 1,
            child: Container(
              height: 400,
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // خلفية بيضاء بدل الداكن
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.7), // ظل خفيف
                    blurRadius: 8,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    ...fields,
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          onAdd(); // أضف المشرف أو أي كيان آخر
                          await fetchSubjectsFromApi(); // إعادة جلب المواد بعد الإضافة
                          context
                              .read<UserCubit>()
                              .subjectNameController
                              .clear();
                          context
                              .read<UserCubit>()
                              .subjectStudentsController
                              .clear();
                          context
                              .read<UserCubit>()
                              .roomCapacityController
                              .clear();
                          context.read<UserCubit>().examDateController.clear();
                          context
                              .read<UserCubit>()
                              .examPeriodFromController
                              .clear();
                          context.read<UserCubit>().roomNameController.clear();
                          context
                              .read<UserCubit>()
                              .roomCameraControllers
                              .clear();
                        },
                        child: const Text(
                          'إضافة',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),

          /// العرض
          Expanded(
            flex: 2,
            child: Container(
              height: 400,
              margin: const EdgeInsets.only(bottom: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, // خلفية بيضاء بدل الداكن
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.7), // ظل خفيف
                    blurRadius: 8,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '$title',
                    style: const TextStyle(
                      color: Colors.black87, // تغيير لون النص إلى الأسود
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const Divider(thickness: 2, color: Colors.black87),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing:
                              60, // ضبط المسافة بين الأعمدة حسب الحاجة
                          columns: columns,
                          rows: rows,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('إدخال البيانات',
            style: TextStyle(
              color: Colors.black87, // تغيير لون النص إلى الأسود
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            )),
        elevation: 1, // ظل خفيف للتمييز
        iconTheme: const IconThemeData(color: Colors.blue),
        backgroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// المواد
            buildSection(
              title: 'بيانات مادة امتحانية',
              fields: [
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: context.read<UserCubit>().subjectNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم المادة',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller:
                      context.read<UserCubit>().subjectStudentsController,
                  decoration: const InputDecoration(
                    labelText: 'عدد الطلاب',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(
                  height: 20,
                ),
                // هنا نستبدل TextField الخاص بالمستوى بـ DropdownButtonFormField
                DropdownButtonFormField<String>(
                  value: context.read<UserCubit>().selectedLevel,
                  items: levels.map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    context.read<UserCubit>().setSelectedLevel(value);
                    setState(() {}); // لتحديث الواجهة بعد التغيير
                  },
                  decoration: const InputDecoration(
                    labelText: 'المستوى',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white),
                ),

// إظهار اختيار الاختصاص فقط إذا المستوى هو المستوى الخامس
                if (context.read<UserCubit>().selectedLevel == 'المستوى الخامس')
                  DropdownButtonFormField<String>(
                    value: context.read<UserCubit>().selectedSpecializationId,
                    items: specialties.map((spec) {
                      return DropdownMenuItem<String>(
                        value: spec['id'], // استخدام المعرف وليس الاسم
                        child: Text(spec['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        context.read<UserCubit>().selectedSpecializationId =
                            value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'الاختصاص',
                      labelStyle: TextStyle(color: Colors.black87),
                    ),
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                  ),
              ],
              onAdd: context.read<UserCubit>().addSubject,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 75,
                    child: Text('ID',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 75,
                    child: Text('الاسم',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 75,
                    child: Text('عدد الطلاب',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 75,
                    child: Text('المستوى',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 75,
                    child: Text('الاختصاص',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                    label: SizedBox(
                        height: 70,
                        width: 75,
                        child: Text('تعديل',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
                DataColumn(
                    label: SizedBox(
                        height: 70,
                        width: 75,
                        child: Text('حذف',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
              ],
              rows: subjects
                  .map((s) => DataRow(cells: [
                        DataCell(
                          SizedBox(
                            height: 70,
                            width: 85,
                            child: Text(s['id'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 18)),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            height: 70,
                            width: 85,
                            child: Text(s['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 18)),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            height: 70,
                            width: 85,
                            child: Text(s['students'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 18)),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            height: 70,
                            width: 85,
                            child: Tooltip(
                              message: s['level'] ?? '',
                              child: Text(
                                s['level'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            height: 70,
                            width: 85,
                            child: Tooltip(
                              message: s['specialization'] ?? '',
                              child: Text(
                                s['specialization'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubjectDetailsPage(
                                      subjectId: int.parse(s['id'].toString())),
                                ),
                              );
                            },
                          ),
                        ),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.blue),
                            onPressed: () async {
                              final subjectId = s['id'];
                              context
                                  .read<UserCubit>()
                                  .deleteSubject(subjectId as String);
                              await fetchSubjectsFromApi();
                            },
                          ),
                        ),
                      ]))
                  .toList(),
            ),

            /// القاعات
            buildSection(
              title: 'بيانات القاعة',
              fields: [
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: context.read<UserCubit>().roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم القاعة',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: context.read<UserCubit>().roomCapacityController,
                  decoration: const InputDecoration(
                    labelText: 'سعة القاعة',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(
                  height: 20,
                ),
                // هنا استبدلنا TextField واحد بعمود يحوي حقول متعددة
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'عناوين الكاميرات',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    ...context
                        .read<UserCubit>()
                        .roomCameraControllers
                        .map((controller) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: TextField(
                                controller: controller, // هنا
                                decoration: const InputDecoration(
                                  labelText: 'عنوان الكاميرا',
                                  labelStyle: TextStyle(color: Colors.black87),
                                ),
                                style: const TextStyle(color: Colors.black87),
                              ),
                            )),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          roomCameraControllers.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة كاميرا'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),
              ],
              onAdd: context.read<UserCubit>().sendHallData,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 60,
                    child: Text('ID',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 60,
                    child: Text('اسم القاعة',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 60,
                    child: Text('السعة',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    height: 70,
                    width: 60,
                    child: Text('الكاميرا',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                    label: SizedBox(
                        height: 70,
                        width: 60,
                        child: Text('تعديل',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
                DataColumn(
                    label: SizedBox(
                        height: 70,
                        width: 60,
                        child: Text('حذف',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
              ],
              rows: rooms
                  .map(
                    (r) => DataRow(cells: [
                      DataCell(
                        SizedBox(
                          height: 70,
                          width: 100,
                          child: Text(r['id'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 18)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          height: 70,
                          width: 100,
                          child: Text(r['name'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 18)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          height: 70,
                          width: 100,
                          child: Text(r['capacity'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 18)),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          height: 70,
                          width: 100,
                          child: Tooltip(
                            message: r['camera'] ?? '',
                            child: Text(
                              r['camera'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditHallPage(
                                    hallId: int.parse(r['id'].toString())),
                              ),
                            );
                          },
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.blue),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('token');

                            var dio = Dio();
                            var headers = {
                              'Authorization': 'Bearer $token',
                              'Content-Type': 'application/json',
                            };

                            try {
                              var response = await dio.delete(
                                'http://localhost:8000/api/halls/${r['id']}',
                                options: Options(headers: headers),
                              );

                              if (response.statusCode == 200) {
                                print(json.encode(response.data));
                              } else {
                                print('حدث خطأ: ${response.statusMessage}');
                              }
                            } catch (error) {
                              print('خطأ في الاتصال أو الحذف: $error');
                            }
                            await fetchSubjectsFromApi();
                          },
                        ),
                      ),
                    ]),
                  )
                  .toList(),
            ),

            /// أوقات الامتحان
            buildSection(
              title: 'أيام الامتحان',
              fields: [
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller: context.read<UserCubit>().examDateController,
                  decoration: const InputDecoration(
                    labelText: 'اليوم و التاريخ',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  style: const TextStyle(color: Colors.black87),
                  readOnly: true,
                  onTap: () async {
                    DateTime? newDate = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(1500),
                      lastDate: DateTime(2500),
                    );
                    if (newDate != null) {
                      setState(() {
                        date = newDate;
                        // عوضًا عن examDateController.text الذي قد يكون غير معرف محليًا، استخدم الـ cubit:
                        context.read<UserCubit>().examDateController.text =
                            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        // تحديث اليوم بالإنجليزية داخل الـ cubit
                        context.read<UserCubit>().selectedDay =
                            _getDayName(date.weekday);
                      });
                    }
                  },
                ),
              ],
              onAdd: context.read<UserCubit>().sendExamDay,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text('ID',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('اليوم',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('التاريخ',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                    label: SizedBox(
                        width: 150,
                        child: Text('تعديل',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
                DataColumn(
                    label: SizedBox(
                        width: 150,
                        child: Text('حذف',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
              ],
              rows: examDays.map((e) {
                return DataRow(cells: [
                  DataCell(SizedBox(
                    width: 100,
                    child: Text(e['id'] ?? '',
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  )),
                  DataCell(SizedBox(
                    width: 150,
                    child: Text(e['day'] ?? '',
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  )),
                  DataCell(SizedBox(
                    width: 150,
                    child: Text(e['date'] ?? '',
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  )),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token');
                        var headers = {
                          'Authorization': 'Bearer $token',
                        };
                        var dio = Dio();
                        var response = await dio.request(
                          'http://localhost:8000/api/exam-day/${e['id']}',
                          options: Options(
                            method: 'GET',
                            headers: headers,
                          ),
                        );

                        if (response.statusCode == 200) {
                          final examDay = response.data;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditExamDayPage(examDay: examDay),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل في جلب البيانات')),
                          );
                        }
                      },
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.blue),
                      onPressed: () async {
                        var dio = Dio();
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token');
                        // استبدل بالتوكن المناسب
                        var headers = {
                          'Authorization': 'Bearer $token',
                        };

                        try {
                          var response = await dio.delete(
                            'http://localhost:8000/api/exam-days/${e['id']}',
                            options: Options(headers: headers),
                          );

                          if (response.statusCode == 200) {
                            print(json.encode(response.data));
                            // ممكن تضيف هنا تحديث للواجهة أو عرض رسالة نجاح
                          } else {
                            print('حدث خطأ: ${response.statusMessage}');
                          }
                        } catch (e) {
                          print('خطأ في الاتصال أو الحذف: $e');
                        }
                        await fetchSubjectsFromApi();
                      },
                    ),
                  ),
                ]);
              }).toList(),
            ),
            buildSection(
              title: 'فترات الامتحانات',
              fields: [
                const SizedBox(
                  height: 20,
                ),
                TextField(
                  controller:
                      context.read<UserCubit>().examPeriodFromController,
                  decoration: const InputDecoration(
                    labelText: 'من',
                    labelStyle: TextStyle(color: Colors.black87),
                  ),
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
              onAdd: context.read<UserCubit>().sendExamTime,
              columns: const [
                DataColumn(
                  label: SizedBox(
                    width: 100,
                    child: Text('ID',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                  label: SizedBox(
                    width: 150,
                    child: Text('الوقت',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  ),
                ),
                DataColumn(
                    label: SizedBox(
                        width: 150,
                        child: Text('تعديل',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
                DataColumn(
                    label: SizedBox(
                        width: 150,
                        child: Text('حذف',
                            style: TextStyle(
                                color: Colors.black87, fontSize: 18)))),
              ],
              rows: examTimes.map((e) {
                return DataRow(cells: [
                  DataCell(SizedBox(
                    width: 100,
                    child: Text(e['id'] ?? '',
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  )),
                  DataCell(SizedBox(
                    width: 150,
                    child: Text(e['time'] ?? '',
                        style: TextStyle(color: Colors.black87, fontSize: 18)),
                  )),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token');
                        var headers = {
                          'Authorization': 'Bearer $token',
                        };

                        var dio = Dio();
                        try {
                          var response = await dio.request(
                            'http://localhost:8000/api/exam-time/${e['id']}',
                            options: Options(method: 'GET', headers: headers),
                          );

                          if (response.statusCode == 200) {
                            final examTime = response.data;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditExamTimePage(examTime: examTime),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('فشل في جلب وقت الامتحان')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('حدث خطأ: $e')),
                          );
                        }
                      },
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.blue),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token');

                        var dio = Dio();
                        var headers = {
                          'Authorization': 'Bearer $token',
                        };

                        try {
                          var response = await dio.delete(
                            'http://localhost:8000/api/exam-times/${e['id']}',
                            options: Options(headers: headers),
                          );

                          if (response.statusCode == 200) {
                            print(json.encode(response.data));
                            // هنا ممكن تضيف كود لتحديث الواجهة أو عرض رسالة نجاح
                          } else {
                            print('حدث خطأ: ${response.statusMessage}');
                          }
                        } catch (e) {
                          print('خطأ في الاتصال أو الحذف: $e');
                        }
                        await fetchSubjectsFromApi();
                      },
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
