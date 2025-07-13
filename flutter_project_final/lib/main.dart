import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_project_final/getx_bainding/DashboardBinding.dart';
import 'package:flutter_project_final/getx_bainding/login_binding.dart';
import 'package:flutter_project_final/moduels/dashpord/dashboard_view.dart';
import 'package:flutter_project_final/moduels/login/login_view.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(); // تهيئة التخزين المحلي
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final box = GetStorage();

  @override
  Widget build(BuildContext context) {
    final initialRoute = box.read('isLoggedIn') == true
        ? '/monitor_dashboard'
        : '/login';

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      builder: EasyLoading.init(),
      getPages: [
        GetPage(
          name: '/login',
          page: () => LoginView(),
          binding: LoginBinding(),
        ),
       GetPage(
  name: '/monitor_dashboard',
  page: () => DashboardView(),
  binding: DashboardBinding(), // ← هذا هو فقط ما تحتاجه
),

      ],
    );
  }
}
