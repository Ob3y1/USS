import cv2
import numpy as np
import mediapipe as mp
from ultralytics import YOLO
from gtts import gTTS
from playsound import playsound
import time
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
import base64
from io import BytesIO
from PIL import Image


# إعدادات عامة
violation_folder = "violations2"
os.makedirs(violation_folder, exist_ok=True)
report_file = "violations_report.csv"
font_path = "arial.ttf"  # تأكد من وجود الخط

# تحميل الموديلات
model = YOLO('C:/Users/Ali/Downloads/Hul-E.v3i.coco/themodel2222/yolov8_exp1/weights/best.pt')
pose = mp.solutions.pose.Pose(static_image_mode=False, min_detection_confidence=0.5)
tracker = DeepSort(max_age=30)

custom_names = {
    0: "Head-Normalrotation",
    1: "Hand-Suspiciousrotation",
    2: "Hand-Normalrotation",
    3: "Head-Suspiciousrotation",
}

arabic_translations = {
    "Head-Suspiciousrotation": "تحذير هناك حركة مريبة",
    "Hand-Suspiciousrotation": "تحذير هناك حركة مريبة",
    "Hand-Between-Students": "تحذير اليد بين طالبين"
}

ALLOWED_MARGIN = 20
HAND_OUTSIDE_DURATION_THRESHOLD = 1.5  # ثواني
HAND_SPEED_THRESHOLD = 30  # بكسل/إطار
MIN_ELBOW_ANGLE = 30
MAX_ELBOW_ANGLE = 160
FINGER_OPEN_THRESHOLD = 0.2

hand_outside_zone_start = defaultdict(float)
previous_wrist_positions = {}
violations_log = []
alerted_ids = set()
head_rotation_start = {} 
# خارج كل الدوال (في بداية الملف)
head_rotation_start = {}
 # track_id -> start_time


mp_drawing = mp.solutions.drawing_utils

def render_text_arabic(img, text, pos, font, font_size=24, color=(0, 0, 255)):
    reshaped_text = arabic_reshaper.reshape(text)
    bidi_text = get_display(reshaped_text)
    pil_img = Image.fromarray(img)
    draw = ImageDraw.Draw(pil_img)
    font_pil = ImageFont.truetype(font, font_size)
    draw.text(pos, bidi_text, font=font_pil, fill=color)
    return np.array(pil_img)

def get_position_description(center_x, center_y, frame_width, frame_height):
    cols = 4
    rows = 2
    col_width = frame_width // cols
    row_height = frame_height // rows

    col_idx = center_x // col_width
    row_idx = center_y // row_height

    section_id = int(row_idx * cols + col_idx) + 1  # من 1 إلى 8
    return section_id, row_idx + 1, col_idx + 1

def detect_hand_between_students(hands):
    if len(hands) < 2:
        return False
    hands = sorted(hands, key=lambda h: h[0])
    for i in range(len(hands) - 1):
        x1, _ = hands[i]
        x2, _ = hands[i + 1]
        if abs(x2 - x1) < 150:
            return True
    return False

def calculate_angle(a, b, c):
    a = np.array(a)
    b = np.array(b)
    c = np.array(c)
    ba = a - b
    bc = c - b
    cosine_angle = np.dot(ba, bc) / (np.linalg.norm(ba) * np.linalg.norm(bc))
    angle = np.arccos(np.clip(cosine_angle, -1.0, 1.0))
    return np.degrees(angle)

#تحويل الصورة
def encode_image_to_base64(image):
    img_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    pil_img = Image.fromarray(img_rgb)
    buffered = BytesIO()
    pil_img.save(buffered, format="JPEG")
    img_base64 = base64.b64encode(buffered.getvalue()).decode("utf-8")
    return img_base64


class KalmanFilter2D:
    def __init__(self):
        self.kalman = cv2.KalmanFilter(4, 2)
        self.kalman.measurementMatrix = np.array([[1, 0, 0, 0],
                                                   [0, 1, 0, 0]], np.float32)
        self.kalman.transitionMatrix = np.array([[1, 0, 1, 0],
                                                 [0, 1, 0, 1],
                                                 [0, 0, 1, 0],
                                                 [0, 0, 0, 1]], np.float32)
        self.kalman.processNoiseCov = np.eye(4, dtype=np.float32) * 0.03
        self.kalman.measurementNoiseCov = np.eye(2, dtype=np.float32) * 0.5
        self.kalman.statePre = np.zeros((4, 1), dtype=np.float32)

    def update(self, coord):
        measurement = np.array([[np.float32(coord[0])],
                                [np.float32(coord[1])]])
        self.kalman.correct(measurement)

    def predict(self):
        prediction = self.kalman.predict()
        return prediction[:2].flatten()


