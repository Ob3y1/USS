import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_project_final/moduels/Cheating/CheatingDetectionView%20.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart'; // استيراد GetStorage
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class SmartMonitorScreen extends StatefulWidget {
  const SmartMonitorScreen({super.key});

  @override
  State<SmartMonitorScreen> createState() => _SmartMonitorScreenState();
}

class _SmartMonitorScreenState extends State<SmartMonitorScreen> {
  final String fastApiUrl = "http://localhost:8003";
  final String laravelApiUrl = "http://localhost:8000/api/addCheatingIncidents";

  final box = GetStorage(); // تعريف كائن التخزين

  bool showStream = false;
  List<Map<String, dynamic>> violations = [];
  List<Map<String, dynamic>> subjects = [];

  // حفظ المادة المختارة لكل مخالفة (مفتاح: index المخالفة، قيمة: subject_id أو null)
  Map<int, int?> selectedSubjectForViolation = {};

  Timer? autoRefreshTimer;

  @override
  @override
  void initState() {
    super.initState();
    _initAll(); // استدعِ دالة async
  }

  void _initAll() async {
    await fetchCurrentDistribution();
    await _initializeApp(); // حمل المواد وابدأ المراقبة بعد ذلك
  }

  Future<void> _initializeApp() async {
    await fetchSubjects(); // تحميل المواد أولًا وانتظارها
    _initMonitoring(); // ثم بدء المراقبة بعد تحميل المواد
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

  int? hallId; // لتخزين hall_id

  Future<void> fetchCurrentDistribution() async {
    try {
      final token = box.read('token') ?? '';
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/getCurrentDistributionId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            hallId = data['hall_id'];
          });
          print('✅ hall_id المحمّل: $hallId');
        } else {
          print('⚠️ فشل في قراءة hall_id من الرد: $data');
        }
      } else {
        print('❌ فشل في جلب hall_id: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ أثناء جلب hall_id: $e');
    }
  }

  Future<void> fetchSubjects() async {
    try {
      final token = box.read('token') ?? ''; // قراءة التوكن من التخزين
      final response = await http.get(
        Uri.parse("http://localhost:8000/api/getsubjectsnow"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded.containsKey('subjects')) {
          setState(() {
            subjects = List<Map<String, dynamic>>.from(decoded['subjects']);
          });
          print('✅ المواد المحملة: $subjects');
        } else {
          print('⚠️ البيانات المستلمة غير متوقعة: $decoded');
        }
      } else {
        print('❌ فشل في جلب المواد: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ أثناء جلب المواد: $e');
    }
  }

  Future<void> startMonitoring() async {
    if (hallId == null) {
      _showSnackBar("⚠️لا يوجد توزيع لهذا المراقب حاليا");
            _showSnackBar("⚠️لا توجد مواد حاليا للمراقب");

      return;
    }

    final url = Uri.parse("$fastApiUrl/start_cheat_detection");
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'hall_id': hallId});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      setState(() => showStream = true);
      _showSnackBar("✅ بدأ المراقبة");
    } else {
      print("❌ فشل بدء المراقبة: ${response.body}");
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
        final decoded = json.decode(utf8.decode(response.bodyBytes));

        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('violations')) {
          final List<dynamic> rawViolations = decoded['violations'];

          setState(() {
            violations = rawViolations
                .whereType<Map<String, dynamic>>()
                .toList();

            // هيأ القيم للمواد المختارة لكل مخالفة
            for (int i = 0; i < violations.length; i++) {
              selectedSubjectForViolation.putIfAbsent(i, () => null);
            }
          });
        } else {
          print('⚠️ تنسيق البيانات غير صحيح أو مفتاح "violations" غير موجود');
        }
      } else {
        print('❌ فشل في جلب المخالفات: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ خطأ أثناء جلب المخالفات: $e');
    }
  }

  String decodeUnicode(String input) {
    return input.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }

  Future<void> confirmViolation(
    Map<String, dynamic> violation,
    int subjectId,
  ) async {
    try {
      final token = box.read('token') ?? '';
      final uri = Uri.parse(laravelApiUrl);

      String formattedTimestamp = '';
      if (violation['timestamp'] != null &&
          violation['timestamp'].toString().isNotEmpty) {
        DateTime parsed = DateTime.parse(violation['timestamp']);
        formattedTimestamp =
            "${parsed.year}-${parsed.month}-${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:00:00";
      } else {
        DateTime now = DateTime.now();
        formattedTimestamp =
            "${now.year}-${now.month}-${now.day} ${now.hour.toString().padLeft(2, '0')}:00:00";
      }

      var request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['subject_id'] = subjectId.toString()
        ..fields['cheating_type'] = violation['arabic_name'] ?? 'غير معروف'
        ..fields['timestamp'] = formattedTimestamp
        ..fields['Dealing_with_cheating'] = '';

      final imageBase64 = violation['image_base64'];

      if (imageBase64 != null && imageBase64.isNotEmpty) {
        final regex = RegExp(r'data:image/(\w+);base64,');
        final match = regex.firstMatch(imageBase64);
        String imageType = 'jpeg';
        if (match != null) {
          imageType = match.group(1)!;
        }

        final base64Str = imageBase64.split(',').last;
        Uint8List imageBytes = base64Decode(base64Str);

        final multipartFile = http.MultipartFile.fromBytes(
          'video_snapshot',
          imageBytes,
          filename: 'snapshot.$imageType',
          contentType: MediaType('image', imageType),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();

      final responseBody = await response.stream.bytesToString();

      try {
        final decoded = jsonDecode(responseBody);
        final rawMessage = decoded['message'];
        final readableMessage = decodeUnicode(rawMessage);
        _showSnackBar(readableMessage);
        print("📨 Response message: $readableMessage");
      } catch (e) {
        print("📨 Response body (raw): $responseBody");
        _showSnackBar(responseBody);
      }

      if (response.statusCode == 200) {
        _showSnackBar("✅ تم تأكيد المخالفة");

        // **تحديث تلقائي**
        final detectionController = Get.find<DetectionController>();
        detectionController.loadIncidents();
      } else {
        _showSnackBar("❌ فشل تأكيد المخالفة: $responseBody");
      }
    } catch (e, stack) {
      print("📛 Exception: $e");
      print("📛 Stacktrace: $stack");
      _showSnackBar("❌ خطأ أثناء إرسال المخالفة: $e");
    }
  }

  Future<void> clearViolations() async {
    final res = await http.post(Uri.parse("$fastApiUrl/clear_violations"));
    if (res.statusCode == 200) {
      setState(() {
        violations.clear();
        selectedSubjectForViolation.clear();
      });
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
          Expanded(child: _buildViolationsList()),
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

  Widget _buildViolationsList() {
    if (violations.isEmpty) {
      return Center(
        child: Text(
          "لا توجد مخالفات حتى الآن",
          style: TextStyle(color: Colors.white54),
        ),
      );
    } else {
      return ListView.builder(
        itemCount: violations.length,
        itemBuilder: (context, index) {
          final violation = violations[index];
          final String type = violation['arabic_name'] ?? "غير معروف";
          final String position = violation['position'] ?? "غير محدد";
          final String timestamp = violation['timestamp'] ?? "";
          final imageBytes = decodeBase64Image(violation['image_base64']);
          print(
            'Index: $index, Selected Subject: ${selectedSubjectForViolation[index]}, Subjects count: ${subjects.length}',
          );

          return Card(
            key: ValueKey(index),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            elevation: 3,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "🔔 نوع المخالفة: $type",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("📍 $position", style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(
                    "🕒 الوقت: $timestamp",
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  if (imageBytes != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.memory(imageBytes, fit: BoxFit.contain),
                    ),
                  DropdownButton<int>(
                    key: ValueKey('dropdown_$index'),
                    hint: const Text("اختر المادة"),
                    value: selectedSubjectForViolation[index],
                    items: subjects.map((subject) {
                      return DropdownMenuItem<int>(
                        value: subject['id'],
                        child: Text(subject['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubjectForViolation[index] = value;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: selectedSubjectForViolation[index] == null
                        ? null
                        : () async {
                            await confirmViolation(
                              violation,
                              selectedSubjectForViolation[index]!,
                            );
                          },
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
}
