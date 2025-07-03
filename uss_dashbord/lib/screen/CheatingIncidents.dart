import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheatingIncident {
  final int id;
  final String cheatingType;
  final String snapshot;
  final String? dealingWithCheating;
  final String timestamp;
  final String supervisorName;
  final String hallLocation;
  final String subjectName;
  final String examDate;
  final String examDay;
  final String examTime;

  CheatingIncident({
    required this.id,
    required this.cheatingType,
    required this.snapshot,
    required this.dealingWithCheating,
    required this.timestamp,
    required this.supervisorName,
    required this.hallLocation,
    required this.subjectName,
    required this.examDate,
    required this.examDay,
    required this.examTime,
  });

  factory CheatingIncident.fromJson(Map<String, dynamic> json) {
    return CheatingIncident(
      id: json['id'],
      cheatingType: json['cheating_type'],
      snapshot: json['video_snapshot'],
      dealingWithCheating: json['dealing_with_cheating'],
      timestamp: json['timestamp'],
      supervisorName: json['supervisor']['name'],
      hallLocation: json['hall']['location'],
      subjectName: json['subject']['name'],
      examDate: json['exam_day']['date'],
      examDay: json['exam_day']['day'],
      examTime: json['exam_time']['time'],
    );
  }
}

class CheatingListScreen extends StatefulWidget {
  @override
  _CheatingListScreenState createState() => _CheatingListScreenState();
}

class _CheatingListScreenState extends State<CheatingListScreen> {
  List<CheatingIncident> incidents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCheatingIncidents();
  }

  Future<void> fetchCheatingIncidents() async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await dio.get(
        'http://localhost:8000/api/CheatingIncidents',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print(response.data);
        final List<dynamic> data = response.data;
        setState(() {
          incidents = data.map((e) => CheatingIncident.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        print('فشل الاستدعاء: ${response.statusMessage}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('خطأ: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('سجل حالات الغش',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.blue),
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Image.network(
                      'http://localhost:8000/storage/${incident.snapshot}',
                      width: 60,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                    title: Text('نوع الغش: ${incident.cheatingType}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('المشرف: ${incident.supervisorName}'),
                        Text('المادة: ${incident.subjectName}'),
                        Text('القاعة: ${incident.hallLocation}'),
                        Text(
                            'الزمن: ${incident.examDay} ${incident.examDate} - ${incident.examTime}'),
                        Text(
                            'الإجراء: ${incident.dealingWithCheating ?? "لم تتم المعالجة"}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
