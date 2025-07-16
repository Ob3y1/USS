from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
import threading
import asyncio
import time
import cv2
import numpy as np
import mediapipe as mp
from ultralytics import YOLO
from gtts import gTTS
from playsound import playsound
import csv
from datetime import datetime
import os
import uuid
from PIL import ImageFont, ImageDraw, Image
import arabic_reshaper
from bidi.algorithm import get_display
from deep_sort_realtime.deepsort_tracker import DeepSort
from collections import defaultdict
import glob
import json
import queue
import mysql.connector

from model import process_frame, violations_log

# إعداد بيانات الاتصال بقاعدة البيانات MySQL
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'uss'
}

app = FastAPI()  # إنشاء تطبيق FastAPI

# إضافة وسيط CORS للسماح بالوصول من أي مصدر (Cross-Origin Resource Sharing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # السماح لجميع العناوين
    allow_methods=["*"],   # السماح بكل طرق HTTP
    allow_headers=["*"],   # السماح بكل رؤوس الطلبات
)

# متغيرات عامة تستخدم في التطبيق
running = False            # حالة التشغيل: هل نظام الكشف يعمل أم لا
latest_frame = None        # أحدث صورة معالجة سيتم بثها
frame_queue = queue.Queue(maxsize=5)  # صف للفريمات التي سيتم معالجتها، بسعة 5 فقط
camera_addresses = []      # قائمة عناوين الكاميرات (يمكن أن تكون عدة كاميرات)

# دالة لقراءة الفيديو من الكاميرات المتعددة
def camera_reader():
    global running, frame_queue, camera_addresses

    # فتح عدة كاميرات من العناوين المحفوظة في camera_addresses
    caps = [cv2.VideoCapture(addr) for addr in camera_addresses]
    for cap in caps:
        cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # تقليل حجم المخزن المؤقت للكاميرا لتقليل التأخير

    frame_counter = 0
    start_time = time.time()

    while running:
        # قراءة إطار (فريم) من كل كاميرا
        for cap in caps:
            if not cap.isOpened():
                continue  # تخطى الكاميرا إذا لم تفتح بشكل صحيح
            ret, frame = cap.read()
            if not ret:
                continue  # تخطى إذا لم يتم استرجاع فريم

            frame_counter += 1
            # أضف الفريم إلى صف الانتظار إذا لم يكن الصف ممتلئًا
            if not frame_queue.full():
                frame_queue.put(frame)

        # حساب وعرض معدل الإطارات (FPS) كل ثانية
        elapsed = time.time() - start_time
        if elapsed >= 1.0:
            print(f"📷 FPS: {frame_counter}")
            frame_counter = 0
            start_time = time.time()

    # إغلاق جميع الكاميرات عند التوقف
    for cap in caps:
        cap.release()

# دالة لمعالجة الفريمات من صف الانتظار
def frame_processor(hands_detector, pose_detector):
    global running, latest_frame, frame_queue
    frame_count = 0
    previous_processed = None  # لتخزين الفريم المعالج الأخير للاستخدام إذا لم يتوفر جديد

    while running:
        try:
            # الحصول على فريم من صف الانتظار مع مهلة 1 ثانية
            frame = frame_queue.get(timeout=1)
        except queue.Empty:
            continue  # إذا لم يتوفر فريم جديد، استمر في الانتظار

        # تغيير حجم الفريم ليصبح 640x480 لتوحيد المعالجة
        frame = cv2.resize(frame, (640, 480))
        frame_count += 1

        # معالجة كل 3 فريمات فقط لتخفيف الحمل الحسابي
        if frame_count % 3 == 0:
            # استدعاء دالة المعالجة من ملف model.py
            previous_processed = process_frame(frame, hands_detector, pose_detector)

        # استخدام الفريم المعالج الأخير أو الفريم الحالي إذا لم يكن هناك معالج جديد
        frame_to_use = previous_processed if previous_processed is not None else frame
        # ترميز الفريم إلى صيغة JPEG
        _, jpeg = cv2.imencode('.jpg', frame_to_use)
        # حفظ الفريم المشفر للبث المباشر
        latest_frame = jpeg.tobytes()

