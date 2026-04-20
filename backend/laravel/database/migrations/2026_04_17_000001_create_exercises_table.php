<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('exercises', function (Blueprint $table) {
            $table->id();
            $table->string('name', 180);
            $table->string('type', 30); // strength | cardio | hiit | bodyweight
            $table->unsignedTinyInteger('difficulty')->default(2); // 1..5

            // Cost parameters (admin-tunable)
            $table->decimal('met', 6, 2)->nullable(); // cardio-like
            $table->decimal('coeff', 10, 4)->default(1.0); // strength-like multiplier

            $table->boolean('is_approved')->default(false);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['is_approved', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('exercises');
    }
};

