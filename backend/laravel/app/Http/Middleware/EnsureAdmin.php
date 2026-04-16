<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\Role;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $roleKey = (string) ($user->role ?? 'user');
        $role = Role::query()->where('key', $roleKey)->first();
        $perms = is_array($role?->permissions) ? $role->permissions : [];
        $has = ($perms['admin_access'] ?? false) === true;

        // Backward-compatible fallback (if roles table not migrated/seeded yet).
        if (!$role) {
            $has = $roleKey === 'admin' || $roleKey === 'staff';
        }

        if (!$has) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return $next($request);
    }
}

