
# from fastapi import FastAPI, HTTPException
# from fastapi.middleware.cors import CORSMiddleware
# from pydantic import BaseModel
# from typing import List, Dict
# from ortools.linear_solver import pywraplp
# from ortools.sat.python import cp_model
# import mysql.connector
# import os

# app = FastAPI()

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# DB_CONFIG = {
#     "host": os.getenv("DB_HOST", "127.0.0.1"),
#     "user": os.getenv("DB_USER", "root"),
#     "password": os.getenv("DB_PASS", ""),
#     "database": os.getenv("DB_NAME", "laravel_db"),
# }

# # ========== نماذج ==========

# class ScheduleItem(BaseModel):
#     day: str
#     time: str
#     room: str

# class Supervisor(BaseModel):
#     name: str
#     available_days: List[str]

# # ========== جلب البيانات من MySQL ==========

# def fetch_exam_data():
#     conn = mysql.connector.connect(**DB_CONFIG)
#     cursor = conn.cursor(dictionary=True)

#     # جلب بيانات المواد وجدول الامتحانات
#     cursor.execute("""
#         SELECT s.name, s.student_number, sch.exam_days_id AS day, sch.time_id AS time
#         FROM subjects s
#         JOIN schedule sch ON sch.subject_id = s.id
#     """)
#     courses = cursor.fetchall()

#     # جلب القاعات مع الموقع (location) وعدد الكراسي (chair_number)
#     cursor.execute("SELECT location, chair_number FROM halls")
#     halls_data = cursor.fetchall()

#     # تحويل القاعات إلى قاموس: الموقع → عدد الكراسي
#     halls = {row["location"]: row["chair_number"] for row in halls_data}

#     cursor.close()
#     conn.close()
#     return courses, halls


# def fetch_supervision_data():
#     conn = mysql.connector.connect(**DB_CONFIG)
#     cursor = conn.cursor(dictionary=True)

#     cursor.execute("SELECT DISTINCT id, exam_days_id AS day, time_id AS time FROM schedule")
#     sessions = cursor.fetchall()

#     cursor.execute("SELECT user_name, day FROM working_days_for_users")
#     raw_supervisors = cursor.fetchall()

#     supervisors: Dict[str, List[str]] = {}
#     for row in raw_supervisors:
#         name, day = row["user_name"], row["day"]
#         if name not in supervisors:
#             supervisors[name] = []
#         if day not in supervisors[name]:
#             supervisors[name].append(day)

#     cursor.close()
#     conn.close()
#     return supervisors, sessions

# # ========== توزيع الطلاب على القاعات ==========

# def solve_schedule(courses_data, rooms):
#     class C:
#         def __init__(self, d):
#             self.day = str(d["day"])
#             self.time = str(d["time"])
#             self.name = d["name"]
#             self.students = int(d["student_number"])

#     courses = [C(r) for r in courses_data]
#     schedule_groups = {}
#     for c in courses:
#         key = (c.day, c.time)
#         schedule_groups.setdefault(key, []).append(c)

#     result = {}
#     for (day, time), group in schedule_groups.items():
#         solver = pywraplp.Solver.CreateSolver("SCIP")
#         if not solver:
#             raise HTTPException(status_code=500, detail="Solver not available")

#         assign, used, extras = {}, {}, []

#         for i, course in enumerate(group):
#             for room in rooms:
#                 assign[(i, room)] = solver.IntVar(0, rooms[room], f"x_{i}_{room}")
#         for room in rooms:
#             used[room] = solver.BoolVar(f"u_{room}")

#         for i, course in enumerate(group):
#             solver.Add(solver.Sum(assign[(i, r)] for r in rooms) == course.students)

#         for room in rooms:
#             solver.Add(
#                 solver.Sum(assign[(i, room)] for i in range(len(group)))
#                 <= rooms[room] * used[room]
#             )

#         for i, course in enumerate(group):
#             for room in rooms:
#                 thr = int(rooms[room] * 2 / 3)
#                 ex = solver.IntVar(0, rooms[room], f"e_{i}_{room}")
#                 extras.append(ex)
#                 solver.Add(assign[(i, room)] <= thr + ex)

#         solver.Minimize(solver.Sum(used.values()) + 0.01 * solver.Sum(extras))

#         status = solver.Solve()
#         key = f"{day} {time}"
#         if status == pywraplp.Solver.OPTIMAL:
#             out = {}
#             for i, course in enumerate(group):
#                 out[course.name] = {}
#                 for room in rooms:
#                     val = int(assign[(i, room)].solution_value())
#                     if val > 0:
#                         out[course.name][room] = val
#             result[key] = out
#         else:
#             result[key] = "no solution"

#     return {"status": "ok", "schedule": result}

# # ========== توزيع المراقبين ==========

# def solve_supervision(supervisors, sessions):
#     model = cp_model.CpModel()
#     assign = {}

