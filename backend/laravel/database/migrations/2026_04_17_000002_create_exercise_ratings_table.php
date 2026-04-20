<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exercise_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exercise_id')->constrained('exercises')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();

            // 1..5 stars (overall required)
            $table->unsignedTinyInteger('stars_overall');
            $table->unsignedTinyInteger('stars_muscle')->nullable();
            $table->unsignedTinyInteger('stars_fat')->nullable();
            $table->unsignedTinyInteger('stars_safety')->nullable();

            $table->timestamps();

            $table->unique(['exercise_id', 'user_id']);
            $table->index(['exercise_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercise_ratings');
    }
};

