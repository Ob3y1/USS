<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class ExamDay extends Model
{
    use HasFactory,SoftDeletes;
    protected $fillable = ['day', 'date'];

    public function schedules() {
        return $this->hasMany(Schedule::class);
    }
}

