<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gym;

class GymController extends Controller
{
    public function index()
    {
        $gyms = Gym::query()
            ->orderBy('name')
            ->limit(200)
            ->get(['id', 'name', 'address', 'latitude', 'longitude', 'created_at']);

        return response()->json(['data' => $gyms]);
    }
}
