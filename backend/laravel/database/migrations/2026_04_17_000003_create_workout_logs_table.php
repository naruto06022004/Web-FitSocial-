<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('workout_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('exercise_id')->constrained('exercises')->cascadeOnDelete();

            // Inputs (some may be null depending on exercise type)
            $table->unsignedInteger('reps')->nullable();
            $table->decimal('weight_kg', 8, 2)->nullable();
            $table->unsignedInteger('duration_sec')->nullable();
            $table->decimal('distance_km', 8, 3)->nullable();
            $table->unsignedTinyInteger('rpe')->nullable(); // 1..10

            // Stored computed values to make leaderboards fast and deterministic.
            $table->decimal('cost_points', 12, 4)->default(0);

            $table->dateTime('performed_at');
            $table->timestamps();

            $table->index(['user_id', 'performed_at']);
            $table->index(['exercise_id', 'performed_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('workout_logs');
    }
};

