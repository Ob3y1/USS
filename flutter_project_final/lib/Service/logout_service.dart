import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../Config/service_conf.dart'; // تأكد من المسار

class AuthService {
  final box = GetStorage();
  final baseUrl = ServiceConf.domainNameServer;

  Future<bool> logout() async {
    final token = box.read('token');
    final url = Uri.parse('$baseUrl${ServiceConf.logoutEndpoint}'); // مثال: /api/logout

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        box.remove('token');
        box.remove('isLoggedIn');
        return true;
      } else {
        print("⚠️ فشل تسجيل الخروج: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ استثناء أثناء تسجيل الخروج: $e");
      return false;
    }
  }
}