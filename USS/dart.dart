import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(
    home: SupervisorScheduler(),
    debugShowCheckedModeBanner: false,
  ));
}

class SupervisorScheduler extends StatefulWidget {
  @override
  _SupervisorSchedulerState createState() => _SupervisorSchedulerState();
}

class _SupervisorSchedulerState extends State<SupervisorScheduler> {
  bool isLoading = false;
  bool isSaving = false;

  List<String> initialDays = ['أحد', 'اثنين', 'ثلاثاء', 'الأربعاء', 'الخميس'];
  List<String> initialTimes = ['9:00', '10:30', '12:00', '13:30', '15:00', '16:30'];

  Map<String, Map<String, Map<String, String>>> finalSchedule = {};
  List<Map<String, dynamic>> assignments = [];
  Map<String, int> taskCounts = {};
  bool hasGenerated = false;

  Map<String, Map<String, Map<String, String>>> initialSchedule = {};

  @override
  void initState() {
    super.initState();
    _buildInitialEmptySchedule();
  }

  void _buildInitialEmptySchedule() {
    initialSchedule.clear();
    for (var day in initialDays) {
      initialSchedule[day] = {};
      for (var time in initialTimes) {
        initialSchedule[day]![time] = {'supervisor': '', 'room': ''};
      }
    }
  }

  Future<void> fetchAndAssign() async {
    setState(() {
      isLoading = true;
      assignments.clear();
      taskCounts.clear();
      finalSchedule.clear();
      hasGenerated = false;
    });

    try {
      final fetchUrl = Uri.parse("http://127.0.0.1:8001/api/fetch-data");
      final fetchResponse = await http.get(fetchUrl);

      if (fetchResponse.statusCode == 200) {
        final fetchedData = jsonDecode(utf8.decode(fetchResponse.bodyBytes));
        final sessions = fetchedData["sessions"];
        final supervisors = fetchedData["supervisors"];

        final assignUrl = Uri.parse("http://127.0.0.1:8000/assign-supervisors");
        final assignResponse = await http.post(
          assignUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "sessions": sessions,
            "supervisors": supervisors,
          }),
        );

        final decoded = jsonDecode(utf8.decode(assignResponse.bodyBytes));

        if (decoded["status"] == "ok") {
          setState(() {
            assignments = List<Map<String, dynamic>>.from(decoded["assignments"]);
            taskCounts = Map<String, int>.from(decoded["task_count"]);
            _buildFinalSchedule();
            hasGenerated = true;
          });
        } else {
          _showError("فشل في التوزيع من بايثون");
        }
      } else {
        _showError("فشل في جلب البيانات من Laravel");
      }
    } catch (e) {
      _showError("خطأ: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveScheduleToDatabase() async {
    if (assignments.isEmpty) {
      _showError("لا يوجد جدول لحفظه");
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final saveUrl = Uri.parse("http://127.0.0.1:8002/api/save-schedule");
      final response = await http.post(
        saveUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"assignments": assignments}),
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && decoded["status"] == "ok") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم حفظ الجدول بنجاح"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError("فشل في حفظ الجدول");
      }
    } catch (e) {
      _showError("خطأ أثناء الحفظ: $e");
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _buildFinalSchedule() {
    finalSchedule.clear();
    for (var a in assignments) {
      final day = a['day'];
      final time = a['time'];
      final supervisor = a['supervisor'];
      final room = a['room'];

      finalSchedule[day] ??= {};
      finalSchedule[day]![time] = {'supervisor': supervisor, 'room': room};
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Widget buildInitialTable() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: Colors.grey.shade400),
          defaultColumnWidth: FixedColumnWidth(100),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey.shade100),
              children: [
                tableHeader("اليوم / الوقت"),
                ...initialTimes.map((t) => tableHeader(t)).toList(),
              ],
            ),
            ...initialDays.map((day) => TableRow(
              children: [
                tableHeader(day),
                ...initialTimes.map((time) {
                  return Container(
                    padding: EdgeInsets.all(6),
                    child: Center(child: Text("-", style: TextStyle(color: Colors.grey))),
                  );
                }).toList(),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget buildFinalScheduleTable() {
    final days = finalSchedule.keys.toList()..sort();
    final timesSet = <String>{};
    for (var day in days) {
      timesSet.addAll(finalSchedule[day]!.keys);
    }
    final times = timesSet.toList()..sort();

    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: Colors.blueGrey.shade200),
          defaultColumnWidth: FixedColumnWidth(120),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blueGrey.shade100),
              children: [
                tableHeader("اليوم / الوقت"),
                ...times.map((t) => tableHeader(t)),
              ],
            ),
            ...days.map((day) {
              return TableRow(
                children: [
                  tableHeader(day),
                  ...times.map((time) {
                    final content = finalSchedule[day]?[time];
                    final sup = content?['supervisor'] ?? '';
                    final room = content?['room'] ?? '';
                    return Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.grey[50],
                      child: Center(
                        child: Text("$sup\n$room", textAlign: TextAlign.center),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget buildTaskCounts() {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 12),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("عدد الجلسات لكل مراقب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            ...taskCounts.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text("${e.key}: ${e.value} جلسة", style: TextStyle(fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }

  Widget tableHeader(String text) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[900]),
      textAlign: TextAlign.center,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text("نظام توزيع المراقبين")),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.download),
                label: Text(isLoading ? "جارٍ التحميل..." : "جلب وتوزيع المراقبين"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: isLoading || isSaving ? null : fetchAndAssign,
              ),

              SizedBox(height: 12),

              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text(isSaving ? "جارٍ الحفظ..." : "💾 حفظ الجدول"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  backgroundColor: Colors.green,
                  textStyle: TextStyle(fontSize: 18),
                ),
                onPressed: (!hasGenerated || isLoading || isSaving) ? null : saveScheduleToDatabase,
              ),

              SizedBox(height: 16),

              if (!hasGenerated) ...[
                Text(
                  "جدول الأوقات الأولي",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
                ),
                buildInitialTable(),
              ],

              if (hasGenerated) ...[
                Text(
                  "جدول توزيع المراقبين",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700]),
                ),
                buildFinalScheduleTable(),

                SizedBox(height: 10),

                buildTaskCounts(),
              ],

              if (isLoading || isSaving)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}