def process_frame(frame):
    global hand_outside_zone_start, previous_wrist_positions, alerted_ids, head_rotation_start

    frame_height, frame_width = frame.shape[:2]

    # إعدادات التقسيم: 2 صفوف × 4 أعمدة = 8 مناطق
    NUM_ROWS = 2
    NUM_COLS = 4
    section_width = frame_width // NUM_COLS
    section_height = frame_height // NUM_ROWS

    # دالة لحساب موقع (صف، عمود) و ID بناءً عليه
    def get_position_description(cx, cy, frame_width, frame_height):
        col_num = min(cx // section_width + 1, NUM_COLS)  # العمود (1-4)
        row_num = min(cy // section_height + 1, NUM_ROWS) # الصف (1-2)
        section_id = (row_num - 1) * NUM_COLS + col_num  # ID القسم (1-8)
        return section_id, row_num, col_num

    results = model(frame)[0]
    raw_detections = []
    current_hand_centers = []
    sift = cv2.SIFT_create()
    bf = cv2.BFMatcher()
    calculator_descriptors = [] 

    def is_calculator(device_img):
        gray = cv2.cvtColor(device_img, cv2.COLOR_BGR2GRAY)
        gray = cv2.resize(gray, (200, 200))
        kp1, des1 = sift.detectAndCompute(gray, None)
        if des1 is None:
            return False
        for des2 in calculator_descriptors:
            matches = bf.knnMatch(des1, des2, k=2)
            good_matches = [m for m, n in matches if m.distance < 0.7 * n.distance]
            if len(good_matches) > 10:
                return True
        return False

    def is_valid_phone_device(device_img):
        if device_img is None or device_img.size == 0:
            return False
        h, w = device_img.shape[:2]
        if h == 0 or w == 0:
            return False
        aspect_ratio = w / h
        if aspect_ratio < 0.2 or aspect_ratio > 1.0:
            return False
        resized = cv2.resize(device_img, (150, 150))
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        edges = cv2.Canny(gray, 80, 200)
        edge_density = np.sum(edges > 0) / (150 * 150)
        if edge_density < 0.02:
            return False
        corners = cv2.goodFeaturesToTrack(gray, 10, 0.01, 10)
        if corners is None or len(corners) < 4:
            return False
        blur = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(blur, 50, 150)
        contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        for cnt in contours:
            peri = cv2.arcLength(cnt, True)
            approx = cv2.approxPolyDP(cnt, 0.02 * peri, True)
            area = cv2.contourArea(cnt)
            if len(approx) == 4 and area > 1000:
                return True
        return False

    def is_phone_in_hand(phone_center, hand_points, threshold=60):
        px, py = phone_center
        return any(np.linalg.norm(np.array([px, py]) - np.array(hp)) < threshold for hp in hand_points)

    device_detections = []
    kalman_filters = getattr(process_frame, "kalman_filters", {})
    in_hand_start = getattr(process_frame, "in_hand_start", {})

    device_results = model(frame)[0]
    for r in device_results.boxes:
        conf = float(r.conf[0])
        if conf > 0.5:
            x1, y1, x2, y2 = map(int, r.xyxy[0])
            device_detections.append(([x1, y1, x2 - x1, y2 - y1], conf, 'device'))

    device_tracks = tracker.update_tracks(device_detections, frame=frame)
    tracked_devices = []

    for track in device_tracks:
        if not track.is_confirmed():
            continue
        tid = int(track.track_id)
        l, t, r, b = track.to_ltrb()
        cx_raw = int((l + r) / 2)
        cy_raw = int((t + b) / 2)

        if tid not in kalman_filters:
            kalman_filters[tid] = KalmanFilter2D()
        kf = kalman_filters[tid]
        kf.update([cx_raw, cy_raw])
        cx, cy = kf.predict().astype(int)

        cropped_img = frame[int(t):int(b), int(l):int(r)]
        if cropped_img is None or cropped_img.size == 0:
            continue
        if is_calculator(cropped_img):
            continue
        if not is_valid_phone_device(cropped_img):
            continue

        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        hands_result = mp.solutions.hands.Hands(False, max_num_hands=2, min_detection_confidence=0.8, min_tracking_confidence=0.8).process(rgb_frame)
        hand_points = []
        if hands_result.multi_hand_landmarks:
            for hl in hands_result.multi_hand_landmarks:
                hand_points.append([(int(p.x * frame.shape[1]), int(p.y * frame.shape[0])) for p in hl.landmark])

        in_hand = any(is_phone_in_hand((cx, cy), hpts) for hpts in hand_points)
        now = time.time()
        if in_hand:
            if tid not in in_hand_start:
                in_hand_start[tid] = now
            elif now - in_hand_start[tid] > 1.5:
                section_id, row_num, col_num = get_position_description(cx, cy, frame_width, frame_height)
                pos_desc = f"الموقع: الصف {row_num}، العمود {col_num}"
                frame = render_text_arabic(frame, f"هاتف مع الطالب - {row_num} {col_num}", (cx - 80, cy - 40), font_path, 20)
                alert_key = f"PhoneInHand_{section_id}_{tid}"
                if alert_key not in alerted_ids:
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    filename = f"Cheat_Phone_{section_id}_{tid}_{timestamp}.jpg"
                    cv2.imwrite(os.path.join(violation_folder, filename), frame)
                    violation = {
                        "class_name": "Phone-In-Hand",
                        "arabic_name": "هاتف في يد الطالب",
                        "position": pos_desc,
                        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                        "image_base64": encode_image_to_base64(frame)

                    }
                    violations_log.append(violation)
                    alerted_ids.add(alert_key)
        else:
            in_hand_start.pop(tid, None)

    setattr(process_frame, "kalman_filters", kalman_filters)
    setattr(process_frame, "in_hand_start", in_hand_start)

    for box in results.boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        conf = float(box.conf[0])
        cls = int(box.cls[0])
        class_name = custom_names.get(cls)
        if not class_name:
            continue
        if class_name == "Head-Suspiciousrotation" and conf < 0.8:
            continue
        if class_name == "Hand-Suspiciousrotation" and conf < 0.7:
            continue
        x, y, w, h = x1, y1, x2 - x1, y2 - y1
        raw_detections.append(([x, y, w, h], conf, cls))

    tracks = tracker.update_tracks(raw_detections, frame=frame)

    for track in tracks:
        if not track.is_confirmed():
            continue

        track_id = track.track_id
        ltrb = track.to_ltrb()
        x1, y1, x2, y2 = map(int, ltrb)
        class_id = track.det_class
        class_name = custom_names.get(class_id, "Unknown")
        center_x = int((x1 + x2) / 2)
        center_y = int((y1 + y2) / 2)

        if class_name == "Head-Suspiciousrotation":
            section_id, row_num, col_num = get_position_description(center_x, center_y, frame_width, frame_height)
            pos_desc = f"الموقع: الصف {row_num}، العمود {col_num}"

            alert_key = f"{class_name}_{section_id}_{track_id}"
            current_time = time.time()

            if alert_key not in head_rotation_start:
                head_rotation_start[alert_key] = current_time
            elif current_time - head_rotation_start[alert_key] > 5:
                if alert_key not in alerted_ids:
                    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    filename = f"Cheat_Head_{section_id}_{track_id}_{timestamp}.jpg"
                    cv2.imwrite(os.path.join(violation_folder, filename), frame)
                    violation = {
                        "class_name": "Head-Suspiciousrotation",
                        "arabic_name": "حالة مشبوهة في الرأس",
                        "position": pos_desc,
                        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                        "image_base64": encode_image_to_base64(frame)

                    }
                    violations_log.append(violation)
                    alerted_ids.add(alert_key)

                text = f"{arabic_translations[class_name]} - {pos_desc}"
                frame = render_text_arabic(frame, text, (x1, y1 - 30), font_path, font_size=26, color=(0, 165, 255))
                cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 165, 255), 3)

            continue

        if class_name != "Hand-Suspiciousrotation":
            cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 255, 255), 2)
            continue

        roi = frame[y1:y2, x1:x2]
        if roi.size == 0:
            continue

        suspicious = False
        current_hand_centers.append((center_x, center_y))

        img_rgb = cv2.cvtColor(roi, cv2.COLOR_BGR2RGB)
        results_pose = pose.process(img_rgb)
        if not results_pose.pose_landmarks:
            continue

        landmarks = results_pose.pose_landmarks.landmark
        height, width, _ = roi.shape

        for side in ["RIGHT", "LEFT"]:
            wrist = landmarks[getattr(mp.solutions.pose.PoseLandmark, f"{side}_WRIST")]
            elbow = landmarks[getattr(mp.solutions.pose.PoseLandmark, f"{side}_ELBOW")]
            shoulder = landmarks[getattr(mp.solutions.pose.PoseLandmark, f"{side}_SHOULDER")]
            hip = landmarks[getattr(mp.solutions.pose.PoseLandmark, f"{side}_HIP")]

            wrist_xy = np.array([wrist.x * width, wrist.y * height])
            elbow_xy = np.array([elbow.x * width, elbow.y * height])
            shoulder_xy = np.array([shoulder.x * width, shoulder.y * height])
            hip_xy = np.array([hip.x * width, hip.y * height])
            elbow_angle = calculate_angle(shoulder_xy, elbow_xy, wrist_xy)
            arm_length = np.linalg.norm(elbow_xy - shoulder_xy)
            dynamic_margin = arm_length * 0.15

            allowed_x_min = min(shoulder_xy[0], elbow_xy[0]) - dynamic_margin
            allowed_x_max = max(shoulder_xy[0], elbow_xy[0]) + dynamic_margin
            allowed_y_min = min(shoulder_xy[1], elbow_xy[1]) - dynamic_margin
            allowed_y_max = max(shoulder_xy[1], elbow_xy[1]) + dynamic_margin
            in_allowed_zone = (allowed_x_min <= wrist_xy[0] <= allowed_x_max) and (allowed_y_min <= wrist_xy[1] <= allowed_y_max)

            if in_allowed_zone:
                hand_outside_zone_start[(track_id, side)] = 0
            else:
                if hand_outside_zone_start.get((track_id, side), 0) == 0:
                    hand_outside_zone_start[(track_id, side)] = time.time()
                elif time.time() - hand_outside_zone_start[(track_id, side)] > HAND_OUTSIDE_DURATION_THRESHOLD:
                    if wrist_xy[1] < shoulder_xy[1] and abs(wrist_xy[0] - shoulder_xy[0]) > 50:
                        suspicious = True

            prev_wrist_pos = previous_wrist_positions.get((track_id, side), None)
            if prev_wrist_pos is not None:
                speed = np.linalg.norm(wrist_xy - prev_wrist_pos) * 30
                if speed > HAND_SPEED_THRESHOLD:
                    suspicious = True
            previous_wrist_positions[(track_id, side)] = wrist_xy

            if elbow_angle < MIN_ELBOW_ANGLE or elbow_angle > MAX_ELBOW_ANGLE:
                suspicious = True

            table_level_y = hip_xy[1] + 20
            if wrist_xy[1] > table_level_y and abs(wrist_xy[0] - shoulder_xy[0]) < 80:
                suspicious = False

            if wrist_xy[1] > shoulder_xy[1] + 20 and abs(wrist_xy[0] - shoulder_xy[0]) < 80:
                suspicious = False

        if suspicious:
            section_id, row_num, col_num = get_position_description(center_x, center_y, frame_width, frame_height)
            pos_desc = f"الموقع: الصف {row_num}، العمود {col_num}"
            alert_key = f"{class_name}_{section_id}_{track_id}"
            if alert_key not in alerted_ids:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = f"Cheat_Hand_{section_id}_{track_id}_{timestamp}.jpg"
                cv2.imwrite(os.path.join(violation_folder, filename), frame)
                violation = {
                    "class_name": class_name,
                    "arabic_name": arabic_translations.get(class_name, class_name),
                    "position": pos_desc,
                    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                    "image_base64": encode_image_to_base64(frame)

                }
                violations_log.append(violation)
                alerted_ids.add(alert_key)
            frame = render_text_arabic(frame, f"يد مشبوهة - {row_num} {col_num}", (x1, y1 - 40), font_path, 22, (0, 0, 255))
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 0, 255), 3)
        else:
            cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 255, 255), 2)

    # هنا تضيف الأسطر التالية
    for row in range(1, NUM_ROWS):  # خطوط أفقية
        y = row * section_height
        cv2.line(frame, (0, y), (frame_width, y), (100, 255, 100), 2)

    for col in range(1, NUM_COLS):  # خطوط عمودية
        x = col * section_width
        cv2.line(frame, (x, 0), (x, frame_height), (100, 255, 100), 2)


    # رسم رقم الصف والعمود كمجموعة رقم واحد مثل "12"
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_scale = 1
    thickness = 2
    color = (0, 255, 0)  # أخضر

    for row in range(NUM_ROWS):
     for col in range(NUM_COLS):
        number_text = f"{row + 1}{col + 1}"  # دمج رقم الصف والعمود في نص واحد مثل "12"
        x_text = col * section_width + 10
        y_text = row * section_height + 40  # رفع النص قليلاً عن الأعلى

        cv2.putText(frame, number_text, (x_text, y_text), font, font_scale, color, thickness, cv2.LINE_AA)
    

    return frame





def save_report():
    with open(report_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["نوع الغش", "الشرح", "المكان", "التاريخ والوقت"])
        for row in violations_log:
            writer.writerow(row)

