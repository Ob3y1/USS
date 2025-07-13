import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DashboardController extends GetxController {
  var currentIndex = 0.obs;

  // 🆕 اسم المراقب كمُتغيّر مراقَب
  var observerName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // قراءة الاسم من GetStorage عند تشغيل الصفحة
    observerName.value = GetStorage().read('observer_name') ?? 'المراقب';
  }

  void changePage(int index) {
    currentIndex.value = index;
  }

  // 🆕 استدعِ هذه الدالة لو أردت تحديث الاسم بعد تعديل البيانات مباشرة
  void refreshObserverName() {
    observerName.value = GetStorage().read('observer_name') ?? 'المراقب';
  }
}