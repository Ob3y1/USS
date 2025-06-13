import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SupervisorScheduleScreen extends StatefulWidget {
  const SupervisorScheduleScreen({super.key});

  @override
  _SupervisorScheduleScreenState createState() =>
      _SupervisorScheduleScreenState();
}

class _SupervisorScheduleScreenState extends State<SupervisorScheduleScreen> {
  final List<String> days = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
  ];

  final List<String> times = [
    '9:00 - 11:00',
    '12:00 - 2:00',
    '3:00 - 5:00',
  ];

  final List<String> rooms = [
    'قاعة 1',
    'قاعة 2',
    'قاعة 3',
  ];

  // بيانات مراقب وهمية: Map<day, Map<time, Map<room, monitor>>>
  Map<String, Map<String, Map<String, String>>> monitorAssignments = {
    'السبت': {
      '9:00 - 11:00': {
        'قاعة 1': 'أحمد',
        'قاعة 2': 'منى',
        'قاعة 3': 'زياد',
      },
      '12:00 - 2:00': {
        'قاعة 1': 'نور',
        'قاعة 2': 'سعيد',
        'قاعة 3': 'هبة',
      },
      '3:00 - 5:00': {
        'قاعة 1': 'ليلى',
        'قاعة 2': 'جمال',
        'قاعة 3': 'تامر',
      },
    },
    // باقي الأيام فارغة مبدئياً
  };

  // قائمة مراقبين متاحة للاختيار
  final List<String> availableMonitors = [
    'أحمد',
    'منى',
    'زياد',
    'نور',
    'سعيد',
    'هبة',
    'ليلى',
    'جمال',
    'تامر',
    'سامر',
    'هالة',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('جدول مواعيد المراقبة',
            style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.blue),
        backgroundColor: Color.fromARGB(255, 50, 50, 65),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: days.map((day) {
            final dayAssignments = monitorAssignments[day] ?? {};
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يوم $day',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 10),
                Table(
                  border: TableBorder.all(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FixedColumnWidth(120),
                    for (int i = 1; i <= rooms.length; i++)
                      i: const FixedColumnWidth(120),
                    rooms.length + 1:
                        const FixedColumnWidth(80), // عمود التعديل
                  },
                  children: [
                    // Header Row
                    TableRow(
                      children: [
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('الفترة / القاعة',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        ...rooms.map(
                          (room) => TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(room,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        const TableCell(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'تعديل',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Data Rows
                    ...times.map((time) {
                      return TableRow(
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(time, textAlign: TextAlign.center),
                            ),
                          ),
                          ...rooms.map((room) {
                            final monitor = dayAssignments[time]?[room] ?? '-';
                            return TableCell(
                              child: Center(child: Text(monitor)),
                            );
                          }),
                          TableCell(
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final updatedAssignments =
                                    await Navigator.push<Map<String, String>>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditMonitoringPage(
                                      day: day,
                                      time: time,
                                      rooms: rooms,
                                      initialAssignments:
                                          Map.from(dayAssignments[time] ?? {}),
                                      availableMonitors: availableMonitors,
                                    ),
                                  ),
                                );

                                if (updatedAssignments != null) {
                                  setState(() {
                                    monitorAssignments[day] ??= {};
                                    monitorAssignments[day]![time] =
                                        updatedAssignments;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('تم اعتماد الجدول ليوم $day',
                                style: TextStyle(color: Colors.white))),
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('اعتماد الجدول',
                        style: TextStyle(color: Colors.blue)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50),
                  ),
                ),
                const Divider(height: 40, thickness: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class EditMonitoringPage extends StatefulWidget {
  final String day;
  final String time;
  final List<String> rooms;
  final Map<String, String> initialAssignments;
  final List<String> availableMonitors;

  const EditMonitoringPage({
    Key? key,
    required this.day,
    required this.time,
    required this.rooms,
    required this.initialAssignments,
    required this.availableMonitors,
  }) : super(key: key);

  @override
  _EditMonitoringPageState createState() => _EditMonitoringPageState();
}

class _EditMonitoringPageState extends State<EditMonitoringPage> {
  late Map<String, String> selectedMonitors;

  @override
  void initState() {
    super.initState();
    selectedMonitors = Map.from(widget.initialAssignments);
    // تأكد وجود قيم لكل قاعة
    for (var room in widget.rooms) {
      selectedMonitors.putIfAbsent(room, () => '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل المراقبين في ${widget.day} - ${widget.time}',
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: widget.rooms.map((room) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child:
                              Text(room, style: const TextStyle(fontSize: 16)),
                        ),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: selectedMonitors[room]!.isNotEmpty
                                ? selectedMonitors[room]
                                : null,
                            items: widget.availableMonitors
                                .map((monitor) => DropdownMenuItem(
                                      value: monitor,
                                      child: Text(monitor),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedMonitors[room] = value ?? '';
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'اختر المراقب',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, selectedMonitors);
              },
              child: const Text('اعتماد التعديلات',
                  style: TextStyle(color: Colors.blue)),
            )
          ],
        ),
      ),
    );
  }
}
