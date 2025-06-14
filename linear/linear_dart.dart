import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ExamSchedulerApp());
}

class ExamSchedulerApp extends StatelessWidget {
  const ExamSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جدول الامتحانات',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SchedulePage(),
    );
  }
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool isLoading = false;
  String? error;

  Map<String, dynamic>? scheduleDistribution;
  List<dynamic>? supervisionAssignment;
  Map<String, dynamic>? supervisionTasks;

  Future<void> fetchSchedule() async {
    setState(() {
      isLoading = true;
      error = null;
      scheduleDistribution = null;
      supervisionAssignment = null;
      supervisionTasks = null;
    });

    try {
      // غير الرابط إلى رابط API الخاص بك
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/generate-full-schedule'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'ok') {
          setState(() {
            scheduleDistribution = data['schedule_distribution'];
            supervisionAssignment = data['supervision_assignment'];
            supervisionTasks = data['supervision_tasks'];
          });
        } else {
          setState(() {
            error = 'حدث خطأ في البيانات المستلمة';
          });
        }
      } else {
        setState(() {
          error = 'فشل الاتصال بالخادم: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        error = 'خطأ في الاتصال: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildScheduleTable() {
    if (scheduleDistribution == null || scheduleDistribution!.isEmpty) {
      return const Text('لا توجد بيانات لعرض جدول توزيع الطلاب.');
    }

    // الجدول: المفتاح (التاريخ + اليوم + الوقت) → المواد + توزيع الطلاب على القاعات
    List<Widget> widgets = [];

    scheduleDistribution!.forEach((sessionKey, courses) {
      widgets.add(Text(
        sessionKey,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ));
      if (courses == "no solution") {
        widgets.add(const Text('لا يوجد حل لهذا الجلسة'));
      } else {
        // courses هو Map<String, Map<String, int>>
        courses.forEach((courseName, rooms) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(courseName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ));
          List<Widget> roomWidgets = [];
          rooms.forEach((room, studentsCount) {
            roomWidgets.add(Text('$room: $studentsCount طالب'));
          });
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roomWidgets,
            ),
          ));
        });
      }
      widgets.add(const Divider());
    });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  Widget buildSupervisionTable() {
    if (supervisionAssignment == null || supervisionAssignment!.isEmpty) {
      return const Text('لا توجد بيانات لعرض توزيع المراقبين.');
    }

    List<DataRow> rows = supervisionAssignment!.map<DataRow>((assignment) {
      return DataRow(cells: [
        DataCell(Text(assignment['supervisor'] ?? '')),
        DataCell(Text(assignment['date'] ?? '')),
        DataCell(Text(assignment['day'] ?? '')),
        DataCell(Text(assignment['time'] ?? '')),
        DataCell(Text(assignment['session_id'] ?? '')),
      ]);
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(columns: const [
        DataColumn(label: Text('المراقب')),
        DataColumn(label: Text('التاريخ')),
        DataColumn(label: Text('اليوم')),
        DataColumn(label: Text('الوقت')),
        DataColumn(label: Text('معرف الجلسة')),
      ], rows: rows),
    );
  }

  Widget buildTasksSummary() {
    if (supervisionTasks == null || supervisionTasks!.isEmpty) {
      return const Text('لا توجد بيانات لعرض ملخص المهام.');
    }

    List<Widget> rows = supervisionTasks!.entries.map((e) {
      return Text('${e.key}: ${e.value} مهمة');
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول توزيع الامتحانات'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          onPressed: fetchSchedule,
                          child: const Text('تحميل الجدول الكامل'),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'توزيع الطلاب على القاعات:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (scheduleDistribution != null) buildScheduleTable(),
                        const SizedBox(height: 20),
                        const Text(
                          'توزيع المراقبين:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (supervisionAssignment != null) buildSupervisionTable(),
                        const SizedBox(height: 20),
                        const Text(
                          'ملخص عدد المهام لكل مراقب:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (supervisionTasks != null) buildTasksSummary(),
                      ],
                    ),
                  ),
      ),
    );
  }
}