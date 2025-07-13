import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';
import '../../Components/custom_button.dart';
import '../../Components/custom_textField.dart';

class ProfileView extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎨 الخلفية
          Positioned.fill(
            child: Image.asset(
              'assets/images/log1.png', // ← اسم الصورة
              fit: BoxFit.cover,
            ),
          ),

          // 🔲 تعتيم ناعم
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.6),
          ),

          // 🧱 المحتوى
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: 450,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.deepPurpleAccent, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.deepPurpleAccent,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "👤 تعديل المعلومات الشخصية",
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // الاسم الكامل
                      CustomTextfield(
                        labelText: 'الاسم الكامل',
                        controller: controller.nameController,
                        onChanged: (val) => controller.name.value = val,
                        textColor: Colors.white,
                        suffixIcon: const Icon(Icons.person, color: Colors.white70),
                      ),
                      const SizedBox(height: 15),

                      // البريد الإلكتروني
                      CustomTextfield(
                        labelText: 'البريد الإلكتروني',
                        controller: controller.emailController,
                        onChanged: (val) => controller.email.value = val,
                        keyboard: TextInputType.emailAddress,
                        textColor: Colors.white,
                        suffixIcon: const Icon(Icons.email, color: Colors.white70),
                      ),
                      const SizedBox(height: 15),

                      // كلمة المرور
                      CustomTextfield(
                        labelText: 'كلمة المرور الجديدة',
                        controller: controller.passwordController,
                        onChanged: (val) => controller.password.value = val,
                        isPassword: true,
                        textColor: Colors.white,
                      ),
                      const SizedBox(height: 30),

                      // زر الحفظ
                      CustomButton(
                        width: double.infinity,
                        height: 50,
                        buttonName: '💾 حفظ التعديلات',
                        ButtonColor: Colors.deepPurpleAccent,
                        fontColor: Colors.white,
                        fontSize: 18,
                        onTap: () => controller.saveProfile(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}