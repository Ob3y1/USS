# backend/main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict
from ortools.linear_solver import pywraplp
import mysql.connector
import os

app = FastAPI()

# CORS للسماح للـ Flutter بالوصول
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ضيّقها عند الإنتاج
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# إعدادات الاتصال بقاعدة البيانات (يمكنك جلبها من متغيرات بيئية)
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASS", ""),
    "database": os.getenv("DB_NAME", "laravel_db"),
}

# نموذج للإرسال النهائي (ليس مستخدماً هنا، فقط للتوثيق)
class Course(BaseModel):
    name: str
    students: int
    day: str
    time: str

class ScheduleRequest(BaseModel):
    courses: List[Course]
    rooms: Dict[str, int]

def fetch_from_mysql():
    """يجلب المواد والجلسات والقاعات من جداول Laravel."""
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(dictionary=True)

    # جدول المواد: يفترض أعمدة name, students, day, time
    cursor.execute("SELECT name, students, day, time FROM exam_courses")
    courses = cursor.fetchall()

    # جدول القاعات: يفترض أعمدة room (الاسم) و capacity (السعة)
    cursor.execute("SELECT room, capacity FROM exam_rooms")
    rooms = {row["room"]: row["capacity"] for row in cursor.fetchall()}

    cursor.close()
    conn.close()
    return courses, rooms

@app.get("/generate-schedule")
def generate_schedule():
    """
    1) يجلب البيانات من MySQL (Laravel)
    2) يعالجها بنموذج الجدولة
    3) يعيد JSON بالجدول إلى Flutter
    """
    courses_data, rooms = fetch_from_mysql()

    # نُحضّر البيانات في شكل Model
    class C:
        def __init__(self, d): self.day, self.time, self.name, self.students = d["day"], d["time"], d["name"], d["students"]
    courses = [C(r) for r in courses_data]

    # نجمع حسب اليوم والوقت
    schedule_groups: Dict[(str,str), List[C]] = {}
    for c in courses:
        key = (c.day, c.time)
        schedule_groups.setdefault(key, []).append(c)

    result: Dict[str, object] = {}

    for (day, time), group in schedule_groups.items():
        solver = pywraplp.Solver.CreateSolver("SCIP")
        if not solver:
            raise HTTPException(status_code=500, detail="Solver not available")

        assign = {}
        used = {}
        extras = []

        # متغيرات
        for i, course in enumerate(group):
            for room in rooms:
                assign[(i, room)] = solver.IntVar(0, rooms[room], f"x_{i}_{room}")
        for room in rooms:
            used[room] = solver.BoolVar(f"u_{room}")

        # كل طالب يجب تخصيصه
        for i, course in enumerate(group):
            solver.Add(solver.Sum(assign[(i, r)] for r in rooms) == course.students)

        # لا تتجاوز السعة أو تُفعّل العلم used
        for room in rooms:
            solver.Add(
                solver.Sum(assign[(i, room)] for i in range(len(group)))
                <= rooms[room] * used[room]
            )

        # السماح بتجاوز ثُلثي السعة قليلاً (excess)
        for i, course in enumerate(group):
            for room in rooms:
                thr = int(rooms[room] * 2 / 3)
                ex = solver.IntVar(0, rooms[room], f"e_{i}_{room}")
                extras.append(ex)
                solver.Add(assign[(i, room)] <= thr + ex)

        # هدف التوازن
        solver.Minimize(solver.Sum(used.values()) + 0.01 * solver.Sum(extras))

        status = solver.Solve()
        key = f"{day} {time}"
        if status == pywraplp.Solver.OPTIMAL:
            out = {}
            for i, course in enumerate(group):
                out[course.name] = {}
                for room in rooms:
                    val = int(assign[(i, room)].solution_value())
                    if val > 0:
                        out[course.name][room] = val
            result[key] = out
        else:
            result[key] = "no solution"

    return {"status": "ok", "schedule": result}
