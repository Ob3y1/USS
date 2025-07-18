import 'package:dio/dio.dart';
import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchStatistics();
  }

  Future<void> fetchStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    const url = 'http://localhost:8000/api/statistics';
    final headers = {
      'Authorization': 'Bearer $token',
    };
    try {
      var dio = Dio();
      var response = await dio.get(url, options: Options(headers: headers));
      if (response.statusCode == 200) {
        print(token);
        setState(() {
          data = response.data;
          isLoading = false;
          error = null;
        });
      } else {
        setState(() {
          error = 'خطأ في تحميل البيانات: ${response.statusMessage}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'حدث خطأ: $e';
        isLoading = false;
      });
    }
  }

  Widget buildCard(String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E43),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(height: 8),
            child, // لا تستخدم Expanded هنا، فقط مرر الـ Widget كما هو
          ],
        ),
      ),
    );
  }

  Widget buildUsersCard() {
    final users = data!['users'];
    return buildCard(
      "المستخدمون",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("الإجمالي: ${users['total']}", style: _cardTextStyle()),
          Text("نشطون: ${users['active']}", style: _cardTextStyle()),
          Text("مشغولون: ${users['busy']}", style: _cardTextStyle()),
          Text("غير نشطين: ${users['inactive']}", style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildSubjectsCard() {
    final subjects = data!['subjects'];
    return buildCard(
      "المواد",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("عدد المواد: ${subjects['total']}", style: _cardTextStyle()),
          Text("عدد الطلاب الكلي: ${subjects['total_students']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildHallsCard() {
    final halls = data!['halls'];
    return buildCard(
      "القاعات",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("عدد القاعات: ${halls['total']}", style: _cardTextStyle()),
          Text("عدد الكراسي الكلي: ${halls['total_chairs']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildcamerasCard() {
    final camera = data!['cameras'];
    return buildCard(
      "الكاميرات",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("عدد الكاميرات: ${camera['total']}", style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildexamdaysCard() {
    final exam_days = data!['exam_days'];
    return buildCard(
      "ايام الامتحانات",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("عدد الامتحانات: ${exam_days['total']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildexamtimesCard() {
    final exam_times = data!['exam_times'];
    return buildCard(
      "اوقات الامتحانات",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("اوقات الامتحانات: ${exam_times['total']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildschedulesCard() {
    final schedules = data!['schedules'];
    return buildCard(
      "الجداول",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("الجداول: ${schedules['total']}", style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildspecialtiesCard() {
    final specialties = data!['specialties num'];
    return buildCard(
      "مجموع الاختصاصات",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("مجموع الاختصاصات: ${specialties['total']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget builddistributionsCard() {
    final distributions = data!['distributions'];
    return buildCard(
      "التوزيع",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("مجموع التوزيع: ${distributions['total']}",
              style: _cardTextStyle()),
          Text(
              "اجمالي توزيع الطلاب: ${distributions['total_students_distributed']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildworkingdaysCard() {
    final working_days = data!['working_days'];
    return buildCard(
      "ايام العمل ",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("ايام العمل : ${working_days['total']}",
              style: _cardTextStyle()),
        ],
      ),
    );
  }

  Widget buildCheatingIncidentsCard() {
    final cheating = data!['cheating_incidents'];
    final types = cheating['types_count'] as List<dynamic>;
    return buildCard(
      "حالات الغش المكتشفة",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("الإجمالي: ${cheating['total']}", style: _cardTextStyle()),
          const SizedBox(height: 8),
          ...types.map((type) => Text(
                "${type['cheating_type']}: ${type['total']} حالة",
                style: _cardTextStyle(color: Colors.orangeAccent),
              )),
        ],
      ),
    );
  }

  Widget buildTopCheatingHallsCard() {
    final halls = data!['top_cheating_halls'] as List<dynamic>;
    return buildCard(
      "أكثر القاعات حدوثاً لحالات الغش",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: halls
            .map((h) => Text("${h['location']}: ${h['cheating_count']} حالة",
                style: _cardTextStyle()))
            .toList(),
      ),
    );
  }

  Widget buildTopCheatingObserversCard() {
    final observers = data!['top_cheating_observers'] as List<dynamic>;
    return buildCard(
      "المراقبون الأكثر تسجيلًا لحالات الغش",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: observers
            .map((o) => Text("${o['name']}: ${o['cheating_reports']} تقرير غش",
                style: _cardTextStyle()))
            .toList(),
      ),
    );
  }

  Widget buildLowestCheatingObserversCard() {
    final observers = data!['lowest_cheating_observers'] as List<dynamic>;
    return buildCard(
      "المراقبون الأقل في تسجيل الغش مع عدد الإشرافات",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: observers
            .map((o) => Text(
                "${o['name']}: ${o['cheating_reports']} تقرير غش، عدد الإشرافات: ${o['total_supervisions']}",
                style: _cardTextStyle()))
            .toList(),
      ),
    );
  }

  Widget buildFrequentCheatingDaysCard() {
    final days = data!['frequent_cheating_days'] as List<dynamic>;
    return buildCard(
      "أيام الغش الأكثر تكرارًا",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: days
            .map((d) => Text(
                "${d['day']} (${d['date']}): ${d['cheating_count']} حالة",
                style: _cardTextStyle()))
            .toList(),
      ),
    );
  }

  Widget buildFrequentCheatingTimesCard() {
    final times = data!['frequent_cheating_times'] as List<dynamic>;
    return buildCard(
      "أوقات الغش الأكثر تكرارًا",
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: times
            .map((t) => Text("${t['time']}: ${t['cheating_count']} حالة",
                style: _cardTextStyle()))
            .toList(),
      ),
    );
  }

  TextStyle _cardTextStyle({Color color = Colors.white70}) {
    return TextStyle(
      fontSize: 14,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    // قائمة كل البطاقات جاهزة للعرض
    final cards = data == null
        ? []
        : [
            buildUsersCard(),
            buildSubjectsCard(),
            buildHallsCard(),
            buildCheatingIncidentsCard(),
            buildTopCheatingHallsCard(),
            buildTopCheatingObserversCard(),
            buildLowestCheatingObserversCard(),
            buildFrequentCheatingDaysCard(),
            buildFrequentCheatingTimesCard(),
            buildworkingdaysCard(),
            buildexamtimesCard(),
            buildexamdaysCard(),
            buildcamerasCard(),
            builddistributionsCard(),
            buildschedulesCard(),
            buildspecialtiesCard(),
          ];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      drawer: const AppDrawer(),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
        title: const Text(
          'الإحصائيات',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              return cards[index];
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
