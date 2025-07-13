import 'package:flutter/material.dart';
import 'package:flutter_project_final/Service/profile_service.dart';
import 'package:flutter_project_final/moduels/dashpord/dashboard_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';


class ProfileController extends GetxController {
  // 🧠 المتغيرات المراقبة
  final name = ''.obs;
  final email = ''.obs;
  final password = ''.obs;

  // 🎯 TextEditingControllers لإدارة الحقول
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 🧩 خدمة الملف الشخصي
  final _service = ProfileService();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  // 🔁 تحميل البيانات من السيرفر وتعبئتها داخل الـ controllers
  void loadProfile() async {
    final data = await _service.fetchUserProfile();
    if (data != null) {
      name.value = data['name'] ?? '';
      email.value = data['email'] ?? '';
      nameController.text = name.value;
      emailController.text = email.value;
    } else {
      Get.snackbar("⚠️", "فشل تحميل بيانات المستخدم");
    }
  }

  // 💾 حفظ التعديلات عند الضغط على الزر
  void saveProfile() async {
    name.value = nameController.text;
    email.value = emailController.text;
    password.value = passwordController.text;

    final success = await _service.updateUserProfile(
      name.value,
      email.value,
      password.value,
    );

    if (success) {
  Get.snackbar("تم", "✅ تم تحديث المعلومات بنجاح");
  passwordController.clear();
  loadProfile();

  // 🆕 حفظ الاسم الجديد محليًا وتحديثه
  GetStorage().write('observer_name', name.value);
  Get.find<DashboardController>().refreshObserverName();
}
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}