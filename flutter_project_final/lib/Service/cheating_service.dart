import 'dart:convert';
import 'package:flutter_project_final/Config/service_conf.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

import '../moduels/Cheating/CheatingDetectionView .dart';

class CheatingService {
  final box = GetStorage();
  final baseUrl = ServiceConf.domainNameServer;

  Future<List<DetectionItem>> fetchPendingIncidents() async {
    final token = box.read('token');
    final url = Uri.parse('$baseUrl${ServiceConf.getIncidents}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['pending_incidents'] as List;
        return list.map((e) => DetectionItem.fromJson(e)).toList();
      } else {
        throw Exception('فشل في تحميل الحالات. ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ أثناء تحميل البيانات: $e');
    }
  }

Future<bool> updateIncidentAction(int id, String action) async {
  final token = box.read('token');
  final url = Uri.parse('${baseUrl}${ServiceConf.updateIncident}/$id'); // ← أضف /$id للرابط

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Dealing_with_cheating': action, // فقط هذا الحقل مطلوب
      }),
    );

    print("📮 Status: ${response.statusCode}");
    print("📩 Response: ${response.body}");

    final decoded = jsonDecode(response.body);
    return response.statusCode == 200 &&
           decoded['message'] == 'تم تحديث التعامل مع حالة الغش بنجاح.';
  } catch (e) {
    print("❌ استثناء أثناء الإرسال: $e");
    return false;
  }
}}