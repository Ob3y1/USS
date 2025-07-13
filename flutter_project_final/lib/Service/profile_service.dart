import 'dart:convert';
import 'package:flutter_project_final/Config/service_conf.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';


class ProfileService {
  final box = GetStorage();
  final baseUrl = ServiceConf.domainNameServer;

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final token = box.read('token');
    final url = Uri.parse('$baseUrl${ServiceConf.showprofileuser}');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return decoded['user'];
      }
    } catch (e) {
      print("❌ خطأ في جلب الملف الشخصي: $e");
    }
    return null;
  }

  Future<bool> updateUserProfile(String name, String email, String password) async {
    final token = box.read('token');
    final url = Uri.parse('$baseUrl${ServiceConf.updateprofileuser}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final decoded = jsonDecode(response.body);
      return response.statusCode == 201 &&
          decoded['message'].toString().contains("successfully");
    } catch (e) {
      print("❌ خطأ في التحديث: $e");
      return false;
    }
  }
}