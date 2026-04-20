<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ExerciseRating extends Model
{
    protected $fillable = [
        'exercise_id',
        'user_id',
        'stars_overall',
        'stars_muscle',
        'stars_fat',
        'stars_safety',
    ];

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(Exercise::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

