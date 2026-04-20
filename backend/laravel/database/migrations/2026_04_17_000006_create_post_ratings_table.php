<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('post_ratings')) {
            return;
        }

        Schema::create('post_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('post_id')->constrained('posts')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('stars'); // 1..5
            $table->timestamps();

            $table->unique(['post_id', 'user_id']);
            $table->index(['post_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('post_ratings');
    }
};

