import 'package:exam_dashboard/Widgit/app_drawer.dart';
import 'package:flutter/material.dart';

class EditSupervisorPage extends StatefulWidget {
  final Map<String, dynamic> supervisor;
  final Function(Map<String, dynamic>) onSave;

  const EditSupervisorPage({
    Key? key,
    required this.supervisor,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditSupervisorPage> createState() => _EditSupervisorPageState();
}

class _EditSupervisorPageState extends State<EditSupervisorPage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  List<String> allDays = ['السبت', 'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'];
  late List<String> selectedDays;
  String status = 'available';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.supervisor['name']);
    emailController = TextEditingController(text: widget.supervisor['email']);
    selectedDays = List<String>.from(widget.supervisor['workingDays']);
    status = widget.supervisor['status'];
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void toggleDay(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day);
      } else {
        selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل معلومات المراقب'),iconTheme: IconThemeData(color: Colors.blue),),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            ),
            const SizedBox(height: 16),
            const Text('أيام الدوام:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: allDays.map((day) {
                return FilterChip(
                  label: Text(day),
                  selected: selectedDays.contains(day),
                  onSelected: (_) => toggleDay(day),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('الحالة:', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: status,
              items: const [
                DropdownMenuItem(value: 'available', child: Text('متاح')),
                DropdownMenuItem(value: 'busy', child: Text('في المراقبة')),
                DropdownMenuItem(value: 'unavailable', child: Text('غير متاح')),
              ],
              onChanged: (value) {
                setState(() {
                  status = value!;
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
  onPressed: () {
    final updated = {
      'name': nameController.text,
      'email': emailController.text,
      'workingDays': selectedDays,
      'status': status,
    };
    widget.onSave(updated); // سيتم إغلاق الصفحة من UserManagementScreen
  },
  child: const Text('حفظ التعديلات'),
),

          ],
        ),
      ),
    );
  }
}
