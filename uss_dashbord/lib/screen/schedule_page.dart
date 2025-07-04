import 'dart:convert';
import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisionAssignment {
  final String supervisor;
  final String date;
  final String day;
  final String time;
  final String hall;
  final List<String> courses;
  final int totalStudents;

  SupervisionAssignment({
    required this.supervisor,
    required this.date,
    required this.day,
    required this.time,
    required this.hall,
    required this.courses,
    required this.totalStudents,
  });

  factory SupervisionAssignment.fromJson(Map<String, dynamic> json) {
    return SupervisionAssignment(
      supervisor: json['supervisor'],
      date: json['date'],
      day: json['day'],
      time: json['time'],
      hall: json['hall'],
      courses: List<String>.from(json['courses']),
      totalStudents: json['total_students'],
    );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Map<String, Map<String, Map<String, Map<String, dynamic>>>>? scheduleData;
  bool isLoading = false;
  String? errorMessage;
  List<dynamic> assignmentsList = [];
  Map<String, dynamic> tasksData = {};
  bool isSaving = false;
  @override
  void initState() {
    super.initState();
    fetchStructuredDistribution(); // جلب التوزيع تلقائيًا
  }

  Future<void> fetchStructuredDistribution() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      var headers = {'Authorization': 'Bearer $token'};
      var dio = Dio();
      var response = await dio.request(
        'http://localhost:8000/api/distribution',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        final structured =
            response.data['structured_distribution'] as Map<String, dynamic>;

        final result =
            <String, Map<String, Map<String, Map<String, dynamic>>>>{};

        structured.forEach((dayKey, timeMap) {
          result[dayKey] = {};
          (timeMap as Map<String, dynamic>).forEach((time, hallsMap) {
            result[dayKey]![time] = {};
            (hallsMap as Map<String, dynamic>).forEach((hall, details) {
              final subjects = List<String>.from(details['subjects'] ?? []);
              final supervisors =
                  List<String>.from(details['supervisors'] ?? []);

              result[dayKey]![time]![hall] = {
                'supervisor': supervisors.isNotEmpty ? supervisors.first : null,
                'materials': {
                  for (var subject in subjects)
                    subject: 0, // عدد الطلاب غير موجود
                },
              };
            });
          });
        });

        setState(() {
          scheduleData = result;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.statusMessage;
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

 // 1. أولاً: أضف هذه الدالة في كلاس _SchedulePageState
Future<void> sendDistribution(
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> data) async {
  try {
    // يمكنك هنا إرسال البيانات إلى مكان آخر أو حفظها
    print('تم إرسال توزيع الجدول بنجاح');
    print('عدد الأيام في الجدول: ${data.length}');
  } catch (e) {
    print('حدث خطأ أثناء إرسال التوزيع: $e');
  }
}

// 2. ثانياً: تعديل دالة fetchData
Future<void> fetchData() async {
  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    final url = Uri.parse('http://localhost:8002/generate-full-schedule');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('فشل في جلب البيانات: ${response.statusCode}');
    }

    final decoded = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decoded) as Map<String, dynamic>;

    // تحقق من وجود الحقول الأساسية
    if (!data.containsKey('schedule_distribution') || 
        !data.containsKey('supervision_assignment')) {
      throw Exception('بيانات غير مكتملة من السيرفر');
    }

    final schedule = data['schedule_distribution'] as Map<String, dynamic>;
    final assignmentsList = data['supervision_assignment'] as List;

    final assignments = assignmentsList
        .map((e) => SupervisionAssignment.fromJson(e))
        .toList();

    final result = <String, Map<String, Map<String, Map<String, dynamic>>>>{};

    // معالجة تكليفات المراقبين
    for (final a in assignments) {
      final fullDayKey = '${a.day} (${a.date})';
      result.putIfAbsent(fullDayKey, () => {});
      result[fullDayKey]!.putIfAbsent(a.time, () => {});
      result[fullDayKey]![a.time]!.putIfAbsent(
        a.hall,
        () => {
          'supervisor': a.supervisor,
          'courses': a.courses,
          'total_students': a.totalStudents,
          'materials': <String, int>{},
        },
      );
    }

    // معالجة توزيع الجدول
    schedule.forEach((datetimeKey, courseMap) {
      final regex = RegExp(
        r'(\d{4}-\d{2}-\d{2}) (\w+)(?: at)? (\d{1,2}(?:AM|PM))',
        caseSensitive: false,
      );
      final match = regex.firstMatch(datetimeKey);

      if (match == null) {
        print('تنسيق التاريخ غير صحيح: $datetimeKey');
        return;
      }

      final date = match.group(1)!;
      final day = match.group(2)!;
      final time = match.group(3)!;
      final fullDayKey = '$day ($date)';

      (courseMap as Map<String, dynamic>).forEach((course, hallsData) {
        (hallsData as Map<String, dynamic>).forEach((hall, studentCount) {
          result.putIfAbsent(fullDayKey, () => {});
          result[fullDayKey]!.putIfAbsent(time, () => {});
          result[fullDayKey]![time]!.putIfAbsent(
            hall,
            () => {
              'supervisor': null,
              'courses': [],
              'total_students': 0,
              'materials': <String, int>{},
            },
          );

          result[fullDayKey]![time]![hall]!['materials'][course] = 
              (studentCount as num).toInt();
        });
      });
    });

    setState(() {
      scheduleData = result;
      isLoading = false;
    });

   
  } catch (e, stackTrace) {
    final errorMsg = 'حدث خطأ: ${e.toString()}';
    print('Error Details: $errorMsg');
    print('Stack Trace: $stackTrace');
    
    setState(() {
      errorMessage = errorMsg;
      isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }
}
void _validateFullData(Map<String, dynamic> data) {
  // التحقق من الجدول الزمني
  if (data['schedule_distribution'] == null || 
      data['schedule_distribution'].isEmpty) {
    throw Exception('بيانات الجدول الزمني غير صالحة');
  }

  // التحقق من تكليفات المراقبين
  if (data['supervision_assignment'] == null || 
      data['supervision_assignment'].isEmpty) {
    throw Exception('بيانات تكليفات المراقبين غير صالحة');
  }

  // التحقق من مهام المراقبة
  if (data['supervision_tasks'] == null || 
      data['supervision_tasks'].isEmpty) {
    throw Exception('بيانات مهام المراقبة غير صالحة');
  }
}
Future<void> senddistribution(Map<String, Object?> fullData) async {
  try {
    // التحقق من وجود البيانات الأساسية
    if (scheduleData!.isEmpty || assignmentsList.isEmpty || tasksData.isEmpty) {
      throw Exception('بيانات غير مكتملة');
    }

    setState(() => isSaving = true);

    // تحضير هيكل البيانات النهائي
    final requestData = {
      'status': 'ok',
      'schedule_distribution': scheduleData,
      'supervision_assignment': assignmentsList,
      'supervision_tasks': tasksData,
      'metadata': {
        'generated_at': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
      },
    };

    // التحقق من صحة البيانات
    _validateFullData(requestData);

    // الحصول على token
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) throw Exception('لم يتم العثور على token');

    // إعداد وإرسال الطلب
    final dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000',
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ));

    final response = await dio.post(
      '/api/distribution',
      data: jsonEncode(requestData),
    );

    if (response.statusCode != 201) {
      throw Exception('فشل في الحفظ: ${response.statusCode}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم الحفظ بنجاح')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ: ${e.toString()}')),
    );
    rethrow;
  } finally {
    if (mounted) setState(() => isSaving = false);
  }
}
void _validateScheduleData(Map<String, dynamic> data) {
  // 1. التحقق من أن البيانات ليست فارغة
  if (data.isEmpty) {
    throw Exception('بيانات الجدول فارغة');
  }

  // 2. التحقق من كل يوم في الجدول
  data.forEach((dayKey, dayData) {
    if (dayData == null || dayData is! Map) {
      throw Exception('تنسيق غير صحيح لليوم $dayKey');
    }

    // 3. التحقق من كل فترة زمنية
    dayData.forEach((timeSlot, hallData) {
      if (hallData == null || hallData is! Map) {
        throw Exception('تنسيق غير صحيح للفترة $timeSlot في اليوم $dayKey');
      }

      // 4. التحقق من بيانات كل قاعة
      hallData.forEach((hall, details) {
        if (details == null || details is! Map) {
          throw Exception('تنسيق غير صحيح للقاعة $hall في الفترة $timeSlot');
        }

        // 5. التحقق من وجود المشرف والمواد
        if (details['supervisor'] == null || details['materials'] == null) {
          throw Exception('بيانات ناقصة للقاعة $hall');
        }
      });
    });
  });
}
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = scheduleData?.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'توزيع الامتحانات',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.blue),
        backgroundColor: Color.fromARGB(255, 50, 50, 65),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('توزيع'),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text('حدث خطأ: $errorMessage',
                      style: const TextStyle(color: Colors.red)))
              : scheduleData == null
                  ? const Center(child: Text('اضغط على زر "توزيع" لبدء الحساب'))
                  : buildScheduleTable(scheduleData!, theme),
    );
  }

  Widget buildScheduleTable(
    Map<String, Map<String, Map<String, Map<String, dynamic>>>> data,
    ThemeData theme,
  ) {
    final days = data.keys.toList();

    return DefaultTabController(
      length: days.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: theme.primaryColor,
            tabs: days.map((day) => Tab(text: day)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: days.map((day) {
                final times = data[day]!.keys.toList()..sort();
                final halls = <String>{
                  for (var t in data[day]!.values) ...t.keys
                }.toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 30,
                    columns: [
                      const DataColumn(label: Text('القاعة')),
                      ...times.map((time) => DataColumn(label: Text(time))),
                    ],
                    rows: halls.map((hall) {
                      return DataRow(cells: [
                        DataCell(Text(hall)),
                        ...times.map((time) {
                          final entry = data[day]?[time]?[hall];
                          if (entry == null) {
                            return const DataCell(Text('-'));
                          }

                          final supervisor = entry['supervisor'];
                          final materials =
                              entry['materials'] as Map<String, int>;

                          return DataCell(
                            SizedBox(
                              width: 120, // عرض ثابت أو اختياري
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (supervisor != null)
                                      Text(
                                        ' $supervisor',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                    ...materials.entries.map((e) => Text(
                                          ' ${e.key}:  ${e.value}',
                                          style: const TextStyle(fontSize: 12),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ]);
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
ElevatedButton(
  onPressed: () async {
    if (scheduleData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد بيانات لحفظها')),
      );
      return;
    }
    
    await senddistribution(data);
  },
  child: isSaving
      ? const CircularProgressIndicator()
      : const Text('حفظ التغييرات'),
),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<UserCubit>().resetdistribution(context);
                },
                child: const Text('تصفير الجدول'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
