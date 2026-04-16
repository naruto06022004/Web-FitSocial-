<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use App\Models\User;
use App\Models\Role;

class AdminUserController extends Controller
{
    private function userSelectColumns(): array
    {
        $cols = ['id', 'name', 'email', 'role', 'created_at', 'updated_at'];

        // Optional columns that may not exist if migrations not run yet.
        foreach (['bio', 'gym_name', 'avatar_url'] as $c) {
            if (Schema::hasColumn('users', $c)) {
                $cols[] = $c;
            }
        }

        return $cols;
    }

    public function index()
    {
        $users = User::query()
            ->latest()
            ->limit(200)
            ->get($this->userSelectColumns());

        return response()->json(['data' => $users]);
    }

    public function show(User $user)
    {
        $data = $user->only($this->userSelectColumns());
        return response()->json([
            'data' => $data,
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'role' => ['required', 'string', 'max:40'],
            'bio' => ['nullable', 'string', 'max:2000'],
            'gym_name' => ['nullable', 'string', 'max:120'],
            'avatar_url' => ['nullable', 'string', 'max:500'],
        ]);

        $roleKey = strtolower((string) $data['role']);
        $roleExists = Role::query()->where('key', $roleKey)->exists();
        if (!$roleExists) {
            return response()->json(['message' => 'Invalid role'], 422);
        }

        $create = [
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => $roleKey,
        ];

        if (Schema::hasColumn('users', 'bio')) {
            $create['bio'] = $data['bio'] ?? null;
        }
        if (Schema::hasColumn('users', 'gym_name')) {
            $create['gym_name'] = $data['gym_name'] ?? null;
        }
        if (Schema::hasColumn('users', 'avatar_url')) {
            $create['avatar_url'] = $data['avatar_url'] ?? null;
        }

        $user = User::query()->create($create);

        return response()->json(['data' => $user], 201);
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:120'],
            'email' => ['sometimes', 'required', 'email', 'max:190', 'unique:users,email,' . $user->id],
            'password' => ['sometimes', 'required', 'string', 'min:8'],
            'role' => ['sometimes', 'required', 'string', 'max:40'],
            'bio' => ['sometimes', 'nullable', 'string', 'max:2000'],
            'gym_name' => ['sometimes', 'nullable', 'string', 'max:120'],
            'avatar_url' => ['sometimes', 'nullable', 'string', 'max:500'],
        ]);

        if (array_key_exists('password', $data)) {
            $data['password'] = Hash::make($data['password']);
        }

        // Don't set columns that don't exist yet (if migrations not run).
        foreach (['bio', 'gym_name', 'avatar_url'] as $c) {
            if (array_key_exists($c, $data) && !Schema::hasColumn('users', $c)) {
                unset($data[$c]);
            }
        }

        if (array_key_exists('role', $data)) {
            $roleKey = strtolower((string) $data['role']);
            $roleExists = Role::query()->where('key', $roleKey)->exists();
            if (!$roleExists) {
                return response()->json(['message' => 'Invalid role'], 422);
            }
            $data['role'] = $roleKey;
        }

        $user->fill($data);
        $user->save();

        return response()->json(['data' => $user]);
    }

    public function destroy(User $user)
    {
        $user->delete();
        return response()->json(['ok' => true]);
    }
}