# الدالة الرئيسية التي تشغل نظام كشف الغش
def detect_cheat():
    global running

    # إعداد كاشف الأيدي باستخدام MediaPipe
    mp_hands = mp.solutions.hands
    hands_detector = mp_hands.Hands(
        static_image_mode=False, max_num_hands=2,
        min_detection_confidence=0.8, min_tracking_confidence=0.8)

    # إعداد كاشف وضعيات الجسم (pose)
    mp_pose = mp.solutions.pose
    pose_detector = mp_pose.Pose(
        static_image_mode=False, model_complexity=1,
        min_detection_confidence=0.5, min_tracking_confidence=0.5)

    print("✅ بدأ الكشف عن الغش...")

    # تشغيل دالة قراءة الكاميرا في خيط (thread) منفصل
    reader_thread = threading.Thread(target=camera_reader, daemon=True)
    # تشغيل دالة معالجة الفريمات في خيط منفصل
    processor_thread = threading.Thread(target=frame_processor, args=(hands_detector, pose_detector), daemon=True)

    reader_thread.start()
    processor_thread.start()

    # الاستمرار في العمل طالما المتغير running صحيح
    while running:
        time.sleep(0.1)  # تأخير صغير لمنع استهلاك عالي للمعالج

    # عند التوقف، إغلاق الكواشف وتنظيف الموارد
    hands_detector.close()
    pose_detector.close()
    cv2.destroyAllWindows()
    print("📴 توقف الكشف.")

# دالة لتوليد بث الفيديو بشكل مباشر باستخدام آخر فريم معالج
def generate_video_stream():
    global latest_frame
    while True:
        if latest_frame is not None:
            # بناء صيغة البث التي تدعم تحديث الفريمات (multipart)
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + latest_frame + b'\r\n')
        time.sleep(0.03)  # معدل تحديث حوالي 30 إطار في الثانية

# نقطة النهاية لبث الفيديو المباشر
@app.get("/video_feed")
async def video_feed():
    return StreamingResponse(generate_video_stream(), media_type="multipart/x-mixed-replace; boundary=frame")

# نقطة النهاية لبدء نظام كشف الغش مع استقبال hall_id من الطلب
@app.post("/start_cheat_detection")
async def start_cheat_detection(request: Request):
    global running, frame_queue, camera_addresses

    if running:
        return {"status": "already running"}

    data = await request.json()  # قراءة بيانات JSON من الطلب
    hall_id = data.get("hall_id")  # استخراج hall_id
    if hall_id is None:
        return {"status": "error", "message": "hall_id is required"}  # خطأ إذا لم يُرسل hall_id

    try:
        # الاتصال بقاعدة البيانات
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()
        # جلب عناوين الكاميرات الخاصة بالقاعة المطلوبة والتي لم تُحذف
        cursor.execute("SELECT address FROM cameras WHERE hall_id = %s AND deleted_at IS NULL", (hall_id,))
        results = cursor.fetchall()
        camera_addresses = [row[0] for row in results]  # تخزين العناوين في القائمة
        cursor.close()
        connection.close()

        if not camera_addresses:
            return {"status": "error", "message": "No cameras found for this hall"}

        # إعادة تهيئة صف الفريمات
        frame_queue = queue.Queue(maxsize=5)
        running = True
        # تشغيل نظام كشف الغش في خيط جديد
        threading.Thread(target=detect_cheat, daemon=True).start()

        return {"status": "started", "cameras": camera_addresses}

    except mysql.connector.Error as err:
        # في حال حدوث خطأ في الاتصال بقاعدة البيانات
        return {"status": "error", "message": str(err)}

# نقطة النهاية لإيقاف نظام كشف الغش
@app.post("/stop_cheat_detection")
async def stop_cheat_detection():
    global running
    running = False
    return {"status": "stopped"}

# نقطة النهاية لجلب سجل الانتهاكات الحالية
@app.get("/violations")
async def get_violations():
    # إعادة السجل كـ JSON مع التأكد من ترميز UTF-8 ودعم النص العربي
    return JSONResponse(
        content=json.loads(json.dumps({"violations": violations_log}, ensure_ascii=False)),
        media_type="application/json; charset=utf-8"
    )

# نقطة النهاية لمسح سجل الانتهاكات
@app.post("/clear_violations")
async def clear_violations():
    violations_log.clear()
    return {"message": "Violations cleared"}
























# from fastapi import FastAPI
# from fastapi.middleware.cors import CORSMiddleware
# from fastapi.responses import StreamingResponse, JSONResponse
# import threading
# import asyncio
# import time
# import cv2
# import numpy as np
# import mediapipe as mp
# from ultralytics import YOLO
# from gtts import gTTS
# from playsound import playsound
# import csv
# from datetime import datetime
# import os
# import uuid
# from PIL import ImageFont, ImageDraw, Image
# import arabic_reshaper
# from bidi.algorithm import get_display
# from deep_sort_realtime.deepsort_tracker import DeepSort
# from collections import defaultdict
# import glob
# import json
# import queue

# from model import process_frame, violations_log

# app = FastAPI()

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# # 🔁 متغيرات مشتركة
# running = False
# latest_frame = None        # الفريم المعالج للإرسال

# frame_queue = queue.Queue(maxsize=5)  # صف للفريمات الخام (بحد أقصى 5)

