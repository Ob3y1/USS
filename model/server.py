from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncio
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



from fastapi.responses import StreamingResponse
import threading

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import cv2
import time
from main2 import process_frame, violations_log

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

running = False
latest_frame = None  # سنخزن آخر فريم هنا

def detect_cheat():
    global running, latest_frame
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ فشل في فتح الكاميرا.")
        return

    print("✅ بدأ الكشف عن الغش...")

    while running:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.resize(frame, (640, 480))
        process_frame(frame)  # معالجتك الخاصة
        
        # تحديث آخر فريم
        _, jpeg = cv2.imencode('.jpg', frame)
        latest_frame = jpeg.tobytes()

        time.sleep(0.1)

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

@app.post("/start_cheat_detection")
async def start_cheat_detection():
    global running
    if running:
        return {"status": "already running"}
    
    running = True
    loop = asyncio.get_event_loop()
    loop.run_in_executor(None, detect_cheat)
    
    return {"status": "started"}

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


@app.post("/clear_violations")
async def clear_violations():
    violations_log.clear()
    return {"message": "Violations cleared"}
