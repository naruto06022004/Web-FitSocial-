<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user || ($user->role !== 'admin' && $user->role !== 'staff')) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        return $next($request);
    }
}

