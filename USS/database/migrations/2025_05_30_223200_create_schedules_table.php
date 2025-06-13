<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateSchedulesTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('schedule', function (Blueprint $table) {
            $table->id();
            $table->foreignId('subjects_id')->constrained('subjects')->onDelete('cascade');
            $table->foreignId('exam_days_id')->constrained('exam_days')->onDelete('cascade');
            $table->foreignId('exam_times_id')->constrained('exam_times')->onDelete('cascade');
            $table->timestamps();
            $table->softDeletes();

        });
        
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('schedules');
    }
}
