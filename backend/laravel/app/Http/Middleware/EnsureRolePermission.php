<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use App\Models\Role;

class EnsureRolePermission
{
    public function handle(Request $request, Closure $next, string $permission)
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $roleKey = (string) ($user->role ?? 'user');

        $role = null;
        $perms = [];
        if (Schema::hasTable('roles')) {
            $role = Role::query()->where('key', $roleKey)->first();
            $perms = is_array($role?->permissions) ? $role->permissions : [];
        }

        $has = ($perms[$permission] ?? false) === true;

        if (! $role) {
            $has = $this->fallbackHasPermission($roleKey, $permission);
        }

        if (! $has) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        return $next($request);
    }

    private function fallbackHasPermission(string $roleKey, string $permission): bool
    {
        return match ($permission) {
            'users_manage', 'posts_manage' => in_array($roleKey, ['admin', 'staff'], true),
            'roles_manage' => $roleKey === 'admin',
            default => false,
        };
    }
}
