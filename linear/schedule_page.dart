import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse('http://localhost:8002/generate-full-schedule');
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('فشل في جلب البيانات من السيرفر');
      }
      final decoded = utf8.decode(response.bodyBytes);

      final data = jsonDecode(decoded);
      final schedule = data['schedule_distribution'] as Map<String, dynamic>;
      final assignmentsList = data['supervision_assignment'] as List;

      final assignments =
          assignmentsList.map((e) => SupervisionAssignment.fromJson(e)).toList();

      final result = <String, Map<String, Map<String, Map<String, dynamic>>>>{};

      for (var a in assignments) {
        final fullDayKey = '${a.day} (${a.date})';
        result.putIfAbsent(fullDayKey, () => {});
        result[fullDayKey]!.putIfAbsent(a.time, () => {});
        result[fullDayKey]![a.time]!.putIfAbsent(a.hall, () => {
              'supervisor': a.supervisor,
              'materials': <String, int>{},
            });
        // إذا كانت القاعة موجودة، لكن لم يكن هناك مراقب، نضيفه الآن
        result[fullDayKey]![a.time]![a.hall]!['supervisor'] = a.supervisor;
      }

      schedule.forEach((datetimeKey, courseMap) {
      // أمثلة محتملة: "2025-06-27 Friday at 8AM" أو "2025-06-27 Friday 8AM"
      final regex = RegExp(r'(\d{4}-\d{2}-\d{2}) (\w+)(?: at)? (\d{1,2}(?:AM|PM))');
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
            result[fullDayKey]![time]!.putIfAbsent(hall, () => {
                  'supervisor': null,
                  'materials': <String, int>{},
                });

            final mat = result[fullDayKey]![time]![hall]!['materials'] as Map<String, int>;
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
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = scheduleData?.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('توزيع الامتحانات'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('حدث خطأ: $errorMessage', style: const TextStyle(color: Colors.red)))
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
                          final materials = entry['materials'] as Map<String, int>;

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
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
        ],
      ),
    );
  }
}
