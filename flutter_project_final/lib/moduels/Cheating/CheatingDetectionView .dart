import 'package:flutter_project_final/Service/cheating_service.dart';
import 'package:get/get.dart';


class DetectionItem {
  final int id;
  final String cheatType;
  final String imageName;
  final String timestamp;
  final String subjectName;
  final String hall;
  final String examDay;
  final String examDate;
  final String examTime;
  final RxString actionTaken;

  DetectionItem({
    required this.id,
    required this.cheatType,
    required this.imageName,
    required this.timestamp,
    required this.subjectName,
    required this.hall,
    required this.examDay,
    required this.examDate,
    required this.examTime,
  }) : actionTaken = ''.obs;

  factory DetectionItem.fromJson(Map<String, dynamic> json) {
    return DetectionItem(
      id: json['id'],
      cheatType: json['cheating_type'],
      imageName: json['video_snapshot'],
      timestamp: json['timestamp'],
      subjectName: json['subject']['name'],
      hall: json['hall']['location'],
      examDay: json['exam_day']['day'],
      examDate: json['exam_day']['date'],
      examTime: json['exam_time'],
    );
  }
}

class DetectionController extends GetxController {
  final detections = <DetectionItem>[].obs;
  final _service = CheatingService();
@override
void onInit() {
  super.onInit();

  // // ✅ بيانات تجريبية لمعاينة التصميم فقط
  // detections.add(DetectionItem(
  //   id: 999,
  //   cheatType: "استخدام هاتف",
  //   imageName: "snapshot_test.jpg",
  //   timestamp: "10:30 ص",
  //   subjectName: "رياضيات",
  //   hall: "القاعة 4",
  //   examDay: "الاثنين",
  //   examDate: "2025-06-30",
  //   examTime: "10:30",

    
  // ));
  // detections.add(DetectionItem(
  //   id: 999,
  //   cheatType: "استخدام هاتف",
  //   imageName: "snapshot_test.jpg",
  //   timestamp: "10:30 ص",
  //   subjectName: "رياضيات",
  //   hall: "القاعة 4",
  //   examDay: "الاثنين",
  //   examDate: "2025-06-30",
  //   examTime: "10:30",

    
  // ));
  // detections.add(DetectionItem(
  //   id: 999,
  //   cheatType: "استخدام هاتف",
  //   imageName: "snapshot_test.jpg",
  //   timestamp: "10:30 ص",
  //   subjectName: "رياضيات",
  //   hall: "القاعة 4",
  //   examDay: "الاثنين",
  //   examDate: "2025-06-30",
  //   examTime: "10:30",

    
  // ));

  // 🌀 تحميل البيانات الحقيقية بعد ذلك
  loadIncidents();
}

  void loadIncidents() async {
    try {
      final result = await _service.fetchPendingIncidents();
     detections.addAll(result);
      print("✅ عدد الحالات: ${result.length}");
    } catch (e) {
      print("❌ فشل تحميل الحالات: $e");
    }
  }

  void sendAction(DetectionItem item) async {
    final success = await _service.updateIncidentAction(item.id, item.actionTaken.value);
    if (success) {
      Get.snackbar("تم الإرسال", "✅ تم تسجيل الإجراء بنجاح", snackPosition: SnackPosition.BOTTOM);
      detections.remove(item);
    } else {
      Get.snackbar("خطأ", "❌ لم يتم إرسال الإجراء", snackPosition: SnackPosition.BOTTOM);
    }
  }
}