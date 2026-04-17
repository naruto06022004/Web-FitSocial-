<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('users', 'bio')) {
            Schema::table('users', function (Blueprint $table) {
                $table->text('bio')->nullable()->after('role');
            });
        }

        if (! Schema::hasColumn('users', 'gym_name')) {
            Schema::table('users', function (Blueprint $table) {
                $after = Schema::hasColumn('users', 'bio') ? 'bio' : 'role';
                $table->string('gym_name', 120)->nullable()->after($after);
            });
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $drop = [];
            if (Schema::hasColumn('users', 'gym_name')) {
                $drop[] = 'gym_name';
            }
            if (Schema::hasColumn('users', 'bio')) {
                $drop[] = 'bio';
            }
            if ($drop !== []) {
                $table->dropColumn($drop);
            }
        });
    }
};
