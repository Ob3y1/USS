<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Distribution extends Model
{
    use HasFactory,SoftDeletes;

    public function user() {
        return $this->belongsTo(User::class);
    }

    public function hall() {
        return $this->belongsTo(Hall::class);
    }

    public function schedule() {
        return $this->belongsTo(Schedule::class);
    }

    public function cheatingIncidents() {
        return $this->hasMany(CheatingIncident::class);
    }
}

