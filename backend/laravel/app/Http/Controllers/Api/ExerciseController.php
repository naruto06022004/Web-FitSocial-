<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\ExerciseRating;
use App\Services\ExerciseCostService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ExerciseController extends Controller
{
    public function index(Request $request)
    {
        $q = Exercise::query()->where('is_approved', true);

        if ($request->filled('type')) {
            $q->where('type', strtolower((string) $request->query('type')));
        }
        if ($request->filled('search')) {
            $s = trim((string) $request->query('search'));
            $q->where('name', 'like', "%{$s}%");
        }

        $rows = $q
            ->latest()
            ->limit(200)
            ->get(['id', 'name', 'type', 'difficulty', 'met', 'coeff', 'created_by', 'created_at']);

        // Aggregate ratings in one query.
        $ids = $rows->pluck('id')->all();
        $ratingAgg = collect();
        if (!empty($ids)) {
            $ratingAgg = ExerciseRating::query()
                ->select('exercise_id', DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars_overall) as rating_avg'))
                ->whereIn('exercise_id', $ids)
                ->groupBy('exercise_id')
                ->get()
                ->keyBy('exercise_id');
        }

        $data = $rows->map(function (Exercise $e) use ($ratingAgg) {
            $agg = $ratingAgg->get($e->id);
            return [
                'id' => $e->id,
                'name' => $e->name,
                'type' => $e->type,
                'difficulty' => $e->difficulty,
                'met' => $e->met,
                'coeff' => $e->coeff,
                'rating_avg' => $agg ? (float) $agg->rating_avg : null,
                'rating_count' => $agg ? (int) $agg->rating_count : 0,
            ];
        })->values();

        return response()->json(['data' => $data]);
    }

    public function show(Exercise $exercise)
    {
        if (! $exercise->is_approved) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $agg = ExerciseRating::query()
            ->select(DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars_overall) as rating_avg'))
            ->where('exercise_id', $exercise->id)
            ->first();

        return response()->json([
            'data' => [
                'id' => $exercise->id,
                'name' => $exercise->name,
                'type' => $exercise->type,
                'difficulty' => $exercise->difficulty,
                'met' => $exercise->met,
                'coeff' => $exercise->coeff,
                'rating_avg' => $agg ? (float) $agg->rating_avg : null,
                'rating_count' => $agg ? (int) $agg->rating_count : 0,
            ],
        ]);
    }

    // User-submitted exercise; requires auth (route group).
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:180'],
            'type' => ['required', 'string', 'max:30'],
            'difficulty' => ['nullable', 'integer', 'min:1', 'max:5'],
            'met' => ['nullable', 'numeric', 'min:0', 'max:30'],
        ]);

        $exercise = Exercise::query()->create([
            'name' => trim($data['name']),
            'type' => strtolower((string) $data['type']),
            'difficulty' => (int) ($data['difficulty'] ?? 2),
            'met' => $data['met'] ?? null,
            'coeff' => 1.0,
            'is_approved' => false,
            'created_by' => $request->user()->id,
        ]);

        return response()->json(['data' => $exercise], 201);
    }

    public function rate(Request $request, Exercise $exercise)
    {
        if (! $exercise->is_approved) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'stars_overall' => ['required', 'integer', 'min:1', 'max:5'],
            'stars_muscle' => ['nullable', 'integer', 'min:1', 'max:5'],
            'stars_fat' => ['nullable', 'integer', 'min:1', 'max:5'],
            'stars_safety' => ['nullable', 'integer', 'min:1', 'max:5'],
        ]);

        $userId = $request->user()->id;

        ExerciseRating::query()->updateOrCreate(
            ['exercise_id' => $exercise->id, 'user_id' => $userId],
            [
                'stars_overall' => (int) $data['stars_overall'],
                'stars_muscle' => $data['stars_muscle'] ?? null,
                'stars_fat' => $data['stars_fat'] ?? null,
                'stars_safety' => $data['stars_safety'] ?? null,
            ],
        );

        return response()->json(['ok' => true]);
    }

    public function estimateCost(Request $request, Exercise $exercise, ExerciseCostService $svc)
    {
        if (! $exercise->is_approved) {
            return response()->json(['message' => 'Not found'], 404);
        }

        $data = $request->validate([
            'reps' => ['nullable', 'integer', 'min:0', 'max:2000'],
            'weight_kg' => ['nullable', 'numeric', 'min:0', 'max:1000'],
            'duration_sec' => ['nullable', 'integer', 'min:0', 'max:86400'],
            'distance_km' => ['nullable', 'numeric', 'min:0', 'max:1000'],
            'rpe' => ['nullable', 'integer', 'min:1', 'max:10'],
            'user_weight_kg' => ['nullable', 'numeric', 'min:30', 'max:300'],
        ]);

        $cost = $svc->estimate($exercise, $data);
        return response()->json(['data' => ['cost_points' => round($cost, 4)]]);
    }
}

