<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\Post;
use App\Models\PostRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PostRankingController extends Controller
{
    /**
     * Rank exercise-posts by vote count (rating_count desc).
     */
    public function exercisePostsByVotes(Request $request)
    {
        $data = $request->validate([
            'period' => ['nullable', 'string', 'in:day,week,month,all'],
        ]);

        $period = $data['period'] ?? 'week';
        $start = match ($period) {
            'day' => now()->startOfDay(),
            'month' => now()->startOfMonth(),
            'all' => null,
            default => now()->startOfWeek(),
        };

        $q = PostRating::query()
            ->select('post_id', DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars) as rating_avg'))
            ->join('posts', 'posts.id', '=', 'post_ratings.post_id')
            ->where('posts.exercise_id', '>', 0)
            ->whereExists(function ($sub) {
                $sub->select(DB::raw(1))
                    ->from('exercises')
                    ->whereColumn('exercises.id', 'posts.exercise_id');
            })
            ->groupBy('post_id')
            ->orderByDesc('rating_count')
            ->orderByDesc('rating_avg')
            ->limit(50);

        if ($start !== null) {
            $q->where('post_ratings.created_at', '>=', $start);
        }

        $rows = $q->get();
        $postIds = $rows->pluck('post_id')->all();

        $posts = Post::query()
            ->whereIn('id', $postIds)
            ->get(['id', 'title', 'exercise_id', 'created_at'])
            ->keyBy('id');

        $exerciseIds = $posts->pluck('exercise_id')->filter()->unique()->values()->all();
        $exercisesById = collect();
        if (!empty($exerciseIds)) {
            $exercisesById = Exercise::query()
                ->whereIn('id', $exerciseIds)
                ->get(['id', 'name', 'type', 'difficulty', 'met', 'coeff', 'is_approved'])
                ->keyBy('id');
        }

        $ranked = $rows->values()->map(function ($r, $idx) use ($posts, $exercisesById) {
            $p = $posts->get($r->post_id);
            $exercise = null;
            if ($p && $p->exercise_id) {
                $e = $exercisesById->get($p->exercise_id);
                if ($e) {
                    $exercise = [
                        'id' => $e->id,
                        'name' => $e->name,
                        'type' => $e->type,
                        'difficulty' => $e->difficulty,
                        'met' => $e->met,
                        'coeff' => $e->coeff,
                        'is_approved' => (bool) $e->is_approved,
                    ];
                }
            }

            return [
                'rank' => $idx + 1,
                'post_id' => (int) $r->post_id,
                'title' => $p?->title ?? 'Unknown',
                'exercise_id' => $p?->exercise_id,
                'exercise' => $exercise,
                'rating_count' => (int) $r->rating_count,
                'rating_avg' => round((float) $r->rating_avg, 3),
                'created_at' => $p?->created_at,
            ];
        });

        return response()->json([
            'data' => $ranked,
            'meta' => [
                'period' => $period,
                'start_at' => $start?->toIso8601String(),
            ],
        ]);
    }
}

