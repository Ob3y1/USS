import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_project_final/moduels/Cheating/CheatingDetectionView .dart';
import 'package:get/get.dart';
import 'package:flutter_project_final/Config/service_conf.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DetectionView extends StatelessWidget {
  final DetectionController controller = Get.put(DetectionController());
  @override  Widget build(BuildContext context) {
    return Scaffold( body: Stack(children: [
          // 🌄 الخلفية
         Positioned.fill(
            child: Image.asset(
              'assets/images/AI exam monitoring s.png',          fit: BoxFit.cover,      ),),
          // 🔲 التعتيم Container(color: Colors.black.withOpacity(0.55)),          // 📋 المحتوى
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => Column(   crossAxisAlignment: CrossAxisAlignment.start,children: [
                    const SizedBox(height: 10),
                    const Text(
                      '🚨 الحالات المسجلة',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 🔁 القائمة
                    Expanded(
                      child: controller.detections.isEmpty
                          ? const Center(
                              child: Text(
                                "لا يوجد حالات حالياً",
                                style: TextStyle(color: Colors.white70),
                              ),
                            )
                          : ListView.builder(
                              itemCount: controller.detections.length,
                              itemBuilder: (context, index) {
                                final item = controller.detections[index];

                                final card = ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.07),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.deepPurpleAccent,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              '${ServiceConf.domainNameServer}/storage/snapshots/${item.imageName}',
                                              height: 110,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "📌 النوع: ${item.cheatType}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "🧪 المادة: ${item.subjectName}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "🏛 القاعة: ${item.hall}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "🕒 ${item.examDay} - ${item.examDate} - الساعة ${item.examTime}",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "⏱ وقت الالتقاط: ${item.timestamp}",
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // 📝 الإجراء
                                          TextField(
                                            onChanged: (val) =>
                                                item.actionTaken.value = val,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: '📝 الإجراء المتخذ...',
                                              hintStyle: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                              fillColor: Colors.white
                                                  .withOpacity(0.12),
                                              filled: true,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                    horizontal: 12,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  controller.sendAction(item),
                                              icon: const Icon(
                                                Icons.send,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'إرسال',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurpleAccent,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );

                                return card
                                    .animate(
                                      delay: Duration(
                                        milliseconds: 100 * index,
                                      ),
                                    )
                                    .slideY(
                                      begin: 0.2,
                                      duration: Duration(milliseconds: 500),
                                    ).fadeIn(duration: Duration(milliseconds: 500),);},), ),],), ),)),],),);}}
