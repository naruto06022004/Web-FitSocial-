<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Force JSON negotiation for API routes.
        $middleware->api(append: [
            \App\Http\Middleware\ForceJsonForApi::class,
        ]);

        // Route middleware aliases for API routes (Laravel 11/12 style).
        $middleware->alias([
            'ensure.admin' => \App\Http\Middleware\EnsureAdmin::class,
            'permission' => \App\Http\Middleware\EnsureRolePermission::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (\Illuminate\Auth\AuthenticationException $e, \Illuminate\Http\Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            throw $e;
        });
    })->create();
