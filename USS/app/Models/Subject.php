<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Subject extends Model
{
    use HasFactory,SoftDeletes;
    protected $fillable = ['name', 'student_number', 'year'];

    public function schedules() {
        return $this->hasMany(Schedule::class);
    }
    public function specialties()
    {
        return $this->belongsToMany(Specialty::class);
    }
    
}

