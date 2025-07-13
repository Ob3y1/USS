import 'dart:convert';

import 'package:flutter_project_final/Config/service_conf.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class ScheduleItem {
  final String examName;
  final String date;
  final String time;
  final String hall;
  final String day;
  final String subjectList; // ✅ جديد

  ScheduleItem({
    required this.examName,
    required this.date,
    required this.time,
    required this.hall,
    required this.day,
    required this.subjectList,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final firstTime = (json['times'] as List).first;
    final hall = firstTime['hall']['location'];
    final time = firstTime['time'];
    final subjects = (firstTime['subjects'] as List);

    final examNames = subjects.map((e) => e['name']).join(' / ');
    final details = subjects.map((e) {
      final name = e['name'];
      final num = e['students_number'];
      return "- $name: $num طالب";
    }).join('\n');

    return ScheduleItem(
      examName: examNames,
      date: json['date'],
      time: time,
      hall: hall,
      day: json['day'],
      subjectList: details, // 🆕
    );
  }
}

class ScheduleController extends GetxController {
  var schedule = <ScheduleItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSchedule();
  }

  void fetchSchedule() async {
    final box = GetStorage();
    final token = box.read('token');
    final url = Uri.parse(ServiceConf.domainNameServer + ServiceConf.schedule);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> raw = data['supervision_tasks'];

        final scheduleList = raw
            .map((item) => ScheduleItem.fromJson(item))
            .toList();

        schedule.assignAll(scheduleList);
      } else {
        print('📛 خطأ في تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ استثناء في الاتصال: $e');
    }
  }
}
