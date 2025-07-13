import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'schedule_controller.dart';

class ScheduleView extends StatelessWidget {
  final ScheduleController controller = Get.put(ScheduleController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 📸 الخلفية
          Positioned.fill(
            child: Image.asset(
              'assets/images/نظام مراقبة القاعات .png', // ← ضع الصورة في مجلد assets
              fit: BoxFit.cover,
            ),
          ),

          // 🔲 التعتيم (اختياري)
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.6),
          ),

          // 🧱 المحتوى فوق الخلفية
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      "📅 جدول المراقبة",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Obx(
                      () => controller.schedule.isEmpty
                          ? const Center(
                              child: Text(
                                "لا يوجد مواعيد حالياً",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: controller.schedule.length,
                              itemBuilder: (context, index) {
                                final item = controller.schedule[index];
                                return Center(
                                  child: Container(
                                    width: 650,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      // ignore: deprecated_member_use
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.deepPurpleAccent,
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          // ignore: deprecated_member_use
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.event,
                                        color: Colors.deepPurpleAccent,
                                      ),
                                      title: Text(
                                        item.examName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${item.subjectList}\n${item.day} - ${item.date} - الساعة ${item.time}",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                      trailing: Text(
                                        item.hall,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
