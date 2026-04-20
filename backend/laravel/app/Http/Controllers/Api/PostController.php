<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Post;
use App\Models\Exercise;
use App\Models\PostRating;
use Illuminate\Support\Facades\DB;

class PostController extends Controller
{
    public function index(Request $request)
    {
        $q = Post::query()->latest();
        if ($request->filled('kind')) {
            $q->where('kind', strtolower((string) $request->query('kind')));
        }

        $posts = $q->limit(100)->get(['id', 'user_id', 'kind', 'exercise_id', 'title', 'content', 'created_at', 'updated_at']);

        $exerciseIds = $posts->pluck('exercise_id')->filter()->unique()->values()->all();
        $exercisesById = collect();
        if (!empty($exerciseIds)) {
            $exercisesById = Exercise::query()
                ->whereIn('id', $exerciseIds)
                ->get(['id', 'name', 'type', 'difficulty', 'met', 'is_approved'])
                ->keyBy('id');
        }

        $postIds = $posts->pluck('id')->all();
        $ratingAgg = collect();
        if (!empty($postIds)) {
            $ratingAgg = PostRating::query()
                ->select('post_id', DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars) as rating_avg'))
                ->whereIn('post_id', $postIds)
                ->groupBy('post_id')
                ->get()
                ->keyBy('post_id');
        }

        $data = $posts->map(function (Post $p) use ($ratingAgg, $exercisesById) {
            $agg = $ratingAgg->get($p->id);
            $exerciseId = (int) ($p->exercise_id ?? 0);
            $exercise = null;
            if ($exerciseId > 0) {
                $e = $exercisesById->get($exerciseId);
                if ($e) {
                    $exercise = [
                        'id' => $e->id,
                        'name' => $e->name,
                        'type' => $e->type,
                        'difficulty' => $e->difficulty,
                        'met' => $e->met,
                        'is_approved' => (bool) $e->is_approved,
                    ];
                }
            }

            $kindOut = $exerciseId > 0 ? 'exercise' : strtolower((string) ($p->kind ?? 'normal'));

            return [
                'id' => $p->id,
                'user_id' => $p->user_id,
                'kind' => $kindOut,
                'exercise_id' => $p->exercise_id,
                'exercise' => $exercise,
                'title' => $p->title,
                'content' => $p->content,
                'created_at' => $p->created_at,
                'updated_at' => $p->updated_at,
                'rating_avg' => $agg ? (float) $agg->rating_avg : null,
                'rating_count' => $agg ? (int) $agg->rating_count : 0,
            ];
        })->values();

        return response()->json(['data' => $data]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'kind' => ['nullable', 'string', 'in:normal,exercise'],
            'title' => ['required', 'string', 'max:120'],
            'content' => ['nullable', 'string', 'max:5000'],
            'exercise_id' => ['nullable', 'integer', 'exists:exercises,id'],
            // Optional inline exercise creation for exercise post
            'exercise' => ['nullable', 'array'],
            'exercise.name' => ['required_with:exercise', 'string', 'max:180'],
            'exercise.type' => ['required_with:exercise', 'string', 'max:30'],
            'exercise.difficulty' => ['nullable', 'integer', 'min:1', 'max:5'],
            'exercise.met' => ['nullable', 'numeric', 'min:0', 'max:30'],
        ]);

        $kind = strtolower((string) ($data['kind'] ?? 'normal'));
        $exerciseId = null;
        if ($kind === 'exercise') {
            if (isset($data['exercise_id'])) {
                $exerciseId = (int) $data['exercise_id'];
            } elseif (isset($data['exercise']) && is_array($data['exercise'])) {
                $ex = $data['exercise'];
                $exercise = Exercise::query()->create([
                    'name' => trim((string) ($ex['name'] ?? '')),
                    'type' => strtolower((string) ($ex['type'] ?? 'strength')),
                    'difficulty' => (int) ($ex['difficulty'] ?? 2),
                    'met' => $ex['met'] ?? null,
                    'coeff' => 1.0,
                    'is_approved' => false,
                    'created_by' => $request->user()->id,
                ]);
                $exerciseId = $exercise->id;
            } else {
                return response()->json(['message' => 'exercise_id or exercise payload is required for exercise post'], 422);
            }
        }

        $post = Post::query()->create([
            'user_id' => $request->user()->id,
            'kind' => $kind,
            'exercise_id' => $exerciseId,
            'title' => $data['title'],
            'content' => $data['content'] ?? null,
        ]);

        return response()->json(['data' => $post], 201);
    }

    public function show(Post $post)
    {
        $agg = PostRating::query()
            ->select(DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars) as rating_avg'))
            ->where('post_id', $post->id)
            ->first();

        $exerciseId = (int) ($post->exercise_id ?? 0);
        $exercise = null;
        if ($exerciseId > 0) {
            $e = Exercise::query()->find($exerciseId);
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

        $kindOut = $exerciseId > 0 ? 'exercise' : strtolower((string) ($post->kind ?? 'normal'));

        return response()->json([
            'data' => [
                'id' => $post->id,
                'user_id' => $post->user_id,
                'kind' => $kindOut,
                'exercise_id' => $post->exercise_id,
                'exercise' => $exercise,
                'title' => $post->title,
                'content' => $post->content,
                'created_at' => $post->created_at,
                'updated_at' => $post->updated_at,
                'rating_avg' => $agg ? (float) $agg->rating_avg : null,
                'rating_count' => $agg ? (int) $agg->rating_count : 0,
            ],
        ]);
    }

    public function update(Request $request, Post $post)
    {
        if ($request->user()->role !== 'admin'
            && $request->user()->role !== 'staff'
            && $post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:120'],
            'content' => ['nullable', 'string', 'max:5000'],
        ]);

        $post->fill($data);
        $post->save();

        return response()->json(['data' => $post]);
    }

    public function destroy(Request $request, Post $post)
    {
        if ($request->user()->role !== 'admin'
            && $request->user()->role !== 'staff'
            && $post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $post->delete();
        return response()->json(['ok' => true]);
    }
}

