<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use App\Models\User;
use App\Models\Role;

class AuthController extends Controller
{
    private function userPayload(User $u): array
    {
        $roleKey = (string) ($u->role ?? 'user');
        $role = null;
        try {
            $role = Role::query()->where('key', $roleKey)->first();
        } catch (\Throwable) {
            // If roles table is missing (dev/test), still allow login/me to work.
            $role = null;
        }

        return [
            'id' => $u->id,
            'name' => $u->name,
            'email' => $u->email,
            'role' => $u->role,
            'role_label' => $role?->label,
            'permissions' => is_array($role?->permissions) ? $role->permissions : null,
            'bio' => $u->bio,
            'gym_name' => $u->gym_name,
            'avatar_url' => $u->avatar_url,
        ];
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            // Frontend gửi trường 'email', nhưng cho phép nhập cả email hoặc username.
            'email' => ['required', 'string', 'min:3'],
            'password' => ['required', 'string'],
        ]);

        $identifier = $data['email'];

        /** @var User|null $user */
        $user = User::query()
            ->where('email', $identifier)
            ->orWhere('name', $identifier)
            ->first();
        if (!$user || !Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Tài khoản hoặc mật khẩu không đúng.'],
            ]);
        }

        $roleKey = trim((string) ($user->role ?? ''));
        if ($roleKey === '') {
            $user->role = 'user';
            $user->save();
        } else {
            $knownSystem = in_array($roleKey, ['admin', 'staff'], true);
            try {
                $exists = Role::query()->where('key', $roleKey)->exists();
                if (! $knownSystem && ! $exists) {
                    $user->role = 'user';
                    $user->save();
                }
            } catch (\Throwable) {
                // If roles table is missing, don't block login.
            }
        }

        $token = $user->createToken('fitnet')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userPayload($user),
        ]);
    }

    public function register(Request $request)
    {
        $data = $request->validate([
            'email' => [
                'required',
                'email',
                'max:190',
                'unique:users,email',
                'regex:/^[^@]+@gmail\.com$/i',
            ],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $username = explode('@', $data['email'], 2)[0];
        $user = User::query()->create([
            'name' => $username,
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'role' => 'user',
        ]);

        $token = $user->createToken('fitnet')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $this->userPayload($user),
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()?->currentAccessToken()?->delete();
        return response()->json(['ok' => true]);
    }

    public function me(Request $request)
    {
        $u = $request->user();
        return response()->json([
            'data' => [
                ...$this->userPayload($u),
            ],
        ]);
    }

    public function updateMe(Request $request)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'bio' => ['nullable', 'string', 'max:2000'],
            'gym_name' => ['nullable', 'string', 'max:120'],
            'avatar_url' => ['nullable', 'string', 'max:500'],
        ]);

        $u = $request->user();
        if (isset($data['name'])) {
            $u->name = $data['name'];
        }
        if (array_key_exists('bio', $data)) {
            $u->bio = $data['bio'];
        }
        if (array_key_exists('gym_name', $data)) {
            $g = trim((string) $data['gym_name']);
            $u->gym_name = $g === '' ? null : $g;
        }
        if (array_key_exists('avatar_url', $data) && Schema::hasColumn('users', 'avatar_url')) {
            $a = trim((string) $data['avatar_url']);
            $u->avatar_url = $a === '' ? null : $a;
        }
        $u->save();

        return response()->json([
            'data' => [
                ...$this->userPayload($u),
            ],
        ]);
    }
}

