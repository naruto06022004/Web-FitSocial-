<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Role;
use Illuminate\Http\Request;

class AdminRoleController extends Controller
{
    public function index()
    {
        $roles = Role::query()->orderBy('key')->get();
        return response()->json(['data' => $roles]);
    }

    public function store(Request $request)
    {
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

        // Prevent deleting role that is still in use
        $inUse = \App\Models\User::query()->where('role', $role->key)->exists();
        if ($inUse) {
            return response()->json(['message' => 'Role is in use by users'], 422);
        }

        $role->delete();
        return response()->json(['ok' => true]);
    }
}

