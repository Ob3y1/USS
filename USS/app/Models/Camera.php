<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Camera extends Model
{
    use HasFactory,SoftDeletes;
    protected $fillable = ['hall_id', 'address'];

    public function hall() {
        return $this->belongsTo(Hall::class);
    }
}