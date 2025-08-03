
# 🛰️ University Services System (USS)

نظام مراقبة جامعي ذكي متكامل لإدارة الامتحانات، يعتمد على تقنيات حديثة مثل: الرؤية الحاسوبية، الخوارزميات الجينية، البرمجة الخطية، وتطبيقات Flutter ولوحة تحكم Laravel.

---

## 🧭 محتويات المشروع

```bash
uss/
├── backend/              # Laravel API (لوحة تحكم الأدمن، إدارة الامتحانات)
├── admin_app/            # تطبيق Flutter لمشرف النظام
├── observer_app/         # تطبيق Flutter للمراقب أثناء الامتحانات
├── computer_vision_model/ # نموذج الرؤية الحاسوبية للتعرف على السلوك أو الغش
├── genetic_scheduler/    # خوارزمية جينية لإنشاء الجداول الامتحانية
├── linear_optimizer/     # توزيع الطلاب والمراقبين باستخدام OR-Tools
```

---

## 🧩 مكونات المشروع بالتفصيل

### 🔧 `backend/`
- مبني باستخدام Laravel.
- يوفر RESTful APIs للتطبيقات.
- إدارة:  المراقبين، الجداول، القاعات، البلاغات.
- توثيق المستخدم ( Sanctum).

### 📱 `admin_app/`
- تطبيق Flutter موجه لمسؤولي النظام.
- يعرض بيانات القاعات، المراقبين، الجداول.
- دعم الإشعارات وتسجيل الدخول.

### 👀 `observer_app/`
- تطبيق Flutter مخصص للمراقبين داخل القاعة.
- يستخدم الكاميرا لإرسال الصور إلى وحدة الرؤية الحاسوبية.
- يعرض حالات الغش والتبليغ.

### 🧠 `computer_vision_model/`
- نموذج YOLO أو OpenCV لاكتشاف الغش داخل القاعة.
- تحليل الفيديو أو الصور في الزمن الحقيقي.
- تصنيف الحالات وتسجيلها.

### 🧬 `genetic_scheduler/`
- خوارزمية جينية لتوليد جدول امتحانات بدون تعارض.
- يأخذ في الحسبان سعة القاعات، عدد الطلاب، التكرار الزمني.

### 📊 `linear_optimizer/`
- استخدام Google OR-Tools.
- توزيع المراقبين والطلاب على القاعات بناءً على قيود محددة.
- يدعم تحسين التوزيع وتقليل التداخلات.

---

## ⚙️ كيفية التشغيل

### 1. إعداد الـ Backend
```bash
cd backend/
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### 2. تشغيل تطبيقات Flutter
```bash
cd admin_app/
flutter pub get
flutter run

cd ../observer_app/
flutter pub get
flutter run
```

### 3. تشغيل الخوارزميات
```bash
cd genetic_scheduler/
python main.py

cd ../linear_optimizer/
python assign.py
```

---

## 📚 المتطلبات

| أداة          | الإصدار الموصى به       |
|---------------|--------------------------|
| PHP           | 8.1+                     |
| Laravel       | 10 أو 11                 |
| Flutter       | 3.19+                   |
| Python        | 3.9+                     |
| OR-Tools      | Python library           |
| OpenCV        | في حال استخدامه بالرؤية |

---

## 🧪 ملاحظات مهمة
- تأكد من وجود قاعدة بيانات متصلة بشكل صحيح في ملف `.env`.
- قم بوضع نموذج الرؤية في مكان آمن لخدمة الـ backend.
- تأكد من إعداد صلاحيات التخزين وملفات الخطوط إذا كنت تصدر PDF بالعربية.

---

## 📄 الرخصة

مشروع USS مرخص تحت [MIT License](LICENSE).

---
