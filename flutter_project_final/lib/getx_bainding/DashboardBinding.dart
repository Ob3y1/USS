import 'package:get/get.dart';
import 'package:flutter_project_final/moduels/dashpord/dashboard_controller.dart';
import 'package:flutter_project_final/moduels/profile/profile_controller.dart';
import 'package:flutter_project_final/moduels/schedule/schedule_controller.dart';
import 'package:flutter_project_final/moduels/monitor/monitor_controller.dart';

class DashboardBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(DashboardController());
    Get.put(ProfileController());
    Get.put(ScheduleController());
    Get.put(MonitorController());
  }
}
