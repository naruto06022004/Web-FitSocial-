<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class AdminRoleController extends Controller
{
    public function index()
    {
        if (! Schema::hasTable('roles')) {
            return response()->json([
                'data' => [],
                'meta' => [
                    'schema_incomplete' => true,
                    'hint' => 'Run migrations: php artisan migrate (from backend/laravel)',
                ],
            ]);
        }

        $roles = Role::query()->orderBy('key')->get();
        return response()->json(['data' => $roles]);
    }

    public function store(Request $request)
    {
        if (! Schema::hasTable('roles')) {
            return response()->json([
                'message' => 'Database schema incomplete: roles table missing. Run: php artisan migrate',
            ], 503);
        }

        $data = $request->validate([
            'key' => ['required', 'string', 'max:40', 'regex:/^[a-z0-9_]+$/i', 'unique:roles,key'],
            'label' => ['required', 'string', 'max:80'],
            'permissions' => ['nullable', 'array'],
        ]);

        $role = Role::query()->create([
            'key' => strtolower($data['key']),
            'label' => $data['label'],
            'permissions' => $data['permissions'] ?? [],
        ]);

        return response()->json(['data' => $role], 201);
    }

    public function update(Request $request, Role $role)
    {
        $data = $request->validate([
            'label' => ['sometimes', 'required', 'string', 'max:80'],
            'permissions' => ['sometimes', 'nullable', 'array'],
        ]);

        $role->fill($data);
        $role->save();
        return response()->json(['data' => $role]);
    }

    public function destroy(Role $role)
    {
        if (in_array($role->key, ['admin', 'staff', 'user'], true)) {
            return response()->json(['message' => 'Cannot delete system role'], 422);
        }

        $fallback = 'user';
        $reassigned = 0;

        DB::transaction(function () use ($role, $fallback, &$reassigned): void {
            $reassigned = User::query()->where('role', $role->key)->update(['role' => $fallback]);
            $role->delete();
        });

        return response()->json([
            'ok' => true,
            'reassigned_users' => $reassigned,
            'fallback_role' => $fallback,
        ]);
    }
}

