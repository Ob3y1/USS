import 'dart:convert';
import 'package:flutter_project_final/moduels/schedule/schedule_controller.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter_project_final/Config/service_conf.dart';



class ScheduleService {
  var message = '';
  final box = GetStorage();
  final url = Uri.parse(ServiceConf.domainNameServer + ServiceConf.schedule);

  Future<List<ScheduleItem>> fetchSchedule() async {
    final token = box.read('token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final rawList = jsonResponse['supervision_tasks'] as List;

        return rawList
            .map((item) => ScheduleItem.fromJson(item))
            .toList();
      } else {
        message = 'فشل في تحميل الجدول. الرمز: ${response.statusCode}';
        return [];
      }
    } catch (e) {
      message = 'حدث خطأ أثناء جلب البيانات: $e';
      return [];
    }
  }
}