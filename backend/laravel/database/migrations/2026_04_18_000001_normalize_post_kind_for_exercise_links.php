<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Mọi post đã gắn exercise_id phải là kind exercise (vote, ranking, posts_count đồng bộ).
     */
    public function up(): void
    {
        if (! Schema::hasTable('posts') || ! Schema::hasColumn('posts', 'exercise_id')) {
            return;
        }

        DB::table('posts')
            ->whereNotNull('exercise_id')
            ->where('exercise_id', '>', 0)
            ->update(['kind' => 'exercise']);
    }

    public function down(): void
    {
        // Không revert: trạng thái trước có thể sai nghiệp vụ.
    }
};
