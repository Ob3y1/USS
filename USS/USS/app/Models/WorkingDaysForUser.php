<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WorkingDaysForUser extends Model
{
    use HasFactory;
    protected $table = 'working_days_for_users';

    protected $fillable = [
        'user_id',
        'day_id',
    ];

    // العلاقة مع المستخدم
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    // العلاقة مع اليوم
    public function day()
    {
        return $this->belongsTo(WorkingDay::class, 'day_id');
    }
}
