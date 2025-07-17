import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchDataScreen extends StatefulWidget {
  @override
  _SearchDataScreenState createState() => _SearchDataScreenState();
}

class _SearchDataScreenState extends State<SearchDataScreen> {
  late Future<Map<String, dynamic>> dataFuture;

  @override
  void initState() {
    super.initState();
    dataFuture = fetchData();
  }

  Future<Map<String, dynamic>> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    var dio = Dio();

    try {
      var response = await dio.request(
        'http://localhost:8000/api/search',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        print(response.data);
        return response.data;
      } else {
        throw Exception('فشل في تحميل البيانات: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('خطأ أثناء الاتصال بالخادم: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطأ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 50, 50, 65),
            )),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 50, 50, 65),
                )),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(
      String title, Future<Map<String, dynamic>> Function(int id) onSearch) {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('ابحث في $title'),
        content: TextField(
          controller: idController,
          decoration: const InputDecoration(labelText: 'أدخل الـ ID'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              int id = int.tryParse(idController.text) ?? 0;
              if (id > 0) {
                try {
                  final result = await onSearch(id);
                  _showResultDialog(title, result);
                } catch (e) {
                  _showErrorDialog('لم يتم العثور على نتيجة بالرقم المدخل');
                }
              }
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(String title, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('نتائج $title'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildResultWidgets(title, result),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildResultWidgets(String title, Map<String, dynamic> data) {
    List<Widget> widgets = [];

    switch (title) {
      case 'المراقبون':
        widgets.add(_buildSectionTitle('👤 معلومات المراقب'));
        widgets.add(_buildInfoRow('المعرف', '${data['observer_id']}'));
        widgets.add(_buildInfoRow('الاسم', '${data['observer_name']}'));

        widgets.add(_buildSectionTitle('📅 أيام الدوام'));
        for (var day in data['working_days'] ?? []) {
          widgets.add(Text('- ${day['day']}'));
        }

        widgets.add(const SizedBox(height: 10));
        widgets.add(_buildSectionTitle('📌 مهام الإشراف'));

        for (var task in data['supervision_tasks'] ?? []) {
          String date = task['date'] ?? '';
          String day = task['day'] ?? '';
          widgets.add(Text('📆 $day - $date',
              style: const TextStyle(fontWeight: FontWeight.bold)));

          for (var timeEntry in task['times'] ?? []) {
            String time = timeEntry['time'] ?? '';
            var hall = timeEntry['hall'] ?? {};
            List subjects = timeEntry['subjects'] ?? [];

            widgets.add(
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('🕒 الوقت', time),
                      _buildInfoRow('📍 القاعة',
                          '${hall['location']} (ID: ${hall['id']})'),
                      const Text('📚 المواد:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      for (var subject in subjects)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- ${subject['name']} (عدد الطلاب: ${subject['students_number']})',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
        break;

      case 'أيام الامتحان':
        widgets.add(
            _buildSectionTitle('معرف يوم الامتحان: ${data['exam_day_id']}'));
        List times = data['times'] ?? [];

        for (var timeEntry in times) {
          String time = timeEntry['time'] ?? '---';
          List halls = timeEntry['halls'] ?? [];

          widgets.add(_buildSectionTitle('🕒 الوقت: $time'));

          for (var hallEntry in halls) {
            var hall = hallEntry['hall'] ?? {};
            var supervisor = hallEntry['supervisor'] ?? {};
            List subjects = hallEntry['subjects'] ?? [];

            widgets.add(
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('📍 القاعة',
                          '${hall['location']} (ID: ${hall['id']})'),
                      _buildInfoRow('👤 المراقب',
                          '${supervisor['name']} (ID: ${supervisor['id']})'),
                      const SizedBox(height: 6),
                      const Text('📚 المواد:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      for (var subject in subjects)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- ${subject['name']} (عدد الطلاب: ${subject['students_number']})',
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
        break;

      case 'المواد':
        var subject = data['subject'] ?? {};
        var exam = data['exam'] ?? {};
        var halls = data['halls'] ?? [];

        widgets.add(Text('المعرف: ${subject['id']}'));
        widgets.add(Text('الاسم: ${subject['name']}'));
        widgets.add(Text('عدد الطلاب: ${subject['student_number']}'));
        widgets.add(Text('السنة: ${subject['year']}'));
        widgets.add(const SizedBox(height: 8));
        widgets.add(Text(
            'تاريخ الامتحان: ${exam['date']} (${exam['day']}) - ${exam['time']}'));

        widgets.add(const SizedBox(height: 8));
        widgets.add(const Text('القاعات:',
            style: TextStyle(fontWeight: FontWeight.bold)));

        for (var hall in halls) {
          widgets.add(Text(
              'المعرف: ${hall['id']} - الموقع: ${hall['location']} - عدد الطلاب: ${hall['students_number']}'));
          var supervisor = hall['supervisor'];
          if (supervisor != null) {
            widgets.add(Text(
                'المراقب: ${supervisor['name']} (ID: ${supervisor['id']})'));
          }
          widgets.add(const Divider());
        }

        break;

      case 'القاعات':
        var hall = data['hall'] ?? {};
        widgets.add(_buildSectionTitle('🏫 معلومات القاعة'));
        widgets.add(_buildInfoRow('المعرف', '${hall['id']}'));
        widgets.add(_buildInfoRow('الموقع', '${hall['location']}'));
        widgets.add(_buildInfoRow('عدد المقاعد', '${hall['chair_number']}'));

        widgets.add(_buildSectionTitle('🎥 الكاميرات'));
        for (var cam in data['cameras'] ?? []) {
          widgets.add(Text('- ${cam['address']}'));
        }

        widgets.add(_buildSectionTitle('📆 أيام الإشغال'));
        for (var day in data['occupied_days'] ?? []) {
          String date = day['date'] ?? '';
          String dayName = day['day'] ?? '';
          widgets.add(Text('📅 $dayName - $date',
              style: const TextStyle(fontWeight: FontWeight.bold)));

          for (var t in day['times'] ?? []) {
            String time = t['time'] ?? '';
            var supervisor = t['supervisor'] ?? {};
            List subjects = t['subjects'] ?? [];

            widgets.add(
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('🕒 الوقت', time),
                      _buildInfoRow('👮‍♂️ المراقب',
                          '${supervisor['name']} (ID: ${supervisor['id']})'),
                      const Text('📚 المواد:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      for (var sub in subjects)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '- ${sub['subject']['name']} (عدد الطلاب: ${sub['students_number']})',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        }
        break;

      default:
        widgets.add(Text(data.toString()));
    }

    return widgets;
  }

  Widget buildSearchableSection({
    required String title,
    required List<dynamic> items,
    required String Function(dynamic) getText,
    required Future<Map<String, dynamic>> Function(int id) onSearch,
  }) {
    return ExpansionTile(
      collapsedBackgroundColor: Colors.white10,
      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      textColor: Colors.white70,
      iconColor: Colors.blueAccent,
      collapsedIconColor: Colors.blueAccent,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 20,
              letterSpacing: 1.1,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blueAccent, size: 26),
            tooltip: 'بحث في $title',
            onPressed: () {
              _showSearchDialog(title, onSearch);
            },
          ),
        ],
      ),
      children: items.map((item) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white30,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                shadowColor: Colors.black54,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(
                    getText(item),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onTap: () async {
                    final details = await onSearch(item['id']);
                    _showDetailsDialog(title, details);
                  },
                  hoverColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showDetailsDialog(String type, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white60,
          title: Text(type,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blueAccent)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildResultWidgets(type, data),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("إغلاق", style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'عرض البيانات',
          style: TextStyle(
            color: Colors.black87, // تغيير لون النص إلى الأسود
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,

        elevation: 1, // ظل خفيف للتمييز
        iconTheme: const IconThemeData(color: Colors.blue),
        shadowColor: Colors.black54,
      ),
      drawer: const AppDrawer(),
      backgroundColor: Colors.white70,
      body: FutureBuilder<Map<String, dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
                strokeWidth: 3,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            );
          } else {
            final data = snapshot.data!;
            final observers = data['observers'] ?? [];
            final examDays = data['exam_days'] ?? [];
            final subjects = data['subjects'] ?? [];
            final halls = data['halls'] ?? [];

            return ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              children: [
                buildSearchableSection(
                  title: "المراقبون",
                  items: observers,
                  getText: (item) => '${item['id']}. ${item['name']}',
                  onSearch: (id) =>
                      context.read<UserCubit>().searchObserver(id),
                ),
                buildSearchableSection(
                  title: "أيام الامتحان",
                  items: examDays,
                  getText: (item) => '${item['day']} - ${item['date']}',
                  onSearch: (id) => context.read<UserCubit>().searchDay(id),
                ),
                buildSearchableSection(
                  title: "المواد",
                  items: subjects,
                  getText: (item) => '${item['id']}. ${item['name']}',
                  onSearch: (id) => context.read<UserCubit>().searchSubject(id),
                ),
                buildSearchableSection(
                  title: "القاعات",
                  items: halls,
                  getText: (item) => '${item['id']}. ${item['location']}',
                  onSearch: (id) => context.read<UserCubit>().searchHall(id),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
