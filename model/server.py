from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import cv2
import numpy as np
import mediapipe as mp
from ultralytics import YOLO
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
import mysql.connector
from fastapi import Request



from fastapi.responses import StreamingResponse
import threading

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import cv2
import time
from model import process_frame, violations_log

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'uss'
}

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

running = False
latest_frame = None  # سنخزن آخر فريم هنا
def detect_cheat(camera_addresses):
    global running, latest_frame
    caps = [cv2.VideoCapture(addr) for addr in camera_addresses]

    print("✅ بدأ الكشف عن الغش من الكاميرات:", camera_addresses)

    while running:
        for cap in caps:
            if not cap.isOpened():
                continue
            ret, frame = cap.read()
            if not ret:
                continue

            frame = cv2.resize(frame, (640, 480))
            process_frame(frame)
            
            _, jpeg = cv2.imencode('.jpg', frame)
            latest_frame = jpeg.tobytes()

        time.sleep(0.1)

    for cap in caps:
        cap.release()
    print("📴 توقف الكشف.")

def generate_video_stream():
    global latest_frame
    while True:
        if latest_frame is not None:
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + latest_frame + b'\r\n')
        time.sleep(0.05)

@app.get("/video_feed")
async def video_feed():
    return StreamingResponse(generate_video_stream(), media_type="multipart/x-mixed-replace; boundary=frame")
from fastapi import Request

@app.post("/start_cheat_detection")
async def start_cheat_detection(request: Request):
    global running
    if running:
        return {"status": "already running"}

    data = await request.json()
    hall_id = data.get("hall_id")
    if hall_id is None:
        return {"status": "error", "message": "hall_id is required"}

    # جلب الكاميرات من قاعدة البيانات
    try:
        connection = mysql.connector.connect(**db_config)
        cursor = connection.cursor()
        cursor.execute("SELECT address FROM cameras WHERE hall_id = %s AND deleted_at IS NULL", (hall_id,))
        results = cursor.fetchall()
        camera_addresses = [row[0] for row in results]
        cursor.close()
        connection.close()

        if not camera_addresses:
            return {"status": "error", "message": "No cameras found for this hall"}

        running = True
        loop = asyncio.get_event_loop()
        loop.run_in_executor(None, detect_cheat, camera_addresses)

        return {"status": "started", "cameras": camera_addresses}
    
    except mysql.connector.Error as err:
        return {"status": "error", "message": str(err)}

@app.post("/stop_cheat_detection")
async def stop_cheat_detection():
    global running
    running = False
    return {"status": "stopped"}

from fastapi.responses import JSONResponse
import json

@app.get("/violations")
async def get_violations():
    return JSONResponse(
        content=json.loads(json.dumps({"violations": violations_log}, ensure_ascii=False)),
        media_type="application/json; charset=utf-8"
    )

#  uvicorn server:app --reload --port 8003
@app.post("/clear_violations")
async def clear_violations():
    violations_log.clear()
    return {"message": "Violations cleared"}