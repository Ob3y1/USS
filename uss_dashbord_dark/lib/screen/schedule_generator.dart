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
  bool isDragEnabled = false; // تفعيل السحب فقط بعد "توليد الجدول"
  String? draggedSubject;
  String? fromDayKey;
  String? fromSlot;
  bool isSaved = false;

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
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey800),
                  children: [
                    ...['اليوم', 'التاريخ', ...slotLabels].map(
                      (text) => pw.Container(
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          text,
                          style: pw.TextStyle(
                            font: ttf,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...organizedData.entries.map((entry) {
                  final value = entry.value;
                  final day = value['day'];
                  final date = value['date'];
                  final slots = value['slots'] as Map<String, List<String>>;

                  return pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          day,
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          date,
                          style: pw.TextStyle(font: ttf, fontSize: 10),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                      ...slotLabels.map((slot) {
                        final subjects = slots[slot] ?? [];
                        final text =
                            subjects.isEmpty ? '-' : subjects.join('\n');
                        return pw.Container(
                          alignment: pw.Alignment.centerRight,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            text,
                            style: pw.TextStyle(font: ttf, fontSize: 10),
                            textDirection: pw.TextDirection.rtl,
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ],
            )
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
      print(response);
    } else {
      print("فشل في حفظ الجدول: ${response.statusMessage}");
    }
    Future<void> sendSchedules(dynamic data) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      var headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };

      var dio = Dio();
      try {
        var response = await dio.post(
          'http://localhost:8000/api/schedules',
          data: json.encode(data),
          options: Options(headers: headers),
        );

        print("Data to send: ${json.encode(data)}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          print("تم حفظ الجدول بنجاح");
        } else if (response.statusCode == 202) {
          throw Exception("لم يتم الحفظ: الجدول ممتلئ مسبقًا");
        } else {
          print(response.statusCode);
          throw Exception("فشل في حفظ الجدول: ${response.statusMessage}");
        }
      } catch (e) {
        // أرمي الاستثناء لكي يتم التعامل معه في واجهة المستخدم (مثل SnackBar)
        rethrow;
      }
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
                          return DragTarget<String>(
                            onWillAccept: (_) => isDragEnabled,
                            onAccept: (subject) {
                              if (!isDragEnabled || draggedSubject == null)
                                return;

                              // احذف من الموقع القديم
                              setState(() {
                                if (fromDayKey != null && fromSlot != null) {
                                  organizedData[fromDayKey]!['slots']
                                          [fromSlot!]!
                                      .remove(subject);
                                }

                                // أضف للموقع الجديد
                                slots.putIfAbsent(slot, () => []);
                                slots[slot]!.add(subject);

                                // عدل أيضا في schedule
                                final index = schedule.indexWhere((item) =>
                                    item['subject'] == subject &&
                                    item['day'] == fromDayKey!.split('|')[0] &&
                                    item['date'] == fromDayKey!.split('|')[1] &&
                                    (item['slot'] == fromSlot ||
                                        item['time'] == fromSlot));
                                if (index != -1) {
                                  schedule[index]['day'] = day;
                                  schedule[index]['date'] = date;
                                  schedule[index]['slot'] = slot;
                                }
                              });
                            },
                            builder: (context, candidateData, rejectedData) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: subjects.isNotEmpty
                                      ? subjects.map((subject) {
                                          return isDragEnabled
                                              ? Draggable<String>(
                                                  data: subject,
                                                  feedback: Material(
                                                    color: Colors.transparent,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(subject,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white)),
                                                    ),
                                                  ),
                                                  childWhenDragging: Opacity(
                                                    opacity: 0.3,
                                                    child: Text(subject,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                  onDragStarted: () {
                                                    draggedSubject = subject;
                                                    fromDayKey = entry.key;
                                                    fromSlot = slot;
                                                  },
                                                  onDraggableCanceled: (_, __) {
                                                    draggedSubject = null;
                                                    fromDayKey = null;
                                                    fromSlot = null;
                                                  },
                                                  onDragEnd: (_) {
                                                    draggedSubject = null;
                                                    fromDayKey = null;
                                                    fromSlot = null;
                                                  },
                                                  child: Text(subject,
                                                      style: const TextStyle(
                                                          color: Colors.white)),
                                                )
                                              : Text(subject,
                                                  style: const TextStyle(
                                                      color: Colors.white));
                                        }).toList()
                                      : [
                                          const Text('-',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white))
                                        ],
                                ),
                              );
                            },
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
                onPressed: () {
                  generateSchedule(); // دالة توليد الجدول
                  setState(() {
                    isDragEnabled = true;
                    isSaved = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم توليد الجدول')),
                  );
                },
                child: const Text('توليد الجدول'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final transformed = schedule.map((item) {
                      final matchedDay = examDays.firstWhere(
                        (day) =>
                            day['day'] == item['day'] &&
                            day['date'] == item['date'],
                        orElse: () => null,
                      );

                      return {
                        'subject': item['subject'],
                        'level': item['level'],
                        'day': matchedDay != null ? matchedDay['id'] : 0,
                        'slot': item['slot'],
                      };
                    }).toList();

                    await sendSchedules(transformed);

                    setState(() {
                      isSaved = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حفظ الجدول بنجاح')),
                    );
                  } catch (e) {
                    print(
                        'جدول الامتحانات يحتوي على بيانات. يرجى التصفير أولاً قبل إدخال بيانات جديدة.');
                  }
                },
                child: const Text('حفظ الجدول'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  context.read<UserCubit>().resetSchedules(context);

                  setState(() {
                    schedule.clear();
                    isSaved = false;
                    isDragEnabled = false;
                  });
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
