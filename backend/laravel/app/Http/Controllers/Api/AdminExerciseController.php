<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\ExerciseRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminExerciseController extends Controller
{
    public function index(Request $request)
    {
        $q = Exercise::query();
        if ($request->filled('approved')) {
            $q->where('is_approved', filter_var($request->query('approved'), FILTER_VALIDATE_BOOL));
        }
        if ($request->filled('type')) {
            $q->where('type', strtolower((string) $request->query('type')));
        }
        if ($request->filled('search')) {
            $s = trim((string) $request->query('search'));
            $q->where('name', 'like', "%{$s}%");
        }

        $rows = $q->latest()->limit(300)->get(['id', 'name', 'type', 'difficulty', 'met', 'coeff', 'is_approved', 'created_by', 'created_at']);
        $ids = $rows->pluck('id')->all();

        $postsCountByExercise = collect();
        if (!empty($ids)) {
            // Mọi post gắn exercise_id (đồng bộ với feed sau chuẩn hoá kind).
            $postsCountByExercise = DB::table('posts')
                ->select('exercise_id', DB::raw('COUNT(*) as c'))
                ->whereNotNull('exercise_id')
                ->where('exercise_id', '>', 0)
                ->whereIn('exercise_id', $ids)
                ->groupBy('exercise_id')
                ->pluck('c', 'exercise_id');
        }

        $ratingAgg = collect();
        if (!empty($ids)) {
            $ratingAgg = ExerciseRating::query()
                ->select('exercise_id', DB::raw('COUNT(*) as rating_count'), DB::raw('AVG(stars_overall) as rating_avg'))
                ->whereIn('exercise_id', $ids)
                ->groupBy('exercise_id')
                ->get()
                ->keyBy('exercise_id');
        }

        $data = $rows->map(function (Exercise $e) use ($ratingAgg, $postsCountByExercise) {
            $agg = $ratingAgg->get($e->id);
            return [
                'id' => $e->id,
                'name' => $e->name,
                'type' => $e->type,
                'difficulty' => $e->difficulty,
                'met' => $e->met,
                'coeff' => $e->coeff,
                'is_approved' => (bool) $e->is_approved,
                'created_by' => $e->created_by,
                'created_at' => $e->created_at,
                'rating_avg' => $agg ? (float) $agg->rating_avg : null,
                'rating_count' => $agg ? (int) $agg->rating_count : 0,
                'posts_count' => (int) ($postsCountByExercise[$e->id] ?? 0),
            ];
        })->values();

        return response()->json(['data' => $data]);
    }

    public function update(Request $request, Exercise $exercise)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:180'],
            'type' => ['sometimes', 'required', 'string', 'max:30'],
            'difficulty' => ['sometimes', 'required', 'integer', 'min:1', 'max:5'],
            'met' => ['nullable', 'numeric', 'min:0', 'max:30'],
            'coeff' => ['sometimes', 'required', 'numeric', 'min:0', 'max:1000'],
            'is_approved' => ['sometimes', 'required', 'boolean'],
        ]);

        if (array_key_exists('type', $data)) {
            $data['type'] = strtolower((string) $data['type']);
        }

        $exercise->fill($data);
        $exercise->save();

        return response()->json(['data' => $exercise]);
    }

    public function destroy(Exercise $exercise)
    {
        $exercise->delete();
        return response()->json(['ok' => true]);
    }
}

