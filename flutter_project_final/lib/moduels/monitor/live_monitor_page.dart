import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SmartMonitorScreen extends StatefulWidget {
  const SmartMonitorScreen({super.key});

  @override
  State<SmartMonitorScreen> createState() => _SmartMonitorScreenState();
}

class _SmartMonitorScreenState extends State<SmartMonitorScreen> {
  final String fastApiUrl = "http://localhost:8003";
  final String laravelApiUrl = "http://localhost:8000/api/addCheatingIncidents";

  bool showStream = false;
  List<Map<String, dynamic>> violations = [];
  Timer? autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _initMonitoring();
  }

  @override
  void dispose() {
    autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _initMonitoring() {
    fetchViolations();
    autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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

  Future<void> startMonitoring() async {
    final url = Uri.parse("$fastApiUrl/start_cheat_detection");
    final response = await http.post(url);
    if (response.statusCode == 200) {
      setState(() => showStream = true);
      _showSnackBar("✅ بدأ المراقبة");
    } else {
      _showSnackBar("❌ فشل بدء المراقبة");
    }
  }

  Future<void> stopMonitoring() async {
    final url = Uri.parse("$fastApiUrl/stop_cheat_detection");
    final response = await http.post(url);
    if (response.statusCode == 200) {
      setState(() => showStream = false);
      _showSnackBar("🛑 تم إيقاف المراقبة");
    } else {
      _showSnackBar("❌ فشل في الإيقاف");
    }
  }

  Future<void> fetchViolations() async {
    try {
      final response = await http.get(Uri.parse('$fastApiUrl/violations'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          violations = data['violations'];
        });
      } else {
        print('فشل في جلب المخالفات: ${response.statusCode}');
      }
    } catch (e) {
      print('خطأ أثناء جلب المخالفات: $e');
    }
  }

  Future<void> confirmViolation(Map<String, dynamic> violation) async {
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
      _showSnackBar("✅ تم تأكيد المخالفة");
    } else {
      _showSnackBar("❌ فشل تأكيد المخالفة");
    }
  }

  Future<void> clearViolations() async {
    final res = await http.post(Uri.parse("$fastApiUrl/clear_violations"));
    if (res.statusCode == 200) {
      setState(() => violations.clear());
      _showSnackBar("🧹 تم مسح المخالفات");
    } else {
      _showSnackBar("❌ فشل في عملية المسح");
    }
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('📡 Exam Prohibition System'),
        backgroundColor: const Color(0xFF2E2E48),
        actions: const [
          Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.camera_alt)),
        ],
      ),
      body: Column(
        children: [
          _buildVideoSection(),
          _buildControlButtons(),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const Text(
            "📋 Violations Detected",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildViolationList()),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      margin: const EdgeInsets.all(12),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: showStream && kIsWeb
            ? const HtmlElementView(viewType: 'mjpeg-stream')
            : const Center(
                child: Text(
                  "📷 لا يوجد بث مباشر",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Monitoring"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: startMonitoring,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text("Stop"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: stopMonitoring,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("تحديث يدوي"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () async {
                  await fetchViolations();
                  _showSnackBar("🔄 تم التحديث");
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("مسح جميع الحالات"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: clearViolations,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViolationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: violations.length,
      itemBuilder: (context, index) {
        final v = violations[index];
        final imageBytes = decodeBase64Image(v['image_base64']);

        final String type = v['arabic_name'] ?? "غير معروف";
        final String position = v['position'] ?? "غير محدد";
        final String timestamp = v['timestamp'] ?? "";

        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🔔 نوع المخالفة: $type",
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  "📍 الموقع: $position",
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  "🕒 الوقت: $timestamp",
                  style: const TextStyle(color: Colors.white38),
                ),
                const SizedBox(height: 10),
                if (imageBytes != null)
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Image.memory(imageBytes, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => confirmViolation(v),
                  child: const Text("تأكيد"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
