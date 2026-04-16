<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('key', 40)->unique();   // e.g. admin, staff, user, moderator
            $table->string('label', 80);           // e.g. Admin, Teacher, Student
            $table->json('permissions')->nullable(); // { "admin_access": true, ... }
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('roles');
    }
};

