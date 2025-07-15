import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends State<UserManagementScreen> {
  List supervisors = [];
  Map<int, String> workingDayIdToName = {};
  bool isLoading = true;
  final dio = Dio();

  List<int> selectedDayIds = [];
  List<Map<String, dynamic>> availableDays = [];
  List<dynamic> workingDaysList = [];
  List<int> selectedDays = [];

  @override
  void initState() {
    super.initState();
    fetchSupervisors();
  }

  Future<void> fetchSupervisors() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    try {
      var response = await dio.get(
        'http://localhost:8000/api/showusers',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print(response);
        final data = response.data;
        setState(() {
          supervisors = data['supervisors'];
          workingDayIdToName = {
            for (var day in data['workingdays']) day['id']: day['day']
          };
          isLoading = false;
        });
      } else {
        print('Error: ${response.statusMessage}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Exception: $e');
      setState(() => isLoading = false);
    }
  }

  // حذف مشرف
  Future<void> deleteSupervisor(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    try {
      var response = await dio.delete(
        'http://localhost:8000/api/supervisors/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        // إعادة تحميل القائمة بعد الحذف
        fetchSupervisors();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المشرف بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حذف المشرف')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  // فتح شاشة تعديل أو إضافة مشرف
  Future<void> openSupervisorForm({Map? supervisor}) async {
    // هنا يمكن إنشاء صفحة جديدة أو Dialog للفورم
    // بعد الإضافة أو التعديل يتم إعادة تحميل البيانات
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupervisorFormScreen(supervisor: supervisor),
      ),
    );

    if (result == true) {
      fetchSupervisors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          'ادارة المستخدمين',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openSupervisorForm(); // إضافة مشرف جديد (بـ supervisor=null)
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : supervisors.isEmpty
              ? const Center(child: Text('لا يوجد مشرفون.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: supervisors.length,
                  itemBuilder: (context, index) {
                    final supervisor = supervisors[index];
                    final workingDays = (supervisor['working_days'] as List)
                        .map((dayEntry) => dayEntry['day'] as String? ?? '')
                        .toList();

                    return Card(
                      color: const Color.fromARGB(255, 50, 50, 65),
                      elevation: 8, // زيادة الظل لتوضيح أكثر
                      shadowColor:
                          Colors.white.withOpacity(0.5), // لون الظل أبيض شفاف
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                          color: Colors.white, // لون الإطار أبيض
                          width: 1.5, // سمك الإطار
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supervisor['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'البريد: ${supervisor['email']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'الحالة: ${supervisor['status']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أيام الدوام: ${workingDays.isNotEmpty ? workingDays.join(', ') : "لا يوجد"}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    openSupervisorForm(supervisor: supervisor);
                                  },
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  label: const Text(
                                    'تعديل',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'تأكيد الحذف',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                        content: Text(
                                            'هل تريد حذف المشرف ${supervisor['name']}؟'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'إلغاء',
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              deleteSupervisor(
                                                  supervisor['id']);
                                            },
                                            child: const Text(
                                              'حذف',
                                              style:
                                                  TextStyle(color: Colors.blue),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.blue),
                                  label: const Text(
                                    'حذف',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// نموذج شاشة إضافة / تعديل مشرف (يمكنك تعديله حسب API لديك)
class SupervisorFormScreen extends StatefulWidget {
  final Map? supervisor;
  const SupervisorFormScreen({Key? key, this.supervisor}) : super(key: key);

  @override
  State<SupervisorFormScreen> createState() => _SupervisorFormScreenState();
}

class _SupervisorFormScreenState extends State<SupervisorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dio = Dio();
  late TextEditingController nameController;
  late TextEditingController emailController;
  String status = 'active'; // أو حسب حالتك
  late TextEditingController passwordController;
  List<Map<String, dynamic>> allDays = [];
  List<int> selectedDayIds = [];
  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.supervisor?['name'] ?? '');
    emailController =
        TextEditingController(text: widget.supervisor?['email'] ?? '');
    status = widget.supervisor?['status'] ?? 'active';
    passwordController =
        TextEditingController(text: widget.supervisor?['password'] ?? '');

    // لا تعرّف allDays مجددًا هنا
    Map<String, String> engToArabic = {
      'Saturday': 'السبت',
      'Sunday': 'الأحد',
      'Monday': 'الإثنين',
      'Tuesday': 'الثلاثاء',
      'Friday': 'الجمعة',
    };

    List<Map<String, dynamic>> backendDays = [
      {"id": 1, "day": "Friday"},
      {"id": 2, "day": "Saturday"},
      {"id": 3, "day": "Sunday"},
      {"id": 4, "day": "Monday"},
      {"id": 5, "day": "Tuesday"},
    ];

    allDays = backendDays
        .map((d) => {
              'id': d['id'],
              'day': engToArabic[d['day']] ?? d['day'],
            })
        .toList();

    if (widget.supervisor != null) {
      selectedDayIds = List<int>.from(
        widget.supervisor!['working_days'].map((day) => day['id']),
      );
    }
  }

  Future<void> fetchWorkingDays(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};

    try {
      final response = await dio.get(
        'http://localhost:8000/api/supervisors/$id',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print("عدد الأيام: ${allDays.length}");

        setState(() {
          allDays =
              List<Map<String, dynamic>>.from(response.data['workingdays']);
          if (widget.supervisor != null) {
            selectedDayIds = List<int>.from(
              widget.supervisor!['working_days'].map((day) => day['id']),
            );
          }
        });
      }
    } catch (e) {
      print('خطأ أثناء جلب أيام الدوام: $e');
    }
  }

  Future<void> submit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final data = {
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'status': status,
      'day_ids': selectedDayIds,
      'password': passwordController.text.trim(), // إضافة كلمة المرور هنا
    };

    if (selectedDayIds.isEmpty) {
      // إظهار رسالة للمستخدم باختيار أيام الدوام
      print('Please select at least one working day');
      return;
    }

    try {
      if (widget.supervisor == null) {
        await dio.post(
          'http://localhost:8000/api/supervisors',
          data: data,
          options: Options(headers: headers),
        );
      } else {
        final id = widget.supervisor!['id'];
        await dio.put(
          'http://localhost:8000/api/supervisors/$id',
          data: data,
          options: Options(headers: headers),
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;

        if (errors != null) {
          String message = '';

          errors.forEach((key, value) {
            message += '${value[0]}\n'; // عرض أول خطأ لكل حقل
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.trim()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء الإرسال'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        title: Text(
          widget.supervisor == null ? 'إضافة مشرف' : 'تعديل مشرف',
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'الرجاء إدخال الاسم'
                    : null,
              ),
              TextFormField(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'الرجاء إدخال البريد الإلكتروني';
                  if (!value.contains('@')) return 'البريد الإلكتروني غير صالح';
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: widget.supervisor == null
                      ? 'كلمة المرور'
                      : 'كلمة المرور (اختياري)',
                  labelStyle: const TextStyle(color: Colors.white),
                  counterStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                validator: (value) {
                  if (widget.supervisor == null) {
                    if (value == null || value.isEmpty)
                      return 'الرجاء إدخال كلمة المرور';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
                value: status,
                decoration: const InputDecoration(
                  labelText: 'الحالة',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('نشط')),
                  DropdownMenuItem(value: 'inactive', child: Text('غير نشط')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => status = val);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'أيام الدوام:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent,
                ),
              ),
              ...allDays.map((day) {
                return CheckboxListTile(
                  title: Text(
                    day['day'],
                    style: const TextStyle(color: Colors.white),
                  ),
                  value: selectedDayIds.contains(day['id']),
                  onChanged: (bool? checked) {
                    setState(() {
                      if (checked == true) {
                        selectedDayIds.add(day['id']);
                      } else {
                        selectedDayIds.remove(day['id']);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Colors.lightBlueAccent,
                );
              }).toList(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: submit,
                child: Text(
                  widget.supervisor == null ? 'إضافة' : 'تحديث',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