# import time

# def camera_reader():
#     global running, frame_queue

#     ip_camera_url = "http://10.0.166.248:8080/video"
#     cap = cv2.VideoCapture(ip_camera_url)
#     if not cap.isOpened():
#         print("❌ فشل في فتح الكاميرا.")
#         return

#     cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

#     # FPS Tracking
#     frame_counter = 0
#     start_time = time.time()

#     while running:
#         ret, frame = cap.read()
#         if not ret:
#             continue

#         frame_counter += 1

#         # احسب الزمن المنقضي
#         elapsed = time.time() - start_time
#         if elapsed >= 1.0:
#             print(f"📷 FPS: {frame_counter}")
#             frame_counter = 0
#             start_time = time.time()

#         if not frame_queue.full():
#             frame_queue.put(frame)

#     cap.release()


# def frame_processor(hands_detector, pose_detector):
#     """Thread لمعالجة الفريمات من الـ queue كل 20 فريم"""
#     global running, latest_frame, frame_queue
#     frame_count = 0
#     previous_processed = None  # للاحتفاظ بالفريم المعالج الأخير

#     while running:
#         try:
#             frame = frame_queue.get(timeout=1)
#         except queue.Empty:
#             continue

#         frame = cv2.resize(frame, (640, 480))
#         frame_count += 1

#         if frame_count % 3 == 0:
#             previous_processed = process_frame(frame, hands_detector, pose_detector)

#         # استخدم الفريم المعالج السابق أو الحالي
#         frame_to_use = previous_processed if previous_processed is not None else frame
#         _, jpeg = cv2.imencode('.jpg', frame_to_use)
#         latest_frame = jpeg.tobytes()

# def detect_cheat():
#     """التابع الأساسي للتشغيل"""
#     global running

#     # MediaPipe setup
#     mp_hands = mp.solutions.hands
#     hands_detector = mp_hands.Hands(
#         static_image_mode=False, max_num_hands=2,
#         min_detection_confidence=0.8, min_tracking_confidence=0.8)

#     mp_pose = mp.solutions.pose
#     pose_detector = mp_pose.Pose(
#         static_image_mode=False, model_complexity=1,
#         min_detection_confidence=0.5, min_tracking_confidence=0.5)

#     print("✅ بدأ الكشف عن الغش...")

#     # تشغيل خيوط منفصلة
#     reader_thread = threading.Thread(target=camera_reader, daemon=True)
#     processor_thread = threading.Thread(target=frame_processor, args=(hands_detector, pose_detector), daemon=True)

#     reader_thread.start()
#     processor_thread.start()

#     # الانتظار حتى توقف النظام
#     while running:
#         time.sleep(0.1)

#     # التنظيف
#     hands_detector.close()
#     pose_detector.close()
#     cv2.destroyAllWindows()
#     print("📴 توقف الكشف.")

# def generate_video_stream():
#     """يبث آخر فريم معالج"""
#     global latest_frame
#     while True:
#         if latest_frame is not None:
#             yield (b'--frame\r\n'
#                    b'Content-Type: image/jpeg\r\n\r\n' + latest_frame + b'\r\n')
#         time.sleep(0.03)

# @app.get("/video_feed")
# async def video_feed():
#     return StreamingResponse(generate_video_stream(), media_type="multipart/x-mixed-replace; boundary=frame")

# @app.post("/start_cheat_detection")
# async def start_cheat_detection():
#     global running, frame_queue
#     if running:
#         return {"status": "already running"}

#     running = True
#     frame_queue = queue.Queue(maxsize=5)  # إعادة تهيئة الصف عند بدء الكشف

#     threading.Thread(target=detect_cheat, daemon=True).start()
#     return {"status": "started"}

# @app.post("/stop_cheat_detection")
# async def stop_cheat_detection():
#     global running
#     running = False
#     return {"status": "stopped"}

# @app.get("/violations")
# async def get_violations():
#     return JSONResponse(
#         content=json.loads(json.dumps({"violations": violations_log}, ensure_ascii=False)),
#         media_type="application/json; charset=utf-8"
#     )

# @app.post("/clear_violations")
# async def clear_violations():
#     violations_log.clear()
#     return {"message": "Violations cleared"}






















# قمنا بفصل المهام في خيوط مستقلة (threads):

# read_camera_loop ↔ يقرأ من الكاميرا باستمرار بدون تأخير المعالجة.

# process_frames_loop ↔ يعالج فقط أحدث فريم متاح.

# generate_video_stream ↔ يبث فقط آخر فريم جاهز.

# الفائدة: القراءة لا تتوقف، المعالجة تعمل بسرعة حسب قدرتها، والبث دائمًا يظهر أحدث نتيجة جاهزة.