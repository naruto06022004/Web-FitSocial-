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

    private function resolveRoleLabel(string $roleKey): string
    {
        $roleKey = strtolower($roleKey);

        if (Schema::hasTable('roles')) {
            $role = Role::query()->where('key', $roleKey)->first();
            if ($role && is_string($role->label) && $role->label !== '') {
                return $role->label;
            }
        }

        return match ($roleKey) {
            'admin' => 'Admin',
            'staff' => 'Teacher',
            'user' => 'Student',
            default => $roleKey,
        };
    }

    /**
     * @return list<array{key: string, label: string}>
     */
    private function roleOptionsForMeta(): array
    {
        if (! Schema::hasTable('roles')) {
            return [];
        }

        return Role::query()
            ->orderBy('key')
            ->get(['key', 'label'])
            ->map(fn (Role $r) => [
                'key' => (string) $r->key,
                'label' => (string) $r->label,
            ])
            ->values()
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    private function userPayloadWithRoleLabel(User $user): array
    {
        $row = $user->only($this->userSelectColumns());
        $row['role_label'] = $this->resolveRoleLabel((string) ($user->role ?? 'user'));

        return $row;
    }

    public function index()
    {
        $users = User::query()
            ->latest()
            ->limit(200)
            ->get($this->userSelectColumns());

        $data = $users->map(fn (User $u) => $this->userPayloadWithRoleLabel($u))->values();

        return response()->json([
            'data' => $data,
            'meta' => [
                'role_options' => $this->roleOptionsForMeta(),
            ],
        ]);
    }

    public function show(User $user)
    {
        return response()->json([
            'data' => $this->userPayloadWithRoleLabel($user),
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

        return response()->json(['data' => $this->userPayloadWithRoleLabel($user)], 201);
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

        return response()->json(['data' => $this->userPayloadWithRoleLabel($user)]);
    }

    public function destroy(User $user)
    {
        $user->delete();
        return response()->json(['ok' => true]);
    }
}

