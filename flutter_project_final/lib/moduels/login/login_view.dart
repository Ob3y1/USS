import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../Components/custom_button.dart';
import '../../Components/custom_textField.dart';
import 'login_controller.dart';

class LoginView extends StatelessWidget {
  final LoginController controller = Get.find();
  final RxBool isPasswordVisible = false.obs;

  LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Stack(
        children: [
          // خلفية متدرجة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F1F1F), Color(0xFF3A3A3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "👁️ تسجيل الدخول",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextfield(
                      onChanged: (value) => controller.email = value,
                      labelText: "البريد الإلكتروني",
                      keyboard: TextInputType.emailAddress,
                      textColor: Colors.white,
                      suffixIcon: const Icon(Icons.email, color: Colors.white70),
                    ),
                    const SizedBox(height: 15),
                    Obx(() => CustomTextfield(
                          onChanged: (value) => controller.password = value,
                          labelText: "كلمة المرور",
                          keyboard: TextInputType.visiblePassword,
                          textColor: Colors.white,
                          isPassword: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () => isPasswordVisible.toggle(),
                          ),
                        )),
                    const SizedBox(height: 30),
                    CustomButton(
                      width: double.infinity,
                      fontColor: Colors.white,
                      fontSize: 20,
                      ButtonColor: const Color(0xFF7B43E0),
                      height: 50,
                      onTap: () => onClickLogin(),
                      buttonName: "تسجيل الدخول",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onClickLogin() async {
    EasyLoading.show(status: "جاري التحقق...");
    await controller.loginOnClick();

    if (controller.loginStatus) {
      EasyLoading.showSuccess("تم تسجيل الدخول بنجاح");
      Get.offAllNamed('/monitor_dashboard');
    } else {
      EasyLoading.showError(controller.message);
    }
  }
}