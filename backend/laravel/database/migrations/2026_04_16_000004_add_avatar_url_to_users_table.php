<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('users', 'avatar_url')) {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'gym_name')) {
                $table->string('avatar_url', 500)->nullable()->after('gym_name');
            } elseif (Schema::hasColumn('users', 'bio')) {
                $table->string('avatar_url', 500)->nullable()->after('bio');
            } else {
                $table->string('avatar_url', 500)->nullable()->after('role');
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('users', 'avatar_url')) {
            return;
        }

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['avatar_url']);
        });
    }
};

