from pydantic import BaseModel
from typing import List, Tuple
from deap import base, creator, tools, algorithms
import random
import numpy as np
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import Union  # 🔺 أضف هذا في الأعلى
from sqlalchemy import Table, ForeignKey
from sqlalchemy.orm import relationship


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # أو استخدم ['http://localhost:56241']
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


from sqlalchemy import create_engine, Column, Integer, String, Date
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "mysql+pymysql://root@localhost/uss"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()
class ExamDay(Base):
    __tablename__ = "exam_days"
    id = Column(Integer, primary_key=True, index=True)
    day = Column(String(255))
    date = Column(Date)

class ExamTime(Base):
    __tablename__ = "exam_times"
    id = Column(Integer, primary_key=True, index=True)
    time = Column(String(255))

def get_exam_periods():
    db = SessionLocal()
    days = db.query(ExamDay).all()
    times = db.query(ExamTime).all()
    db.close()
    print("exam_days:", days)
    print("exam_times:", times)
    return [(day.id, time.time) for day in days for time in times]  # كان [(day.day, time.time)]

exam_periods = get_exam_periods()

print("exam_periods:", exam_periods)

class Subject(Base):
    __tablename__ = "subjects"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255))
    student_number = Column(Integer)
    year = Column(Integer)

    specialties = relationship("Specialty", secondary="specialty_subject", back_populates="subjects")


class Specialty(Base):
    __tablename__ = "specialties"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255))

    subjects = relationship("Subject", secondary="specialty_subject", back_populates="specialties")


class SpecialtySubject(Base):
    __tablename__ = "specialty_subject"
    id = Column(Integer, primary_key=True, index=True)
    specialty_id = Column(Integer, ForeignKey("specialties.id"))
    subject_id = Column(Integer, ForeignKey("subjects.id"))

def fetch_subjects_from_db():
    db = SessionLocal()
    all_subjects = db.query(Subject).all()
    result = []

    for subj in all_subjects:
        item = {
            "name": subj.name,
            "level": subj.year,
        }

        if subj.specialties:
            item["departments"] = [spec.name for spec in subj.specialties]

        result.append(item)

    db.close()
    return result
subjects = fetch_subjects_from_db()


NUM_SUBJECTS = len(subjects)

# إعدادات الجينات
if "FitnessMin" not in creator.__dict__:
    creator.create("FitnessMin", base.Fitness, weights=(-1.0,))
if "Individual" not in creator.__dict__:
    creator.create("Individual", list, fitness=creator.FitnessMin)

