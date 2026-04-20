<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Post extends Model
{
    protected $fillable = [
        'user_id',
        'kind',
        'exercise_id',
        'title',
        'content',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(PostComment::class);
    }

    public function ratings(): HasMany
    {
        return $this->hasMany(PostRating::class);
    }

    /** Bài đăng gắn bài tập thật (có exercise_id); khớp feed, ranking, Quản lý bài tập. */
    public function isExercisePost(): bool
    {
        return (int) ($this->exercise_id ?? 0) > 0;
    }
}

