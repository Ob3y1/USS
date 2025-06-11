<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;


class CheatingIncident extends Model
{
    use HasFactory,SoftDeletes;

    public function distribution() {
        return $this->belongsTo(Distribution::class);
    }
}

