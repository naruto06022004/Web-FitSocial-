<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exercise;
use App\Models\WorkoutLog;
use App\Services\ExerciseCostService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

class WorkoutLogController extends Controller
{
    public function store(Request $request, ExerciseCostService $svc)
    {
        $data = $request->validate([
            'exercise_id' => ['required', 'integer', 'exists:exercises,id'],
            'reps' => ['nullable', 'integer', 'min:0', 'max:2000'],
            'weight_kg' => ['nullable', 'numeric', 'min:0', 'max:1000'],
            'duration_sec' => ['nullable', 'integer', 'min:0', 'max:86400'],
            'distance_km' => ['nullable', 'numeric', 'min:0', 'max:1000'],
            'rpe' => ['nullable', 'integer', 'min:1', 'max:10'],
            'performed_at' => ['nullable', 'date'],
        ]);

        /** @var Exercise $exercise */
        $exercise = Exercise::query()->findOrFail((int) $data['exercise_id']);
        if (! $exercise->is_approved) {
            return response()->json(['message' => 'Exercise not available'], 422);
        }

        $performedAt = isset($data['performed_at'])
            ? Carbon::parse((string) $data['performed_at'])
            : now();

        $cost = $svc->estimate($exercise, $data);

        $log = WorkoutLog::query()->create([
            'user_id' => $request->user()->id,
            'exercise_id' => $exercise->id,
            'reps' => $data['reps'] ?? null,
            'weight_kg' => $data['weight_kg'] ?? null,
            'duration_sec' => $data['duration_sec'] ?? null,
            'distance_km' => $data['distance_km'] ?? null,
            'rpe' => $data['rpe'] ?? null,
            'cost_points' => round($cost, 4),
            'performed_at' => $performedAt,
        ]);

        return response()->json(['data' => $log], 201);
    }

    public function leaderboard(Request $request)
    {
        $data = $request->validate([
            'period' => ['nullable', 'string', 'in:day,week,month'],
        ]);

        $period = $data['period'] ?? 'week';
        $start = match ($period) {
            'day' => now()->startOfDay(),
            'month' => now()->startOfMonth(),
            default => now()->startOfWeek(),
        };

        $rows = WorkoutLog::query()
            ->select('user_id', DB::raw('SUM(cost_points) as total_cost'), DB::raw('COUNT(*) as logs'))
            ->where('performed_at', '>=', $start)
            ->groupBy('user_id')
            ->orderByDesc('total_cost')
            ->limit(50)
            ->get();

        // Fetch user display info in one go
        $userIds = $rows->pluck('user_id')->all();
        $users = DB::table('users')
            ->whereIn('id', $userIds)
            ->get(['id', 'name', 'email'])
            ->keyBy('id');

        $ranked = $rows->values()->map(function ($r, $idx) use ($users) {
            $u = $users->get($r->user_id);
            return [
                'rank' => $idx + 1,
                'user_id' => (int) $r->user_id,
                'name' => $u?->name ?? 'Unknown',
                'total_cost' => round((float) $r->total_cost, 4),
                'logs' => (int) $r->logs,
            ];
        });

        return response()->json([
            'data' => $ranked,
            'meta' => [
                'period' => $period,
                'start_at' => $start->toIso8601String(),
            ],
        ]);
    }
}

