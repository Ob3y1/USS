import 'package:flutter/material.dart';

class EditHallPage extends StatefulWidget {
  final Map<String, dynamic> hallData;

  const EditHallPage({super.key, required this.hallData});

  @override
  State<EditHallPage> createState() => _EditHallPageState();
}

class _EditHallPageState extends State<EditHallPage> {
  late TextEditingController nameController;
  late TextEditingController capacityController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.hallData['name'] ?? '');
    capacityController = TextEditingController(text: widget.hallData['capacity']?.toString() ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل القاعة')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم القاعة'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'سعة القاعة'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // هنا يمكنك تنفيذ تحديث البيانات عبر API
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}
