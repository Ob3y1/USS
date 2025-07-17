import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:exam_dashboard/models/user.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isLoading = false;

  late User currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user; // نسخة يمكن تعديلها
    nameController = TextEditingController(text: currentUser.name);
    emailController = TextEditingController(text: currentUser.email);
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> updateProfile(
      String token, String name, String email, String password) async {
    setState(() => isLoading = true);

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var data = {
      "name": name,
      "email": email,
    };

    if (password.isNotEmpty) {
      data["password"] = password;
    }

    var dio = Dio();

    try {
      var response = await dio.post(
        'http://localhost:8000/api/updateprofile',
        options: Options(headers: headers),
        data: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // تحديث نسخة المستخدم الحالية في الواجهة
        setState(() {
          currentUser = currentUser.copyWith(name: name, email: email);
          nameController.text = name;
          emailController.text = email;
          passwordController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث الملف الشخصي بنجاح')),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل التحديث: ${response.statusMessage}')),
        );
        return false;
      }
    } on DioError catch (e) {
      String errorMessage = 'حدث خطأ غير معروف';
      if (e.response != null) {
        errorMessage = 'خطأ من السيرفر: ${e.response?.data}';
      } else {
        errorMessage = 'خطأ أثناء الطلب: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return false;
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showEditDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم تسجيل الدخول')),
      );
      return;
    }

    // تحديث الحقول للنصوص الحالية
    nameController.text = currentUser.name;
    emailController.text = currentUser.email;
    passwordController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('تعديل الملف الشخصي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              TextField(
                controller: emailController,
                decoration:
                    const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (name.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('الرجاء ملء الاسم والبريد')),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);

                      bool success =
                          await updateProfile(token, name, email, password);

                      setStateDialog(() => isLoading = false);

                      if (success) {
                        Navigator.pop(context);
                      }
                      // إذا لم ينجح التحديث لا يغلق الديالوج
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          "الملف الشخصي",
          style: TextStyle(
            color: Colors.black87, // تغيير لون النص إلى الأسود
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: Colors.white, // خلفية بيضاء
        elevation: 1, // ظل خفيف للتمييز
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 60, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            Card(
              color: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.blue),
                title: const Text("الاسم",
                    style: TextStyle(color: Colors.black87)),
                subtitle: Text(user.name,
                    style: const TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              color: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text("البريد الإلكتروني",
                    style: TextStyle(color: Colors.black87)),
                subtitle: Text(user.email,
                    style: const TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 15),
            Card(
              color: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const ListTile(
                leading: Icon(Icons.lock, color: Colors.blue),
                title: Text("كلمة المرور",
                    style: TextStyle(color: Colors.black87)),
                subtitle:
                    Text("********", style: TextStyle(color: Colors.black87)),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: showEditDialog,
              icon: const Icon(Icons.edit),
              label: const Text("تعديل المعلومات"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.black87,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
