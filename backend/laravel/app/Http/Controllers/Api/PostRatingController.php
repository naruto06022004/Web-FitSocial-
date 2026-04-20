<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PostRatingController extends Controller
{
    public function rate(Request $request, Post $post)
    {
        if (! $post->isExercisePost()) {
            return response()->json(['message' => 'Ratings only available for exercise posts'], 422);
        }

        $data = $request->validate([
            'stars' => ['required', 'integer', 'min:1', 'max:5'],
        ]);

        PostRating::query()->updateOrCreate(
            [
                'post_id' => $post->id,
                'user_id' => $request->user()->id,
            ],
            [
                'stars' => (int) $data['stars'],
            ],
        );

        return response()->json(['ok' => true]);
    }

    public function summary(Post $post)
    {
        if (! $post->isExercisePost()) {
            return response()->json(['message' => 'Ratings only available for exercise posts'], 422);
        }

        $agg = PostRating::query()
            ->select(DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars) as rating_avg'))
            ->where('post_id', $post->id)
            ->first();

        return response()->json([
            'data' => [
                'rating_count' => $agg ? (int) $agg->rating_count : 0,
                'rating_avg' => $agg ? (float) $agg->rating_avg : null,
            ],
        ]);
    }
}