toolbox = base.Toolbox()
toolbox.register("gene", lambda: random.randint(0, len(exam_periods) - 1))
toolbox.register("individual", tools.initRepeat, creator.Individual, toolbox.gene, n=NUM_SUBJECTS)
toolbox.register("population", tools.initRepeat, list, toolbox.individual)
def fitness(individual):
    penalty = 0
    schedule = {}
    exams_by_day = {}
    subject_by_day = {}
    departments_by_day = {}

    for idx, period_index in enumerate(individual):
        subject = subjects[idx]
        level = subject["level"]
        day, slot = exam_periods[period_index]
        period = (day, slot)

        # حفظ الجدولة حسب الفترة
        schedule.setdefault(period, []).append((idx, level))

        # حفظ الامتحانات حسب اليوم
        exams_by_day.setdefault(day, []).append((slot, level, idx))

        # حفظ المستويات حسب اليوم
        subject_by_day.setdefault(day, []).append((level, idx))

        # حفظ الأقسام حسب اليوم
        if "departments" in subject:
            for dept in subject["departments"]:
                departments_by_day.setdefault(day, {}).setdefault(dept, []).append(subject["name"])

    # 1️⃣ عقوبة: مواد عامة في نفس الفترة (فرق مستوى <= 1)
    for exams in schedule.values():
        for i in range(len(exams)):
            idx1, lvl1 = exams[i]
            subj1 = subjects[idx1]
            if "departments" in subj1 and len(subj1["departments"]) <= 2:
                continue
            for j in range(i + 1, len(exams)):
                idx2, lvl2 = exams[j]
                subj2 = subjects[idx2]
                if "departments" in subj2 and len(subj2["departments"]) <= 2:
                    continue
                if abs(lvl1 - lvl2) <= 1:
                    penalty += 30

    # 2️⃣ عقوبة: مادتان بنفس المستوى في نفس اليوم على فترات متتالية (فقط العامة)
    for exams in exams_by_day.values():
        exams.sort()
        for i in range(len(exams) - 1):
            time1, lvl1, idx1 = exams[i]
            time2, lvl2, idx2 = exams[i + 1]
            subj1 = subjects[idx1]
            subj2 = subjects[idx2]
            if ("departments" in subj1 and len(subj1["departments"]) <= 2) or ("departments" in subj2 and len(subj2["departments"]) <= 2):
                continue
            if lvl1 == lvl2:
                penalty += 15

    # 3️⃣ عقوبة: أكثر من مادتين بنفس المستوى في نفس اليوم (فقط العامة)
    for levels in subject_by_day.values():
        level_counts = {}
        for lvl, idx in levels:
            subj = subjects[idx]
            if "departments" in subj and len(subj["departments"]) <= 2:
                continue
            level_counts[lvl] = level_counts.get(lvl, 0) + 1
        for count in level_counts.values():
            if count > 2:
                penalty += (count - 2) * 30

    # 4️⃣ عقوبة: تداخل تخصصات داخل نفس الفترة
    for exams in schedule.values():
        departments_in_period = []
        for idx, _ in exams:
            subj = subjects[idx]
            if "departments" in subj:
                departments_in_period.append(set(subj["departments"]))
        for i in range(len(departments_in_period)):
            for j in range(i + 1, len(departments_in_period)):
                intersection = departments_in_period[i] & departments_in_period[j]
                if intersection:
                    penalty += 30 * len(intersection)

    # 5️⃣ عقوبة: أكثر من مادة من نفس التخصص في نفس اليوم (يشمل المواد المشتركة بشكل دقيق)
    for day, dept_subjects in departments_by_day.items():
        for dept, subject_list in dept_subjects.items():
            subject_counts = {}
            for subj in subject_list:
                subject_counts[subj] = subject_counts.get(subj, 0) + 1
            for count in subject_counts.values():
                if count > 1:
                    penalty += (count - 1) * 30


    return (penalty,)

# تسجيل الدوال
toolbox.register("evaluate", fitness)
toolbox.register("mate", tools.cxTwoPoint)
toolbox.register("mutate", tools.mutUniformInt, low=0, up=len(exam_periods) - 1, indpb=0.1)
toolbox.register("select", tools.selTournament, tournsize=3)

def run_ga():
    pop = toolbox.population(n=300)
    hof = tools.HallOfFame(1)
    for gen in range(100):
        offspring = algorithms.varAnd(pop, toolbox, cxpb=0.7, mutpb=0.3)
        fits = list(map(toolbox.evaluate, offspring))
        for fit, ind in zip(fits, offspring):
            ind.fitness.values = fit
        pop[:] = toolbox.select(offspring, k=len(pop))
    hof.update(pop)
    return hof[0]

# نموذج الإخراج
class ScheduleEntry(BaseModel):
    subject: str
    level: int
    day: int 
    slot: str

@app.get("/generate", response_model=List[ScheduleEntry])
def generate_schedule():
    db = SessionLocal()
    day_map = {day.id: day.day for day in db.query(ExamDay).all()}
    best = run_ga()
    result = []
    for idx, period_index in enumerate(best):
        subject = subjects[idx]
        day_id, slot = exam_periods[period_index]
        result.append(ScheduleEntry(
            subject=subject["name"],
            level=subject["level"],
            day=day_id,
            slot=slot
        ))
    db.close()
    return result
