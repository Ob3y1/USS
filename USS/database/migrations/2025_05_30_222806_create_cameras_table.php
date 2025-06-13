<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCamerasTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('cameras', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hall_id')->constrained('halls')->onDelete('cascade');
            $table->string('address');
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
        Schema::dropIfExists('cameras');
    }
}