#     exam_sessions = [(str(s["day"]), str(s["time"]), str(s["id"])) for s in sessions]
#     supervisor_names = list(supervisors.keys())

#     for s in supervisor_names:
#         for (day, time, session_id) in exam_sessions:
#             assign[(s, day, time, session_id)] = model.NewBoolVar(f'assign_{s}_{day}_{time}_{session_id}')

#     for (day, time, session_id) in exam_sessions:
#         model.AddExactlyOne(assign[(s, day, time, session_id)] for s in supervisor_names)

#     time_slots = set((d, t) for (d, t, _) in exam_sessions)
#     for s in supervisor_names:
#         for (day, time) in time_slots:
#             model.Add(sum(assign[(s, d, t, sid)] for (d, t, sid) in exam_sessions if (d, t) == (day, time)) <= 1)

#     for s in supervisor_names:
#         for (day, time, session_id) in exam_sessions:
#             if day not in supervisors[s]:
#                 model.Add(assign[(s, day, time, session_id)] == 0)

#     task_count = {}
#     max_tasks = model.NewIntVar(0, len(exam_sessions), "max_tasks")
#     min_tasks = model.NewIntVar(0, len(exam_sessions), "min_tasks")
#     for s in supervisor_names:
#         task_count[s] = model.NewIntVar(0, len(exam_sessions), f'task_count_{s}')
#         model.Add(task_count[s] == sum(assign[(s, d, t, sid)] for (d, t, sid) in exam_sessions))
#         model.Add(task_count[s] <= max_tasks)
#         model.Add(task_count[s] >= min_tasks)

#     model.Minimize(max_tasks - min_tasks)

#     solver = cp_model.CpSolver()
#     status = solver.Solve(model)

#     result = {"status": "no_solution", "assignments": [], "task_count": {}}
#     if status in [cp_model.OPTIMAL, cp_model.FEASIBLE]:
#         result["status"] = "ok"
#         for (day, time, session_id) in exam_sessions:
#             for s in supervisor_names:
#                 if solver.Value(assign[(s, day, time, session_id)]) == 1:
#                     result["assignments"].append({
#                         "supervisor": s,
#                         "day": day,
#                         "time": time,
#                         "session_id": session_id
#                     })
#         result["task_count"] = {s: solver.Value(task_count[s]) for s in supervisor_names}

#     return result

# # ========== نقطة النهاية الرئيسية ==========

# @app.get("/generate-full-schedule")
# def generate_full_schedule():
#     try:
#         courses_data, halls = fetch_exam_data()
#         supervisors, sessions = fetch_supervision_data()

#         schedule_result = solve_schedule(courses_data, halls)
#         supervision_result = solve_supervision(supervisors, sessions)

#         return {
#             "status": "ok",
#             "schedule_distribution": schedule_result["schedule"],
#             "supervision_assignment": supervision_result["assignments"],
#             "supervision_tasks": supervision_result["task_count"]
#         }

#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))


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
    date: str  # إضافة
    day: str
    time: str
    room: str


class SupervisorAssignment(BaseModel):  # نموذج جديد
    supervisor: str
    date: str
    day: str
    time: str
    session_id: str


def fetch_exam_data():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(dictionary=True)

    # جلب بيانات المواد وجدول الامتحانات مع التاريخ
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

    # جلب القاعات مع الموقع (location) وعدد الكراسي (chair_number)
    cursor.execute("""
        SELECT location, chair_number 
        FROM halls 
        WHERE deleted_at IS NULL
    """)
    halls_data = cursor.fetchall()

    # تحويل القاعات إلى قاموس: الموقع → عدد الكراسي
    halls = {row["location"]: row["chair_number"] for row in halls_data}

    cursor.close()
    conn.close()
    return courses, halls


def fetch_supervision_data():
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor(dictionary=True)

    # جلب جلسات الامتحانات مع التاريخ
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

    # جلب المراقبين
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

    # تسجيل البيانات للتصحيح
    print("عدد جلسات الامتحانات:", len(sessions))
    print("عينة من جلسات الامتحانات:", sessions[:1])  # طباعة أول جلسة كمثال
    print("عدد المراقبين:", len(supervisors))

    return supervisors, sessions


# ========== توزيع الطلاب على القاعات ==========

def solve_schedule(courses_data, rooms):
    class C:
        def __init__(self, d):
            self.day = str(d["day"])
            self.date = str(d["date"])  # إضافة التاريخ
            self.time = str(d["time"])
            self.name = d["name"]
            self.students = int(d["student_number"])

    courses = [C(r) for r in courses_data]
    schedule_groups = {}
    for c in courses:
        key = (c.date, c.day, c.time)  # إضافة التاريخ كمفتاح
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
        key = f"{date} {day} {time}"  # تعديل المفتاح ليشمل التاريخ
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


# ========== توزيع المراقبين ==========

