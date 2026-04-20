<?php

namespace App\Services;

use App\Models\Exercise;

class ExerciseCostService
{
    /**
     * Cost points (effort proxy).
     *
     * Supported input keys:
     * - reps (int)
     * - weight_kg (float)
     * - duration_sec (int)
     * - distance_km (float)
     * - rpe (int 1..10)
     * - user_weight_kg (float) optional (for MET calculations; defaults to 60)
     */
    public function estimate(Exercise $exercise, array $input): float
    {
        $type = strtolower((string) $exercise->type);
        $difficulty = max(1, min(5, (int) ($exercise->difficulty ?? 2)));
        $diffFactor = 0.85 + ($difficulty - 1) * 0.10; // 1->0.85, 5->1.25

        $rpe = isset($input['rpe']) ? (int) $input['rpe'] : null;
        $rpeFactor = 1.0;
        if ($rpe !== null) {
            $rpe = max(1, min(10, $rpe));
            $rpeFactor = 0.75 + ($rpe - 1) * (0.65 / 9.0); // ~0.75..1.40
        }

        return match ($type) {
            'cardio' => $this->cardioCost($exercise, $input) * $diffFactor,
            'hiit', 'bodyweight' => $this->hiitCost($exercise, $input) * $diffFactor * $rpeFactor,
            default => $this->strengthCost($exercise, $input) * $diffFactor * $rpeFactor,
        };
    }

    private function strengthCost(Exercise $exercise, array $input): float
    {
        $reps = isset($input['reps']) ? max(0, (int) $input['reps']) : 0;
        $weight = isset($input['weight_kg']) ? max(0.0, (float) $input['weight_kg']) : 0.0;
        $coeff = max(0.0, (float) ($exercise->coeff ?? 1.0));

        // Volume proxy: reps * weight, normalized to "points"
        $raw = ($reps * $weight) / 100.0;
        return $raw * max(0.2, $coeff);
    }

    private function cardioCost(Exercise $exercise, array $input): float
    {
        $durationSec = isset($input['duration_sec']) ? max(0, (int) $input['duration_sec']) : 0;
        $mins = $durationSec / 60.0;
        $met = (float) ($exercise->met ?? 6.0);
        $weightKg = isset($input['user_weight_kg']) ? max(30.0, (float) $input['user_weight_kg']) : 60.0;

        // kcal estimate: minutes * MET * weight(kg) * 0.0175
        $kcal = $mins * $met * $weightKg * 0.0175;
        // Convert to points (10 kcal ≈ 1 point)
        return $kcal / 10.0;
    }

    private function hiitCost(Exercise $exercise, array $input): float
    {
        $durationSec = isset($input['duration_sec']) ? max(0, (int) $input['duration_sec']) : 0;
        $mins = $durationSec / 60.0;
        $met = (float) ($exercise->met ?? 8.0);
        $weightKg = isset($input['user_weight_kg']) ? max(30.0, (float) $input['user_weight_kg']) : 60.0;
        $kcal = $mins * $met * $weightKg * 0.0175;
        return $kcal / 10.0;
    }
}

