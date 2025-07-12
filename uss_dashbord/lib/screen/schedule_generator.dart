import 'package:dio/dio.dart';
import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:exam_dashboard/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;

class FullSchedulePage extends StatefulWidget {
  @override
  _FullSchedulePageState createState() => _FullSchedulePageState();
}

class _FullSchedulePageState extends State<FullSchedulePage> {
  List<dynamic> schedule = [];
  List<dynamic> examDays = [];
  final pdf = pw.Document();
  Map<String, String> getDayAndDate(int dayId) {
    final dayData =
        examDays.firstWhere((e) => e['id'] == dayId, orElse: () => null);
    if (dayData != null) {
      return {
        'day': dayData['day'],
        'date': dayData['date'],
      };
    } else {
      return {'day': 'غير معروف', 'date': 'غير معروف'};
    }
  }

  Future<pw.Document> buildPdf(Map<String, Map<String, dynamic>> organizedData,
      List<String> slotLabels) async {
    final pdf = pw.Document();

    // تحميل الخط العربي
    final arabicFont =
        await rootBundle.load("assets/fonts/static/Cairo-Regular.ttf");
    final ttf = pw.Font.ttf(arabicFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Center(
              child: pw.Text(
                'الجدول الامتحاني',
                textDirection: pw.TextDirection.rtl,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['اليوم', 'التاريخ', ...slotLabels],
              data: organizedData.entries.map((entry) {
                final value = entry.value;
                final day = value['day'];
                final date = value['date'];
                final slots = value['slots'] as Map<String, List<String>>;

                return [
                  day,
                  date,
                  ...slotLabels.map((slot) {
                    final subjects = slots[slot] ?? [];
                    if (subjects.isEmpty) return '-';
                    return subjects.join('\n');
                  }).toList(),
                ];
              }).toList(),
              border: pw.TableBorder.all(),
              cellAlignment: pw.Alignment.centerRight,
              headerStyle: pw.TextStyle(
                font: ttf,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey800),
              cellStyle: pw.TextStyle(
                font: ttf,
                fontSize: 10,
              ),
              headerHeight: 25,
              cellHeight: 30,
              cellAlignments: {
                for (var i = 0; i < slotLabels.length + 2; i++)
                  i: pw.Alignment.centerRight
              },
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  Future<void> generateSchedule() async {
    final response =
        await http.get(Uri.parse('http://localhost:8001/generate'));

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBody);

      print(data); // التأكد من وصول البيانات

      // 🟢 تحديث الحالة وحفظ البيانات في المتغير المحلي schedule
      setState(() {
        schedule = data.map((item) {
          final matchedDay = examDays.firstWhere(
            (day) => day['id'] == item['day'],
            orElse: () => null,
          );

          return {
            ...item,
            'day': matchedDay != null ? matchedDay['day'] : 'غير معروف',
            'date': matchedDay != null ? matchedDay['date'] : '',
          };
        }).toList();
      });
      print(schedule);
    } else {
      print('حدث خطأ في الاتصال: ${response.statusCode}');
    }
  }

  Future<void> sendSchedules(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    var headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };

    var dio = Dio();
    var response = await dio.post(
      'http://localhost:8000/api/schedules',
      data: json.encode(data), // ترسل البيانات مشفرة JSON
      options: Options(headers: headers),
    );
    print("Data to send: ${json.encode(data)}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("تم حفظ الجدول بنجاح");
      print(response);
    } else {
      print("فشل في حفظ الجدول: ${response.statusMessage}");
    }
  }

  Future<void> fetchSavedSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('token'); // أو يمكنك استخدام التوكن الثابت مؤقتًا

    var headers = {
      'Authorization': 'Bearer $token', // ضع التوكن الثابت هنا إذا أردت
      'Content-Type': 'application/json'
    };

    try {
      var dio = Dio();
      var response = await dio.get(
        'http://localhost:8000/api/schedules',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print("الجدول المحفوظ: ${json.encode(response.data)}");
        setState(() {
          examDays = response.data['exam_days'];
          schedule = response.data['schedule']; // أو فك تشفيره إذا كان String
        });
      } else {
        print("فشل في جلب الجدول: ${response.statusMessage}");
      }
    } catch (e) {
      print("خطأ أثناء جلب الجدول: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSavedSchedule(); // عرض البيانات القديمة مباشرة
  }

  @override
  Widget build(BuildContext context) {
    // تنظيم البيانات: {day|date: {day, date, slots: {slot: [subjects]}}}
    Map<String, Map<String, dynamic>> organizedData = {};
    for (var item in schedule) {
      final day = item['day'].toString();
      final date = item['date'].toString();
      final dayKey = '$day|$date';
      final slot =
          item['slot']?.toString() ?? item['time']?.toString() ?? 'غير محدد';
      final subject = item['subject'].toString();

      organizedData.putIfAbsent(
        dayKey,
        () => {
          'day': day,
          'date': date,
          'slots': <String, List<String>>{},
        },
      );

      Map<String, List<String>> slots = organizedData[dayKey]!['slots'];
      slots.putIfAbsent(slot, () => []);
      slots[slot]!.add(subject);
    }

    // ترتيب slotLabels حسب الوقت الحقيقي
    final slotLabels = schedule
        .map((item) =>
            item['slot']?.toString() ?? item['time']?.toString() ?? 'غير محدد')
        .toSet()
        .toList()
      ..sort((a, b) {
        try {
          final timeA = TimeOfDay(
              hour: int.parse(a.split(':')[0]),
              minute: int.parse(a.split(':')[1]));
          final timeB = TimeOfDay(
              hour: int.parse(b.split(':')[0]),
              minute: int.parse(b.split(':')[1]));
          return timeA.hour.compareTo(timeB.hour) != 0
              ? timeA.hour.compareTo(timeB.hour)
              : timeA.minute.compareTo(timeB.minute);
        } catch (e) {
          return a.compareTo(b); // في حال فشل التحويل
        }
      });

    // ترتيب organizedData حسب التاريخ
    final sortedEntries = organizedData.entries.toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.value['date']) ?? DateTime(2100);
        final dateB = DateTime.tryParse(b.value['date']) ?? DateTime(2100);
        return dateA.compareTo(dateB);
      });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'الجدول الامتحاني',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: {
                  0: const FixedColumnWidth(100),
                  1: const FixedColumnWidth(100),
                  for (int i = 2; i < 2 + slotLabels.length; i++)
                    i: const FixedColumnWidth(200),
                },
                children: [
                  // رأس الجدول
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 61, 61, 68),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('اليوم',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('التاريخ',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white)),
                      ),
                      ...slotLabels.map(
                        (slot) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(slot,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white)),
                        ),
                      ),
                    ],
                  ),

                  // صفوف البيانات المرتبة حسب التاريخ
                  ...sortedEntries.map((entry) {
                    final value = entry.value;
                    final day = value['day'];
                    final date = value['date'];
                    final slots = value['slots'] as Map<String, List<String>>;

                    return TableRow(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 61, 61, 68),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          child: Text(day,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          child: Text(date,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.white),
                              textAlign: TextAlign.center),
                        ),
                        ...slotLabels.map((slot) {
                          final subjects = slots[slot] ?? [];
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: subjects.isNotEmpty
                                  ? subjects.map((subject) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 2),
                                        child: Text(
                                          subject,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white),
                                        ),
                                      );
                                    }).toList()
                                  : [
                                      const Text('-',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white))
                                    ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: generateSchedule,
                child: const Text('توليد الجدول'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final transformed = schedule.map((item) {
                      // نبحث عن اليوم المطابق في examDays
                      final matchedDay = examDays.firstWhere(
                        (day) =>
                            day['day'] == item['day'] &&
                            day['date'] == item['date'],
                        orElse: () => null,
                      );

                      return {
                        'subject': item['subject'],
                        'level': item['level'],
                        'day': matchedDay != null
                            ? matchedDay['id']
                            : 0, // نحصل على id اليوم
                        'slot': item['slot'],
                      };
                    }).toList();

                    await sendSchedules(transformed);
                  } catch (e) {
                    print("خطأ أثناء التحويل أو الإرسال: $e");
                  }
                },
                child: Text('حفظ الجدول'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<UserCubit>().resetSchedules(context);
                },
                child: const Text('تصفير الجدول'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final organizedData = <String, Map<String, dynamic>>{};
                  for (var item in schedule) {
                    final day = item['day'].toString();
                    final date = item['date'].toString();
                    final dayKey = '$day|$date';
                    final slot = item['slot']?.toString() ??
                        item['time']?.toString() ??
                        'غير محدد';
                    final subject = item['subject'].toString();

                    organizedData.putIfAbsent(
                      dayKey,
                      () => {
                        'day': day,
                        'date': date,
                        'slots': <String, List<String>>{},
                      },
                    );

                    Map<String, List<String>> slots =
                        organizedData[dayKey]!['slots'];
                    slots.putIfAbsent(slot, () => []);
                    slots[slot]!.add(subject);
                  }

                  final slotLabels = schedule
                      .map((item) =>
                          item['slot']?.toString() ??
                          item['time']?.toString() ??
                          'غير محدد')
                      .toSet()
                      .toList()
                    ..sort((a, b) {
                      try {
                        final timeA = TimeOfDay(
                            hour: int.parse(a.split(':')[0]),
                            minute: int.parse(a.split(':')[1]));
                        final timeB = TimeOfDay(
                            hour: int.parse(b.split(':')[0]),
                            minute: int.parse(b.split(':')[1]));
                        return timeA.hour.compareTo(timeB.hour) != 0
                            ? timeA.hour.compareTo(timeB.hour)
                            : timeA.minute.compareTo(timeB.minute);
                      } catch (e) {
                        return a.compareTo(b);
                      }
                    });

                  final pdfDoc = await buildPdf(organizedData, slotLabels);
                  await Printing.layoutPdf(onLayout: (format) => pdfDoc.save());
                },
                child: const Text('طباعة الجدول'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
