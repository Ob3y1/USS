from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
from ortools.sat.python import cp_model
from fastapi.testclient import TestClient
import random

app = FastAPI()

# السماح بالاتصال من Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # لتجربة محلية فقط، غيّرها عند النشر
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# نماذج البيانات
class ExamSession(BaseModel):
    day: str
    time: str
    room: str

class Supervisor(BaseModel):
    name: str
    available_days: List[str]

class SupervisionRequest(BaseModel):
    sessions: List[ExamSession]
    supervisors: List[Supervisor]

# بيانات تجريبية
DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday"]
TIMES = ["9:00", "11:00", "13:00"]
ROOMS = [f"Room {i}" for i in range(1, 6)]

# توليد بيانات عشوائية
def generate_mock_data():
    sessions = []
    for _ in range(10):
        day = random.choice(DAYS)
        time = random.choice(TIMES)
        room = random.choice(ROOMS)
        sessions.append(ExamSession(day=day, time=time, room=room))

    supervisors = []
    for i in range(6):
        name = f"Supervisor {i + 1}"
        available_days = random.sample(DAYS, k=random.randint(2, 4))
        supervisors.append(Supervisor(name=name, available_days=available_days))

    return {
        "sessions": [s.dict() for s in sessions],
        "supervisors": [s.dict() for s in supervisors]
    }

# نقطة النهاية الأصلية للتوزيع
@app.post("/assign-supervisors")
def assign_supervisors(request: SupervisionRequest):
    sessions = request.sessions
    supervisors_input = request.supervisors

    model = cp_model.CpModel()
    assign = {}

    exam_sessions = [(s.day, s.time, s.room) for s in sessions]
    supervisors = {s.name: s.available_days for s in supervisors_input}
    supervisor_names = list(supervisors.keys())

    for s in supervisor_names:
        for (day, time, room) in exam_sessions:
            assign[(s, day, time, room)] = model.NewBoolVar(f'assign_{s}_{day}_{time}_{room}')

    for (day, time, room) in exam_sessions:
        model.AddExactlyOne(assign[(s, day, time, room)] for s in supervisor_names)

    time_slots = set((d, t) for (d, t, _) in exam_sessions)
    for s in supervisor_names:
        for (day, time) in time_slots:
            model.Add(sum(assign[(s, d, t, r)]
                          for (d, t, r) in exam_sessions if (d, t) == (day, time)) <= 1)

    for s in supervisor_names:
        for (day, time, room) in exam_sessions:
            if day not in supervisors[s]:
                model.Add(assign[(s, day, time, room)] == 0)

    task_count = {}
    max_tasks = model.NewIntVar(0, len(exam_sessions), "max_tasks")
    min_tasks = model.NewIntVar(0, len(exam_sessions), "min_tasks")
    for s in supervisor_names:
        task_count[s] = model.NewIntVar(0, len(exam_sessions), f'task_count_{s}')
        model.Add(task_count[s] == sum(assign[(s, d, t, r)] for (d, t, r) in exam_sessions))
        model.Add(task_count[s] <= max_tasks)
        model.Add(task_count[s] >= min_tasks)

    model.Minimize(max_tasks - min_tasks)

    solver = cp_model.CpSolver()
    status = solver.Solve(model)

    result = {"status": "no_solution", "assignments": [], "task_count": {}}
    if status in [cp_model.OPTIMAL, cp_model.FEASIBLE]:
        result["status"] = "ok"
        for (day, time, room) in exam_sessions:
            for s in supervisor_names:
                if solver.Value(assign[(s, day, time, room)]) == 1:
                    result["assignments"].append({
                        "supervisor": s,
                        "day": day,
                        "time": time,
                        "room": room
                    })
        result["task_count"] = {s: solver.Value(task_count[s]) for s in supervisor_names}

    return result

# ✅ نقطة النهاية الجديدة لتجربة البيانات مباشرة
@app.get("/dummy-assignments")
def dummy_assignments():
    mock_data = generate_mock_data()

    # استخدم TestClient لاستدعاء نفس منطق التوزيع
    client = TestClient(app)
    response = client.post("/assign-supervisors", json=mock_data)
    return response.json()

# يمكن الإبقاء على init-supervision-data في حال أردت فقط مشاهدة البيانات الأولية
@app.get("/init-supervision-data")
def init_supervision_data():
    return generate_mock_data()
