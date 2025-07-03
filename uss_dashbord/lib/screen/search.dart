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

  List<Widget> _buildResultWidgets(String title, Map<String, dynamic> data) {
    List<Widget> widgets = [];

    switch (title) {
      case 'المراقبون':
        widgets.add(Text('المعرف: ${data['observer_id']}'));
        widgets.add(Text('الاسم: ${data['observer_name']}'));
        widgets.add(const Text('أيام الدوام:',
            style: TextStyle(fontWeight: FontWeight.bold)));
        for (var day in data['working_days'] ?? []) {
          widgets.add(Text('- ${day['day']}'));
        }
        break;

      case 'أيام الامتحان':
        widgets.add(Text('معرف اليوم: ${data['exam_day_id']}'));
        widgets.add(const Text('أوقات الامتحان:'));
        for (var t in data['times'] ?? []) {
          widgets.add(Text('- ${t.toString()}'));
        }
        break;

      case 'المواد':
        var subject = data['subject'] ?? {};
        var exam = data['exam'] ?? {};
        widgets.add(Text('المعرف: ${subject['id']}'));
        widgets.add(Text('الاسم: ${subject['name']}'));
        widgets.add(Text('عدد الطلاب: ${subject['student_number']}'));
        widgets.add(Text('السنة: ${subject['year']}'));
        widgets.add(const SizedBox(height: 8));
        widgets.add(Text(
            'تاريخ الامتحان: ${exam['date']} (${exam['day']}) - ${exam['time']}'));
        break;

      case 'القاعات':
        var hall = data['hall'] ?? {};
        widgets.add(Text('المعرف: ${hall['id']}'));
        widgets.add(Text('الموقع: ${hall['location']}'));
        widgets.add(Text('عدد المقاعد: ${hall['chair_number']}'));
        widgets.add(const Text('الكاميرات:',
            style: TextStyle(fontWeight: FontWeight.bold)));
        for (var cam in data['cameras'] ?? []) {
          widgets.add(Text('- ${cam['address']}'));
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
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blue),
            onPressed: () {
              _showSearchDialog(title, onSearch);
            },
          ),
        ],
      ),
      children: items
          .map((item) => ListTile(
                title: Text(getText(item),
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
        title: const Text('عرض البيانات',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      drawer: const AppDrawer(),
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            final observers = data['observers'] ?? [];
            final examDays = data['exam_days'] ?? [];
            final subjects = data['subjects'] ?? [];
            final halls = data['halls'] ?? [];

            return ListView(
              padding: const EdgeInsets.all(10),
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
