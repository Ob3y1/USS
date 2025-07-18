import 'dart:convert';

import 'package:exam_dashboard/models/user.dart';
import 'package:exam_dashboard/profile/show_profile.dart';
import 'package:exam_dashboard/screen/schedule_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'user_state.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitial());
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController subjectNameController = TextEditingController();
  final TextEditingController subjectStudentsController =
      TextEditingController();
  String? selectedLevel;
  String? selectedSpecialization;

  void setSelectedLevel(String? level) {
    selectedLevel = level;
    // عند تغيير المستوى، نعادل الاختصاص
    selectedSpecialization = null;
    emit(state); // أو حسب طريقة تحديث الحالة عندك
  }

  void setSelectedSpecialization(String? specialization) {
    selectedSpecialization = specialization;
    emit(state);
  }

  bool isLoading = false;

  TextEditingController examDateController = TextEditingController();
  final examPeriodFromController = TextEditingController();
  DateTime date = DateTime.now();
  final roomNameController = TextEditingController();
  final roomCapacityController = TextEditingController();
  String? selectedSpecializationId;
  List<TextEditingController> roomCameraControllers = [TextEditingController()];
  var rooms = <Map<String, String>>[];
  String? selectedDay; // هنا نخزن اليوم بالإنجليزية مثلاً
  // قائمة المواد (المواد المخزنة)
  List<Map<String, String>> subjects = [];
  int mapLevelToYear(String? level) {
    print('Mapping level: "$level"');
    if (level == null) return 3;

    switch (level.trim()) {
      case 'المستوى الأول':
        return 1;
      case 'المستوى الثاني':
        return 2;
      case 'المستوى الثالث':
        return 3;
      case 'المستوى الرابع':
        return 4;
      case 'المستوى الخامس':
        return 5;
      default:
        print('Unknown level, returning default 3');
        return 3;
    }
  }

  signIn() async {
    try {
      emit(SignInLoading());

      final response = await Dio().post(
        "http://localhost:8000/api/loginAdmin", // استخدم IP مناسب
        data: {
          "email": emailController.text,
          "password": passwordController.text,
        },
      );

      final token = response.data['token'];

      // ✅ تعريف prefs قبل الاستخدام
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setBool('is_logged_in', true); // إن أردت ذلك أيضًا

      emit(SignInSuccess());
      print("Token saved: $token");
    } on DioError catch (e) {
      emit(SignInFailure(
        errMessage: e.response?.data['message'] ?? 'فشل تسجيل الدخول',
      ));
    } catch (e) {
      emit(SignInFailure(errMessage: e.toString()));
    }
  }

  Future<void> logout(BuildContext context) async {
    print("0000000");
    final prefs = await SharedPreferences.getInstance();

    try {
      final token = prefs.getString("token");
      if (token == null) throw Exception("لم يتم العثور على التوكن");
      print("11111");
      final dio = Dio();
      final response = await dio.post(
        'http://localhost:8000/api/logoutAdmin', // تأكد أن الراوت يستخدم POST
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      print("22222");
      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 'تم تسجيل الخروج بنجاح';

        // عرض إشعار
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ));

        // حذف البيانات
        await prefs.remove('token');
        await prefs.setBool('is_logged_in', false);

        // تأخير بسيط لإتاحة عرض الإشعار
        await Future.delayed(Duration(seconds: 1));

        // الانتقال إلى صفحة تسجيل الدخول
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل تسجيل الخروج: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تسجيل الخروج: $e')),
      );
    }
  }

  Future<void> fetchUserProfile(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      emit(UserError('لم يتم تسجيل الدخول'));
      return;
    }

    try {
      var headers = {'Authorization': 'Bearer $token'};
      var dio = Dio();
      var response = await dio.get(
        'http://localhost:8000/api/showprofile',
        options: Options(headers: headers),
      );

      if (response.statusCode == 201) {
        var user = User.fromJson(response.data['user']);
        emit(UserLoaded(user)); // من الأفضل استخدام حالة Loaded بدل Loading هنا

        // الانتقال إلى صفحة الملف الشخصي بعد النجاح
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(user: user),
          ),
        );
      } else {
        emit(UserError('فشل في جلب الملف الشخصي: ${response.statusMessage}'));
      }
    } catch (e) {
      emit(UserError('حدث خطأ: $e'));
    }
  }

  Future<void> addSubject() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var data = json.encode({
      "name": subjectNameController.text,
      "student_number": subjectStudentsController.text,
      "year": mapLevelToYear(selectedLevel),
      "specialties": selectedSpecializationId == null
          ? []
          : [int.parse(selectedSpecializationId!)],
    });

    var dio = Dio();

    try {
      var response = await dio.request(
        'http://localhost:8000/api/subjects',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        print(json.encode(response.data));
        // هنا يمكنك إضافة أي معالجة إضافية مثل تحديث واجهة المستخدم
      } else {
        print('خطأ: ${response.statusMessage}');
      }
    } catch (e) {
      print('حدث خطأ أثناء الإضافة: $e');
    }
  }

  void sendExamDay() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var dio = Dio();

    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var data = {
      "day": selectedDay, // اسم اليوم
      "date": examDateController.text, // نص التاريخ
    };
    try {
      var response = await dio.post(
        'http://localhost:8000/api/exam-days',
        options: Options(headers: headers),
        data: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        print(response.data);
      } else {
        print('خطأ: ${response.statusMessage}');
      }
    } catch (e) {
      print('حدث خطأ في الطلب: $e');
    }
  }

  void sendExamTime() async {
    var dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var data = {
      "time": examPeriodFromController.text,
    };

    try {
      var response = await dio.post(
        'http://localhost:8000/api/exam-times',
        options: Options(headers: headers),
        data: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        print(response.data);
      } else {
        print('خطأ: ${response.statusMessage}');
      }
    } catch (e) {
      print('حدث خطأ في الطلب: $e');
    }
  }

  void sendHallData() async {
    var dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    var data = {
      "location": roomNameController.text,
      "chair_number": roomCapacityController.text,
      "camera_addresses": roomCameraControllers.map((c) => c.text).toList(),
    };
    print(jsonEncode(data));

    try {
      var response = await dio.post(
        'http://localhost:8000/api/halls',
        options: Options(headers: headers),
        data: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print(response.data);
        var hallId = response.data['hall_id'];
        print('تم إنشاء القاعة برقم: $hallId');
      } else {
        print('خطأ: ${response.statusMessage}');
      }
    } catch (e) {
      print('حدث خطأ في الطلب: $e');
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    var dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      var response = await dio.delete(
        'http://localhost:8000/api/subjects/$subjectId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        print("تم الحذف بنجاح: ${response.data}");
      } else {
        print("فشل الحذف: ${response.statusMessage}");
      }
    } catch (e) {
      print("حدث خطأ أثناء الحذف: $e");
    }
  }

  Future<void> deleteExamDay(int examDayId) async {
    var dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    var headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      var response = await dio.delete(
        'http://localhost:8000/api/exam-days/$examDayId',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print(json.encode(response.data));
      } else {
        print('حدث خطأ: ${response.statusMessage}');
      }
    } catch (e) {
      print('خطأ في الاتصال أو الحذف: $e');
    }
  }

  Future<void> deleteHall(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    var data = json.encode({
      "day": "Saturday",
    });

    var dio = Dio();

    try {
      var response = await dio.request(
        'http://localhost:8000/api/halls/$id',
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        print(json.encode(response.data));
      } else {
        print('Error: ${response.statusMessage}');
      }
    } catch (e) {
      print('Error during delete: $e');
    }
  }

  showsubject(int subjectId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
    };
    var dio = Dio();
    var response = await dio.request(
      'http://localhost:8000/api/subject/$subjectId',
      options: Options(
        method: 'GET',
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
    } else {
      print(response.statusMessage);
    }
  }

  Future<bool> resetSchedules(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        print('Token not found');
        return false;
      }

      var dio = Dio();
      var response = await dio.get(
        'http://localhost:8000/api/resetSchedule',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        print(json.encode(response.data));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تصفير جدول الامتحانات بنجاح.')),
        );
        return true;
      } else {
        print('Error: ${response.statusMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: ${response.statusMessage}')),
        );
        return false;
      }
    } catch (e) {
      print('Exception caught: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ غير متوقع')),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> searchObserver(item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();
    var response = await dio.get(
      'http://localhost:8000/api/searchObserver/$item',
      options: Options(headers: headers),
    );

    if (response.statusCode == 200) {
      print(response.data);
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception('Failed to load observer');
    }
  }

  Future<Map<String, dynamic>> searchDay(item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();
    var response = await dio.get(
      'http://localhost:8000/api/searchDay/$item',
      options: Options(headers: headers),
    );

    if (response.statusCode == 200) {
      print(response.data);
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception('Failed to load day');
    }
  }

  Future<Map<String, dynamic>> searchSubject(item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();
    var response = await dio.get(
      'http://localhost:8000/api/searchSubject/$item',
      options: Options(headers: headers),
    );

    if (response.statusCode == 200) {
      print(response.data);
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception('Failed to load subject');
    }
  }

  Future<Map<String, dynamic>> searchHall(item) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();
    var response = await dio.get(
      'http://localhost:8000/api/searchHall/$item',
      options: Options(headers: headers),
    );

    if (response.statusCode == 200) {
      print(response.data);
      return Map<String, dynamic>.from(response.data);
    } else {
      throw Exception('Failed to load hall');
    }
  }

 Future<void> resetDistribution(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الرمز غير متوفر، يرجى تسجيل الدخول من جديد')),
      );
      return;
    }

    var dio = Dio();
    var response = await dio.request(
      'http://localhost:8000/api/resetDistribution',
      options: Options(
        method: 'GET',
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;

      if (data['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'تمت العملية بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'حدث خطأ أثناء المعالجة')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال بالخادم، رمز الحالة: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('خطأ أثناء إعادة التوزيع: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ غير متوقع: $e')),
    );
  }
}
}
