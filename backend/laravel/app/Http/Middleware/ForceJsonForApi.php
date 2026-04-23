<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class ForceJsonForApi
{
    public function handle(Request $request, Closure $next)
    {
        // Ensure API routes always negotiate JSON responses (avoid web redirects like Route [login] not defined).
        if ($request->is('api/*') && ! $request->expectsJson()) {
            $request->headers->set('Accept', 'application/json');
        }

        return $next($request);
    }
}

