<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
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
        $isSystemStaff = in_array($roleKey, ['admin', 'staff'], true);

        $role = null;
        $perms = [];
        if (Schema::hasTable('roles')) {
            $role = Role::query()->where('key', $roleKey)->first();
            $perms = is_array($role?->permissions) ? $role->permissions : [];
        }

        // admin/staff luôn vào được admin API; role tùy chỉnh cần admin_access trên bản ghi roles.
        $has = $isSystemStaff || (($perms['admin_access'] ?? false) === true);

        if (! $role) {
            $has = $isSystemStaff;
        }

        if (! $has) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return $next($request);
    }
}

