<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class TrainingSpaceController extends Controller
{
    /**
     * Người cùng “phòng” / cùng gym (theo gym_name trùng nhau).
     */
    public function peers(Request $request)
    {
        $me = $request->user();
        $gym = $me->gym_name;

        if ($gym === null || trim($gym) === '') {
            return response()->json([
                'data' => [],
                'meta' => ['hint' => 'Cập nhật gym_name trong hồ sơ để xem người cùng phòng.'],
            ]);
        }

        $peers = User::query()
            ->where('id', '!=', $me->id)
            ->where('gym_name', $gym)
            ->orderBy('name')
            ->limit(200)
            ->get(['id', 'name', 'email', 'role', 'gym_name']);

        return response()->json(['data' => $peers]);
    }
}
