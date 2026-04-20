<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('posts')) {
            return;
        }

        Schema::table('posts', function (Blueprint $table) {
            if (! Schema::hasColumn('posts', 'kind')) {
                $table->string('kind', 20)->default('normal')->after('user_id'); // normal | exercise
                $table->index('kind');
            }

            if (! Schema::hasColumn('posts', 'exercise_id')) {
                $table->foreignId('exercise_id')->nullable()->after('kind')->constrained('exercises')->nullOnDelete();
                $table->index('exercise_id');
            }
        });
    }

    public function down(): void
    {
        if (! Schema::hasTable('posts')) {
            return;
        }

        Schema::table('posts', function (Blueprint $table) {
            if (Schema::hasColumn('posts', 'exercise_id')) {
                $table->dropConstrainedForeignId('exercise_id');
            }
            if (Schema::hasColumn('posts', 'kind')) {
                $table->dropIndex(['kind']);
                $table->dropColumn('kind');
            }
        });
    }
};

