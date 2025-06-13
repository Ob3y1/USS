import 'package:flutter/material.dart';

class EditMonitoringPage extends StatefulWidget {
  final String day;
  final String time;
  final List<String> rooms;
  final Map<String, String> initialAssignments; // غرفة -> مراقب

  final List<String> availableMonitors;

  final Function(Map<String, String>) onSave;

  const EditMonitoringPage({
    Key? key,
    required this.day,
    required this.time,
    required this.rooms,
    required this.initialAssignments,
    required this.availableMonitors,
    required this.onSave,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل المراقبين في ${widget.day} - ${widget.time}'),
      iconTheme: IconThemeData(color: Colors.blue),
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
                widget.onSave(selectedMonitors);
                Navigator.pop(context);
              },
              child: const Text('اعتماد التعديلات'),
            )
          ],
        ),
      ),
    );
  }
}
