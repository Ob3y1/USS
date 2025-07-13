import 'package:flutter/material.dart';
import 'package:flutter_project_final/Service/logout_service.dart';
import 'package:flutter_project_final/moduels/Cheating/DetectionView.dart';
import 'package:flutter_project_final/moduels/monitor/live_monitor_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../schedule/schedule_view.dart';
import '../profile/profile_view.dart';


import 'dashboard_controller.dart';

class DashboardView extends StatelessWidget {
  final DashboardController controller = Get.put(DashboardController());

  final List<Widget> pages = [
    ScheduleView(),
    ProfileView(),
   SmartMonitorScreen (),
    DetectionView(), // ✅ صفحة ضبط الغش
  ];

  final List<String> titles = [
    '📅 جدول المراقبة',
    '👤 المعلومات الشخصية',
    '🔍 بدء المراقبة',
    '🚨 ضبط الغش',
  ];

  final List<IconData> icons = [
    Icons.calendar_today,
    Icons.person_outline,
    Icons.videocam_outlined,
    Icons.warning_amber_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 2,
        title: Obx(
          () => Text(
            titles[controller.currentIndex.value],
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF2C2C2C),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3A3A3A)),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurpleAccent,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () => Text(
                            'مرحباً، ${controller.observerName.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ...List.generate(titles.length, (index) {
              return Obx(
                () => ListTile(
                  leading: Icon(
                    icons[index],
                    color: controller.currentIndex.value == index
                        ? Colors.deepPurpleAccent
                        : Colors.white70,
                  ),
                  title: Text(
                    titles[index],
                    style: TextStyle(
                      color: controller.currentIndex.value == index
                          ? Colors.deepPurpleAccent
                          : Colors.white,
                    ),
                  ),
                  selected: controller.currentIndex.value == index,
                  onTap: () {
                    controller.changePage(index);
                    Get.back();
                  },
                ),
              );
            }),
            const Spacer(),
            const Divider(color: Colors.grey),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "تسجيل الخروج",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                final confirmed = await Get.defaultDialog<bool>(
                  title: "تأكيد",
                  middleText: "هل أنت متأكد أنك تريد تسجيل الخروج؟",
                  confirmTextColor: Colors.white,
                  textConfirm: "نعم",
                  textCancel: "إلغاء",
                  onConfirm: () => Get.back(result: true),
                  onCancel: () => Get.back(result: false),
                );

                if (confirmed == true) {
                  final success = await AuthService().logout();
                  if (success) {
                    Get.offAllNamed('/login');
                    Get.snackbar("تسجيل الخروج", "✅ تم تسجيل الخروج بنجاح");
                  } else {
                    Get.snackbar("خطأ", "❌ فشل الاتصال بالخادم");
                  }
                }
              },
            ),
          ],
        ),
      ),
      body: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[controller.currentIndex.value],
        ),
      ),
    );
  }
}
