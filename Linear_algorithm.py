from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict
from ortools.linear_solver import pywraplp
from ortools.sat.python import cp_model
import mysql.connector
import os

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
 
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "127.0.0.1"),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASS", ""),
    "database": os.getenv("DB_NAME", "uss"),
}


class ScheduleItem(BaseModel):
    date: str
    day: str
    time: str
    room: str

class SupervisorAssignment(BaseModel):
    supervisor: str
    date: str
    day: str
    time: str
    hall: str
    courses: List[str]
    total_students: int

def fetch_exam_data():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT s.name, s.student_number, ed.day AS day, ed.date AS date, et.time AS time
        FROM subjects s
        JOIN schedule sch ON sch.subjects_id = s.id
        JOIN exam_days ed ON sch.exam_days_id = ed.id
        JOIN exam_times et ON sch.exam_times_id = et.id
        WHERE s.deleted_at IS NULL
        AND sch.deleted_at IS NULL
        AND ed.deleted_at IS NULL
        AND et.deleted_at IS NULL
    """)
    courses = cursor.fetchall()

    cursor.execute("""
        SELECT location, chair_number 
        FROM halls 
        WHERE deleted_at IS NULL
    """)
    halls_data = cursor.fetchall()

    halls = {row["location"]: row["chair_number"] for row in halls_data}

    cursor.close()
    conn.close()
    return courses, halls

def fetch_supervision_data():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(dictionary=True)

    # جلب جلسات الامتحانات مع التاريخ (بدون معلومات القاعة)
    cursor.execute("""
        SELECT sch.id, ed.day AS day, ed.date AS date, et.time AS time
        FROM schedule sch
        JOIN exam_days ed ON sch.exam_days_id = ed.id
        JOIN exam_times et ON sch.exam_times_id = et.id
        WHERE sch.deleted_at IS NULL
        AND ed.deleted_at IS NULL
        AND et.deleted_at IS NULL
    """)
    sessions = cursor.fetchall()
    
    # بقية الدالة تبقى كما هي...
    cursor.execute("""
        SELECT u.name, wd.day
        FROM users u
        JOIN working_days_for_users wdfu ON wdfu.user_id = u.id
        JOIN working_days wd ON wdfu.day_id = wd.id
        WHERE u.role_id = 2
        AND u.deleted_at IS NULL
        AND wd.deleted_at IS NULL
    """)
    raw_supervisors = cursor.fetchall()

    supervisors = {}
    for row in raw_supervisors:
        name, day = row["name"], row["day"]
        if name not in supervisors:
            supervisors[name] = []
        if day not in supervisors[name]:
            supervisors[name].append(day)

    cursor.close()
    conn.close()
    
    print("عدد جلسات الامتحانات:", len(sessions))
    print("عدد المراقبين:", len(supervisors))
    
    return supervisors, sessions

def solve_schedule(courses_data, rooms):
    class C:
        def __init__(self, d):
            self.day = str(d["day"])
            self.date = str(d["date"])
            self.time = str(d["time"])
            self.name = d["name"]
            self.students = int(d["student_number"])

    courses = [C(r) for r in courses_data]
    schedule_groups = {}
    for c in courses:
        key = (c.date, c.day, c.time)
        schedule_groups.setdefault(key, []).append(c)

    result = {}
    for (date, day, time), group in schedule_groups.items():
        solver = pywraplp.Solver.CreateSolver("SCIP")
        if not solver:
            raise HTTPException(status_code=500, detail="Solver not available")

        assign, used, extras = {}, {}, []

        for i, course in enumerate(group):
            for room in rooms:
                assign[(i, room)] = solver.IntVar(0, rooms[room], f"x_{i}_{room}")
        for room in rooms:
            used[room] = solver.BoolVar(f"u_{room}")

        for i, course in enumerate(group):
            solver.Add(solver.Sum(assign[(i, r)] for r in rooms) == course.students)

        for room in rooms:
            solver.Add(
                solver.Sum(assign[(i, room)] for i in range(len(group)))
                <= rooms[room] * used[room]
            )

        for i, course in enumerate(group):
            for room in rooms:
                thr = int(rooms[room] * 2 / 3)
                ex = solver.IntVar(0, rooms[room], f"e_{i}_{room}")
                extras.append(ex)
                solver.Add(assign[(i, room)] <= thr + ex)

        solver.Minimize(solver.Sum(used.values()) + 0.01 * solver.Sum(extras))

        status = solver.Solve()
        key = f"{date} {day} {time}"
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


def solve_supervision(supervisors, sessions, schedule_distribution):
    if not supervisors or not sessions:
        return {
            "status": "error",
            "message": "لا يوجد مراقبون أو جلسات متاحة",
            "assignments": [],
            "task_count": {}
        }

    model = cp_model.CpModel()
    assign = {}

    # 1. استخلاص توزيع القاعات من schedule_distribution
    hall_assignments = {}
    for time_slot, courses in schedule_distribution.items():
        if isinstance(courses, str) and courses == "no solution":
            continue
            
        try:
            date, day, time = time_slot.split()[:3]
            for course, halls in courses.items():
                if isinstance(halls, dict):
                    for hall, students in halls.items():
                        key = (date, day, time, hall)
                        if key not in hall_assignments:
                            hall_assignments[key] = {
                                "courses": [],
                                "total_students": 0
                            }
                        hall_assignments[key]["courses"].append(course)
                        hall_assignments[key]["total_students"] += students
        except Exception as e:
            print(f"خطأ في معالجة بيانات القاعات: {e}")
            continue

    if not hall_assignments:
        return {
            "status": "error",
            "message": "لا توجد قاعات مجدولة",
            "assignments": [],
            "task_count": {}
        }

    # 2. إنشاء متغيرات القرار
    supervisor_names = list(supervisors.keys())
    hall_slots = list(hall_assignments.keys())
    
    # متغيرات القرار: هل المراقب s مكلف بالقاعة hall في الوقت المحدد؟
    for s in supervisor_names:
        for slot in hall_slots:
            assign[(s, *slot)] = model.NewBoolVar(f'assign_{s}_{"_".join(str(x) for x in slot)}')

    # 3. القيود الأساسية
    # أ. مراقب واحد بالضبط لكل قاعة
    for slot in hall_slots:
        date, day, time, hall = slot
        available_supervisors = [
            s for s in supervisor_names 
            if day.lower() in [d.lower() for d in supervisors[s]]
        ]
        if not available_supervisors:
            print(f"تحذير: لا يوجد مراقبون متاحون للقاعة {hall} في {date} {time}")
            continue
            
        model.AddExactlyOne(
            assign[(s, *slot)] for s in available_supervisors
        )

    # ب. لا يمكن للمراقب أن يكون في أكثر من قاعة في نفس الوقت
    time_slots = set((date, day, time) for (date, day, time, hall) in hall_slots)
    for s in supervisor_names:
        for slot in time_slots:
            model.Add(
                sum(
                    assign.get((s, *slot, hall), 0)
                    for hall in [h for (d, dy, t, h) in hall_slots 
                               if (d, dy, t) == slot]
                ) <= 1
            )

    # 4. تحقيق التوزيع العادل
    # أ. حساب عدد المهام لكل مراقب
    task_counts = []
    for s in supervisor_names:
        task_count = model.NewIntVar(0, len(hall_slots), f'tasks_{s}')
        model.Add(
            task_count == sum(
                assign[(s, *slot)] for slot in hall_slots
            )
        )
        task_counts.append(task_count)

    # ب. حساب الحد الأدنى والأقصى للمهام
    max_tasks = model.NewIntVar(0, len(hall_slots), 'max_tasks')
    min_tasks = model.NewIntVar(0, len(hall_slots), 'min_tasks')
    
    for s in supervisor_names:
        model.Add(task_counts[supervisor_names.index(s)] >= min_tasks)
        model.Add(task_counts[supervisor_names.index(s)] <= max_tasks)

    # ج. تقليل الفرق بين الحد الأقصى والأدنى
    model.Minimize(max_tasks - min_tasks)

    # 5. حل النموذج
    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = 60.0  # زيادة وقت الحل
    solver.parameters.num_search_workers = 4  # استخدام عدة نوى معالجة
    status = solver.Solve(model)

    # 6. تجميع النتائج
    result = {
        "status": "ok" if status in [cp_model.OPTIMAL, cp_model.FEASIBLE] else "no_solution",
        "assignments": [],
        "task_count": {s: 0 for s in supervisor_names},
        "message": solver.StatusName(status) if status != cp_model.OPTIMAL else ""
    }

    if result["status"] == "ok":
        assigned_slots = set()  # لتتبع القاعات التي تم تعيينها
        
        for slot in hall_slots:
            date, day, time, hall = slot
            for s in supervisor_names:
                if solver.Value(assign[(s, *slot)]) == 1:
                    if slot not in assigned_slots:
                        result["assignments"].append({
                            "supervisor": s,
                            "date": date,
                            "day": day,
                            "time": time,
                            "hall": hall,
                            "courses": hall_assignments[slot]["courses"],
                            "total_students": hall_assignments[slot]["total_students"]
                        })
                        result["task_count"][s] += 1
                        assigned_slots.add(slot)
                    else:
                        print(f"تحذير: تم تعيين أكثر من مراقب للقاعة {hall} في {date} {time}")

    return result


@app.get("/generate-full-schedule")
def generate_full_schedule():
    try:
        courses_data, halls = fetch_exam_data()
        supervisors, sessions = fetch_supervision_data()

        schedule_result = solve_schedule(courses_data, halls)
        supervision_result = solve_supervision(supervisors, sessions, schedule_result["schedule"])

        return {
            "status": "ok",
            "schedule_distribution": schedule_result["schedule"],
            "supervision_assignment": supervision_result["assignments"],
            "supervision_tasks": supervision_result["task_count"]
        }

    except Exception as e:
        print(f"حدث خطأ: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

