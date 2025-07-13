import 'dart:convert';
import 'package:flutter_project_final/Config/service_conf.dart';
import 'package:flutter_project_final/moduels/users.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';



class LoginService {
  var message = '';
  var token = '';
  final box = GetStorage();
  final url = Uri.parse(ServiceConf.domainNameServer + ServiceConf.login);

  Future<bool> login(User user) async {
    var body = jsonEncode({
      'email': user.email,
      'password': user.password,
    });

    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

    if (response.statusCode == 200 || response.statusCode == 201) { // ✅ يدعم الحالتين
        var jsonResponse = jsonDecode(response.body);

        token = jsonResponse['token'] ?? '';
        var userData = jsonResponse['user'];

        if (token.isNotEmpty) {
          box.write('token', token);
          box.write('isLoggedIn', true);
          box.write('email', userData['email']);
         box.write('observer_name', userData['name']); // لتوحيد الاستخدام مع الـ Drawer
          box.write('userId', userData['id']);

          message = 'تم تسجيل الدخول بنجاح';
          return true;

        } else {
          message = 'لم يتم استلام التوكن من السيرفر';
        }
      } else if (response.statusCode == 401) {
        message = 'بيانات الدخول غير صحيحة';
      } else if (response.statusCode == 422) {
        var jsonResponse = jsonDecode(response.body);
        message = jsonResponse['error'] ?? 'خطأ في البيانات المدخلة';
      } else {
        message = 'فشل الاتصال بالسيرفر (رمز ${response.statusCode})';
      }
    } catch (e) {
      message = 'حدث خطأ أثناء تسجيل الدخول: $e';
    }

    return false;
  }
}