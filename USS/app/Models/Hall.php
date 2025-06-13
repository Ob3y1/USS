<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Hall extends Model
{
    use HasFactory,SoftDeletes;
    protected $fillable = ['location','chair_number'];

    public function distributions() {
        return $this->hasMany(Distribution::class);
    }

    public function cameras() {
        return $this->hasMany(Camera::class);
    }
}

