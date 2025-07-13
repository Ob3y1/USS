// subject_controller.dart
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Subject {
  final int id;
  final String name;

  Subject({required this.id, required this.name});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(id: json['id'], name: json['name']);
  }
}

class SubjectController extends GetxController {
  var subjects = <Subject>[].obs;

  Future<void> fetchSubjects() async {
    final response = await http.get(Uri.parse('http://localhost:8000/api/getsubjectsnow'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data['subjects'] as List;
      subjects.assignAll(raw.map((e) => Subject.fromJson(e)).toList());
    }
  }
}