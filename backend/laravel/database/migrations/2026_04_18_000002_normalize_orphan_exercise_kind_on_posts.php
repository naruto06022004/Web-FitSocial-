<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * kind=exercise nhưng không có exercise_id (hoặc bài tập đã xóa → null) không có trong bảng exercises → không đồng bộ admin.
     */
    public function up(): void
    {
        if (! Schema::hasTable('posts')) {
            return;
        }

        DB::table('posts')
            ->where('kind', 'exercise')
            ->where(function ($q) {
                $q->whereNull('exercise_id')->orWhere('exercise_id', '<=', 0);
            })
            ->update(['kind' => 'normal']);
    }

    public function down(): void
    {
        // Không khôi phục kind cũ (không đủ thông tin).
    }
};
