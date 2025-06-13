<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateCheatingIncidentsTable extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::create('cheating_incidents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('distribution_id')->constrained('distributions')->onDelete('cascade');
            $table->string('cheating_type');
            $table->string('video_snapshot');
            $table->string('Dealing_with_cheating');
            $table->timestamp('timestamp');
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
        Schema::dropIfExists('cheating_incidents');
    }
}
