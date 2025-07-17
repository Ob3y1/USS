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
  final Supervisor? supervisor;
  final Hall? hall;
  final Subject subject;
  final ExamDay? examDay;
  final ExamTime? examTime;

  CheatingIncident({
    required this.id,
    required this.cheatingType,
    required this.snapshot,
    required this.dealingWithCheating,
    required this.timestamp,
    this.supervisor,
    this.hall,
    required this.subject,
    this.examDay,
    this.examTime,
  });

  factory CheatingIncident.fromJson(Map<String, dynamic> json) {
    return CheatingIncident(
      id: json['id'],
      cheatingType: json['cheating_type'],
      snapshot: json['video_snapshot'],
      dealingWithCheating: json['dealing_with_cheating'],
      timestamp: json['timestamp'],
      supervisor: json['supervisor'] != null
          ? Supervisor.fromJson(json['supervisor'])
          : null,
      hall: json['hall'] != null ? Hall.fromJson(json['hall']) : null,
      subject: Subject.fromJson(json['subject']),
      examDay:
          json['exam_day'] != null ? ExamDay.fromJson(json['exam_day']) : null,
      examTime: json['exam_time'] != null
          ? ExamTime.fromJson(json['exam_time'])
          : null,
    );
  }
  String get imageUrl {
    final filename = snapshot.split('/').last;
    return 'http://localhost:8000/storage/snapshots/$filename';
  }
}

class Subject {
  final int id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Supervisor {
  final int id;
  final String name;

  Supervisor({required this.id, required this.name});

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Hall {
  final int id;
  final String location;

  Hall({required this.id, required this.location});

  factory Hall.fromJson(Map<String, dynamic> json) {
    return Hall(
      id: json['id'],
      location: json['location'],
    );
  }
}

class ExamDay {
  final String date;
  final String day;

  ExamDay({required this.date, required this.day});

  factory ExamDay.fromJson(Map<String, dynamic> json) {
    return ExamDay(
      date: json['date'],
      day: json['day'],
    );
  }
}

class ExamTime {
  final String time;

  ExamTime({required this.time});

  factory ExamTime.fromJson(Map<String, dynamic> json) {
    return ExamTime(
      time: json['time'],
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
  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    fetchCheatingIncidents();
  }

  Future<void> fetchCheatingIncidents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await _dio.get(
        'http://localhost:8000/api/CheatingIncidents',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print(response);
        setState(() {
          incidents = data.map((e) => CheatingIncident.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        print('Failed to fetch: ${response.statusMessage}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildImageWidget(String imagePath) {
    // استخراج اسم الملف فقط من المسار
    final filename = imagePath.split('/').last;
    final url = 'http://localhost:8000/storage/snapshots/$filename';

    return Image.network(
      url,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined, color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('سجل حالات الغش',
            style: TextStyle(
              color: Colors.black87, // تغيير لون النص إلى الأسود
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            )),
        backgroundColor: Colors.white, // خلفية بيضاء
        elevation: 1, // ظل خفيف للتمييز
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : incidents.isEmpty
              ? const Center(
                  child: Text('لا توجد حالات غش مسجلة',
                      style: TextStyle(color: Colors.black87)),
                )
              : ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      color: Colors.white70,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageWidget(incident.snapshot),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('نوع الغش: ${incident.cheatingType}',
                                      style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('المادة: ${incident.subject.name}',
                                      style: const TextStyle(
                                          color: Colors.black87)),
                                  if (incident.supervisor != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                          'المشرف: ${incident.supervisor!.name}',
                                          style: const TextStyle(
                                              color: Colors.black87)),
                                    ),
                                  if (incident.hall != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                          'القاعة: ${incident.hall!.location}',
                                          style: const TextStyle(
                                              color: Colors.black87)),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('الوقت: ${incident.timestamp}',
                                        style: const TextStyle(
                                            color: Colors.black87)),
                                  ),
                                  if (incident.examDay != null &&
                                      incident.examTime != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'موعد الامتحان: ${incident.examDay!.day} ${incident.examDay!.date} - ${incident.examTime!.time}',
                                        style: const TextStyle(
                                            color: Colors.black87),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'الإجراء: ${incident.dealingWithCheating ?? "لم تتم المعالجة"}',
                                      style: TextStyle(
                                        color:
                                            incident.dealingWithCheating != null
                                                ? Colors.green
                                                : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
