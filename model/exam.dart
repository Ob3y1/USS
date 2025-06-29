
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void main() {
  runApp(CheatDetectionApp());
}

class CheatDetectionApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام كشف الغش',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CheatDetectionHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CheatDetectionHomePage extends StatefulWidget {
  @override
  _CheatDetectionHomePageState createState() => _CheatDetectionHomePageState();
}

class _CheatDetectionHomePageState extends State<CheatDetectionHomePage> {
  List<Map<String, dynamic>> violations = [];
  final String fastApiUrl = "http://localhost:8000";
  final String laravelApiUrl = "http://localhost:8004/api/save_violation";
  Timer? autoRefreshTimer;
  bool showStream = false;

  @override
  void initState() {
    super.initState();
    fetchViolations();
    autoRefreshTimer = Timer.periodic(Duration(seconds: 5), (_) {
      fetchViolations();
    });

    if (kIsWeb) {
      ui_web.platformViewRegistry.registerViewFactory(
        'mjpeg-stream',
        (int viewId) => html.ImageElement()
          ..src = '$fastApiUrl/video_feed'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%',
      );
    }
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  Future<void> startExam() async {
    final url = Uri.parse("$fastApiUrl/start_cheat_detection");
    final response = await http.post(url);
    if (response.statusCode == 200) {
      setState(() {
        showStream = true;
      });
      _showSnackBar("✅ تم بدء الامتحان");
    } else {
      _showSnackBar("❌ فشل في بدء الامتحان");
    }
  }

  Future<void> endExam() async {
    final url = Uri.parse("$fastApiUrl/stop_cheat_detection");
    final response = await http.post(url);
    if (response.statusCode == 200) {
      setState(() {
        showStream = false;
      });
      _showSnackBar("🛑 تم إنهاء الامتحان");
    } else {
      _showSnackBar("❌ فشل في إنهاء الامتحان");
    }
  }

  Future<void> fetchViolations() async {
    final url = Uri.parse("$fastApiUrl/violations");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> logs = data['violations'];
      setState(() {
        violations = logs.cast<Map<String, dynamic>>();
      });
    } else {
      _showSnackBar("⚠️ فشل في جلب المخالفات");
    }
  }

  Future<void> clearViolations() async {
    final url = Uri.parse("$fastApiUrl/clear_violations");
    final response = await http.post(url);
    if (response.statusCode == 200) {
      _showSnackBar("🧹 تم مسح جميع المخالفات");
      fetchViolations();
    } else {
      _showSnackBar("❌ فشل في مسح المخالفات");
    }
  }

  Future<void> confirmViolation(Map<String, dynamic> violation) async {
    try {
      final response = await http.post(
        Uri.parse(laravelApiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "type": violation['arabic_name'] ?? "غير معروف",
          "position": violation['position'] ?? "غير محدد",
          "timestamp": violation['timestamp'] ?? "",
          "image_base64": violation['image_base64'] ?? "",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("✅ تم تأكيد المخالفة وحفظها");
      } else {
        _showSnackBar("❌ فشل في إرسال المخالفة");
      }
    } catch (e) {
      _showSnackBar("❌ خطأ في الاتصال: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildViolationsList() {
    if (violations.isEmpty) {
      return Center(child: Text("لا توجد مخالفات حتى الآن"));
    } else {
      return ListView.builder(
        itemCount: violations.length,
        itemBuilder: (context, index) {
          final violation = violations[index];
          final String type = violation['arabic_name'] ?? "غير معروف";
          final String position = violation['position'] ?? "غير محدد";
          final String timestamp = violation['timestamp'] ?? "";
          final imageBytes = decodeBase64Image(violation['image_base64']);

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            elevation: 3,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🔔 نوع المخالفة: $type",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text("📍 $position", style: TextStyle(fontSize: 15)),
                  SizedBox(height: 6),
                  Text("🕒 الوقت: $timestamp",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 10),
                  if (imageBytes != null)
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                      child: Image.memory(imageBytes, fit: BoxFit.contain),
                    ),
                  ElevatedButton(
                    onPressed: () => confirmViolation(violation),
                    child: Text("تأكيد"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  )
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🛡️ نظام كشف الغش'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: startExam,
                        child: Text("بدء الامتحان"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      ElevatedButton(
                        onPressed: endExam,
                        child: Text("إنهاء الامتحان"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: fetchViolations,
                        child: Text("تحديث يدوي للمخالفات"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      ),
                      ElevatedButton(
                        onPressed: clearViolations,
                        child: Text("مسح المخالفات"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ],
                  ),
                ),
                if (showStream && kIsWeb)
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: double.infinity,
                      child: HtmlElementView(viewType: 'mjpeg-stream'),
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildViolationsList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
