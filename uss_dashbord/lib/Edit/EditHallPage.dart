import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditHallPage extends StatefulWidget {
  final int hallId;

  const EditHallPage({super.key, required this.hallId});

  @override
  State<EditHallPage> createState() => _EditHallPageState();
}

class _EditHallPageState extends State<EditHallPage> {
  late TextEditingController locationController;
  late TextEditingController chairNumberController;
  List<TextEditingController> cameraControllers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    locationController = TextEditingController();
    chairNumberController = TextEditingController();
    fetchHallData();
  }

  Future<void> fetchHallData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final dio = Dio();
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await dio.get(
        'http://localhost:8000/api/hall/${widget.hallId}',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        locationController.text = data['location'] ?? '';
        chairNumberController.text = data['chair_number'].toString();

        cameraControllers.clear();
        if (data['cameras'] != null) {
          for (var cam in data['cameras']) {
            cameraControllers.add(TextEditingController(text: cam['address']));
          }
        }

        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('فشل في جلب البيانات');
      }
    } catch (e) {
      print("خطأ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء جلب البيانات: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveHallData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final dio = Dio();
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // جمع عناوين الكاميرات من الـ TextControllers
    List<String> cameraAddresses = cameraControllers
        .map((controller) => controller.text.trim())
        .where((address) => address.isNotEmpty)
        .toList();

    final data = json.encode({
      "location": locationController.text.trim(),
      "chair_number": int.tryParse(chairNumberController.text) ?? 0,
      "camera_addresses": cameraAddresses,
    });

    try {
      final response = await dio.put(
        'http://localhost:8000/api/halls/${widget.hallId}',
        options: Options(headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل في حفظ التعديلات: ${response.statusMessage}')),
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response?.data;

        if (responseData is Map && responseData.containsKey('errors')) {
          // جمع رسائل الخطأ في سلسلة واحدة
          final errors = responseData['errors'] as Map<String, dynamic>;
          final errorMessages = errors.values
              .expand((list) => (list as List).map((msg) => msg.toString()))
              .join('\n');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في البيانات:\n$errorMessages')),
          );
        } else if (responseData is Map && responseData.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: ${responseData['message']}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ غير معروف في البيانات')),
          );
        }
      } else {
        print('Error sending request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاتصال: $e')),
        );
      }
    } catch (e) {
      print("خطأ أثناء الحفظ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
      );
    }
  }

  @override
  void dispose() {
    locationController.dispose();
    chairNumberController.dispose();
    for (var controller in cameraControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void addCameraField() {
    setState(() {
      cameraControllers.add(TextEditingController());
    });
  }

  void removeCameraField(int index) {
    setState(() {
      cameraControllers[index].dispose();
      cameraControllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      appBar: AppBar(
        title: const Text(
          'تعديل القاعة',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 50, 50, 65),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'مكان القاعة',
                      labelStyle: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    controller: chairNumberController,
                    decoration: const InputDecoration(
                      labelText: 'عدد الكراسي',
                      labelStyle: const TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'عناوين الكاميرات:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.lightBlueAccent),
                      ),
                      ElevatedButton.icon(
                        onPressed: addCameraField,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة كاميرا'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...cameraControllers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    TextEditingController ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              controller: ctrl,
                              decoration: InputDecoration(
                                labelText: 'عنوان كاميرا ${idx + 1}',
                                labelStyle: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeCameraField(idx),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saveHallData,
                    child: const Text(
                      'حفظ التعديلات',
                      style: const TextStyle(color: Colors.lightBlueAccent),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
