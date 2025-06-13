<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Schedule extends Model
{
    use HasFactory,SoftDeletes;

    public function subject() {
        return $this->belongsTo(Subject::class, 'subjects_id');
    }

    public function examDay() {
        return $this->belongsTo(ExamDay::class, 'exam_days_id');
    }

    public function examTime() {
        return $this->belongsTo(ExamTime::class, 'exam_times_id');
    }

    public function distributions() {
        return $this->hasMany(Distribution::class);
    }
}

