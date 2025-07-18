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
  Map<String, Map<String, Map<String, Map<String, dynamic>>>> scheduleData = {};

  bool isLoading = false;
  String? errorMessage;
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
        print(response.data['structured_distribution'].runtimeType);
        print(response.data['structured_distribution']);

        final rawStructured = response.data['structured_distribution'];

        if (rawStructured is! Map<String, dynamic>) {
          print("⚠️ Error: structured_distribution is not a map");
          setState(() {
            errorMessage = 'اضغط على زر "توزيع" لبدء الحساب';
            isLoading = false;
          });
          return;
        }

        final structured = rawStructured as Map<String, dynamic>;

        final result =
            <String, Map<String, Map<String, Map<String, dynamic>>>>{};

        structured.forEach((dayKey, timeMap) {
          result[dayKey] = {};
          (timeMap as Map<String, dynamic>).forEach((time, hallsMap) {
            result[dayKey]![time] = {};
            (hallsMap as Map<String, dynamic>).forEach((hall, details) {
              final subjectList = details['subjects'] as List<dynamic>? ?? [];
              final supervisors =
                  List<String>.from(details['supervisors'] ?? []);

              // تحويل المواد إلى خريطة: name => students_number
              final materials = <String, int>{};
              for (var subject in subjectList) {
                if (subject is Map<String, dynamic>) {
                  final name = subject['name'] as String? ?? 'غير معروف';
                  final students = subject['students_number'] as int? ?? 0;
                  materials[name] = students;
                }
              }

              result[dayKey]![time]![hall] = {
                'supervisor': supervisors.isNotEmpty ? supervisors.first : null,
                'materials': materials,
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

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse('http://localhost:8002/generate-full-schedule');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        print(response.bodyBytes);
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${utf8.decode(response.bodyBytes)}');

        throw Exception('فشل في جلب البيانات من السيرفر');
      }
      final decoded = utf8.decode(response.bodyBytes);
      print(decoded); // قبل jsonDecode

      final data = jsonDecode(decoded);
      final schedule = data['schedule_distribution'] as Map<String, dynamic>;
      final assignmentsList = data['supervision_assignment'] as List;

      final assignments = assignmentsList
          .map((e) => SupervisionAssignment.fromJson(e))
          .toList();

      final result = <String, Map<String, Map<String, Map<String, dynamic>>>>{};

      for (var a in assignments) {
        final fullDayKey = '${a.day} (${a.date})';
        result.putIfAbsent(fullDayKey, () => {});
        result[fullDayKey]!.putIfAbsent(a.time, () => {});
        result[fullDayKey]![a.time]!.putIfAbsent(
            a.hall,
            () => {
                  'supervisor': a.supervisor,
                  'materials': <String, int>{},
                });
        // إذا كانت القاعة موجودة، لكن لم يكن هناك مراقب، نضيفه الآن
        result[fullDayKey]![a.time]![a.hall]!['supervisor'] = a.supervisor;
      }

      schedule.forEach((datetimeKey, courseMap) {
        // أمثلة محتملة: "2025-06-27 Friday at 8AM" أو "2025-06-27 Friday 8AM"
        final regex =
            RegExp(r'(\d{4}-\d{2}-\d{2}) (\w+)(?: at)? (\d{1,2}(?:AM|PM))');
        final match = regex.firstMatch(datetimeKey);

        if (match == null) return;

        final date = match.group(1)!;
        final day = match.group(2)!;
        final time = match.group(3)!;
        final fullDayKey = '$day ($date)';

        courseMap.forEach((course, hallsData) {
          (hallsData as Map<String, dynamic>).forEach((hall, studentCount) {
            result.putIfAbsent(fullDayKey, () => {});
            result[fullDayKey]!.putIfAbsent(time, () => {});
            result[fullDayKey]![time]!.putIfAbsent(
                hall,
                () => {
                      'supervisor': null,
                      'materials': <String, int>{},
                    });

            final mat = result[fullDayKey]![time]![hall]!['materials']
                as Map<String, int>;
            mat[course] = studentCount;
          });
        });
      });
      // ignore: avoid_print
      print(jsonEncode(result));

      setState(() {
        scheduleData = result;
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> buildRequestPayload(Map<String, dynamic> schedule) {
    final scheduleDistribution = <String, Map<String, Map<String, int>>>{};
    final supervisionAssignment = <Map<String, dynamic>>[];
    final supervisionTasks = <String, int>{};

    schedule.forEach((dayWithDate, times) {
      final dayMatch =
          RegExp(r'^(\w+)\s+\(([\d-]+)\)$').firstMatch(dayWithDate);
      if (dayMatch == null) return;

      final day = dayMatch.group(1)!;
      final date = dayMatch.group(2)!;

      (times as Map<String, dynamic>).forEach((time, halls) {
        final scheduleKey = "$date $day $time";
        final courseMap = <String, Map<String, int>>{};

        (halls as Map<String, dynamic>).forEach((hall, info) {
          final supervisor = info['supervisor'] ?? 'غير معروف';
          final materials = info['materials'] as Map<String, dynamic>;

          // لتجميع بيانات المواد ضمن schedule_distribution
          materials.forEach((course, students) {
            courseMap.putIfAbsent(course, () => {});
            courseMap[course]![hall] = students;
          });

          // لتجميع بيانات الإشراف supervision_assignment
          supervisionAssignment.add({
            'supervisor': supervisor,
            'date': date,
            'day': day,
            'time': time,
            'hall': hall,
            'courses': materials.keys.toList(),
            'total_students':
                materials.values.fold(0, (a, b) => (a + b).toInt()),
          });

          // لتجميع عدد مهام كل مشرف
          supervisionTasks.update(supervisor, (value) => value + 1,
              ifAbsent: () => 1);
        });

        scheduleDistribution[scheduleKey] = courseMap;
      });
    });

    return {
      'status': 'ok',
      'schedule_distribution': scheduleDistribution,
      'supervision_assignment': supervisionAssignment,
      'supervision_tasks': supervisionTasks,
    };
  }

  Future<void> senddistribution(Map<String, dynamic> scheduleData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final dio = Dio();
    final payload = buildRequestPayload(scheduleData);

    try {
      final response = await dio.post(
        'http://localhost:8000/api/distribution',
        options: Options(headers: headers),
        data: payload,
      );

      print('✅ Success: ${response.data}');
    } on DioException catch (e) {
      if (e.response != null) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Error Response: ${e.response?.data}');
      } else {
        print('❌ Dio Error: ${e.message}');
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
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
              child: const Text(
                'توزيع',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
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
              : (scheduleData.isEmpty)
                  ? const Center(child: Text('اضغط على زر "توزيع" لبدء الحساب'))
                  : buildScheduleTable(scheduleData, theme),
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
            indicatorColor: Colors.white,
            unselectedLabelColor: Colors.white,
            labelColor: Colors.white,
            isScrollable: true,
            tabs: days.map((day) => Tab(text: day)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: days.map((day) {
                final times = data[day]!.keys.toList()..sort();
                final halls = <String>{
                  for (var t in data[day]!.values) ...t.keys
                }.toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                            columnSpacing: 20, // تقليل التباعد بين الأعمدة
                            headingRowHeight: 60, // زيادة ارتفاع رأس الجدول
                            dataRowMinHeight: 40, // الحد الأدنى لارتفاع الصف
                            dataRowMaxHeight:
                                double.infinity, // السماح للصفوف بالتوسع
                            columns: [
                              const DataColumn(
                                label: Text(
                                  'القاعة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // زيادة حجم خط الرأس
                                  ),
                                ),
                                tooltip: 'أسماء القاعات',
                              ),
                              ...times.map(
                                (time) => DataColumn(
                                  label: Text(
                                    time,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14, // زيادة حجم خط الرأس
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            rows: halls.map((hall) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      constraints:
                                          const BoxConstraints(minWidth: 80),
                                      child: Text(
                                        hall,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14, // زيادة حجم خط الخلايا
                                        ),
                                      ),
                                    ),
                                  ),
                                  ...times.map((time) {
                                    final entry = data[day]?[time]?[hall];
                                    if (entry == null) {
                                      return const DataCell(
                                        Text(
                                          '-',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    }

                                    final supervisor =
                                        entry['supervisor'] ?? '';
                                    final materialsRaw = entry['materials']
                                            as Map<String, dynamic>? ??
                                        {};

                                    final materials = materialsRaw.map((k, v) {
                                      int val = 0;
                                      if (v is int) {
                                        val = v;
                                      } else if (v is String) {
                                        val = int.tryParse(v) ?? 0;
                                      }
                                      return MapEntry(k, val);
                                    });

                                    return DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 8),
                                        constraints: const BoxConstraints(
                                          minWidth:
                                              120, // زيادة الحد الأدنى لعرض الخلية
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (supervisor.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                  supervisor,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        14, // زيادة حجم الخط
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ...materials.entries.map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4),
                                                child: Text(
                                                  '${e.key}: ${e.value}',
                                                  style: const TextStyle(
                                                    fontSize:
                                                        14, // زيادة حجم الخط
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
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
                  try {
                    await senddistribution(scheduleData);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الجدول بنجاح')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('حدث خطأ أثناء حفظ الجدول: $e')),
                    );
                    print(e);
                  }
                },
                child: const Text('حفظ التغييرات'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<UserCubit>().resetDistribution(context);
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