def solve_supervision(supervisors, sessions):
    if not supervisors or not sessions:
        return {
            "status": "error",
            "message": "لا يوجد مراقبون أو جلسات متاحة",
            "assignments": [],
            "task_count": {}
        }

    model = cp_model.CpModel()
    assign = {}

    # تحضير بيانات الجلسات مع التحقق من الهيكل
    exam_sessions = []
    for s in sessions:
        try:
            # التأكد من وجود جميع الحقول المطلوبة
            required_fields = ['id', 'day', 'date', 'time']
            if not all(field in s for field in required_fields):
                print(f"تحذير: جلسة ناقصة البيانات: {s}")
                continue

            session_data = (
                str(s['date']),    # التاريخ
                str(s['day']).strip().lower(),  # اليوم
                str(s['time']).strip().lower(), # الوقت
                str(s['id'])      # معرف الجلسة
            )
            exam_sessions.append(session_data)
        except Exception as e:
            print(f"تحذير: خطأ في معالجة الجلسة {s}: {str(e)}")
            continue

    if not exam_sessions:
        return {
            "status": "error",
            "message": "لا توجد جلسات صالحة للتوزيع",
            "assignments": [],
            "task_count": {}
        }

    supervisor_names = list(supervisors.keys())

    # 1. إنشاء متغيرات القرار مع الهيكل الصحيح
    for s in supervisor_names:
        for session in exam_sessions:
            # تفريغ القيم حسب الهيكل المتوقع
            date, day, time, session_id = session
            assign[(s, date, day, time, session_id)] = model.NewBoolVar(f'assign_{s}_{date}_{day}_{time}_{session_id}')

    # 2. كل جلسة يجب أن يكون لها مراقب واحد بالضبط
    for session in exam_sessions:
        date, day, time, session_id = session
        available_supervisors = [
            s for s in supervisor_names 
            if day in [d.lower().strip() for d in supervisors[s]]
        ]

        if not available_supervisors:
            print(f"تحذير: لا يوجد مراقبون متاحون لجلسة {date} {day} {time}")
            continue

        model.AddExactlyOne(
            assign[(s, date, day, time, session_id)] 
            for s in available_supervisors
        )

    # 3. لا يمكن للمراقب أن يكون في أكثر من جلسة في نفس الوقت (نفس التاريخ والوقت)
    time_slots = set((date, day, time) for (date, day, time, _) in exam_sessions)
    for s in supervisor_names:
        for slot in time_slots:
            date, day, time = slot
            model.Add(
                sum(
                    assign[(s, dt, d, t, sid)] 
                    for (dt, d, t, sid) in exam_sessions 
                    if (dt, d, t) == (date, day, time)
                ) <= 1
            )

    # 4. موازنة عدد المهام بين المراقبين
    task_count = {}
    max_tasks = model.NewIntVar(0, len(exam_sessions), "max_tasks")
    min_tasks = model.NewIntVar(0, len(exam_sessions), "min_tasks")

    for s in supervisor_names:
        task_count[s] = model.NewIntVar(0, len(exam_sessions), f'task_count_{s}')
        model.Add(
            task_count[s] == sum(
                assign[(s, date, day, time, sid)] 
                for (date, day, time, sid) in exam_sessions
            )
        )
        model.Add(task_count[s] <= max_tasks)
        model.Add(task_count[s] >= min_tasks)

    model.Minimize(max_tasks - min_tasks)

    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = 30.0
    status = solver.Solve(model)

    result = {
        "status": "no_solution",
        "assignments": [],
        "task_count": {},
        "message": ""
    }

    if status in [cp_model.OPTIMAL, cp_model.FEASIBLE]:
        result["status"] = "ok"
        for session in exam_sessions:
            date, day, time, session_id = session
            for s in supervisor_names:
                if solver.Value(assign[(s, date, day, time, session_id)]) == 1:
                    result["assignments"].append({
                        "supervisor": s,
                        "date": date,
                        "day": day,
                        "time": time,
                        "session_id": session_id
                    })
        result["task_count"] = {s: solver.Value(task_count[s]) for s in supervisor_names}
    else:
        result["message"] = solver.StatusName(status)
        print(f"فشل في إيجاد حل. الحالة: {solver.StatusName(status)}")

    return result


# ========== نقطة النهاية الرئيسية ==========

@app.get("/generate-full-schedule")
def generate_full_schedule():
    try:
        courses_data, halls = fetch_exam_data()
        supervisors, sessions = fetch_supervision_data()

        # تسجيل البيانات للتصحيح
        print(f"تم جلب {len(courses_data)} مادة و{len(halls)} قاعة")
        print(f"تم جلب {len(supervisors)} مراقب و{len(sessions)} جلسة امتحان")

        schedule_result = solve_schedule(courses_data, halls)
        supervision_result = solve_supervision(supervisors, sessions)

        return {
            "status": "ok",
            "schedule_distribution": schedule_result["schedule"],
            "supervision_assignment": supervision_result["assignments"],
            "supervision_tasks": supervision_result["task_count"]
        }

    except Exception as e:
        print(f"حدث خطأ: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
