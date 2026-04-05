<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use App\Models\User;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
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

        $token = $user->createToken('fitnet')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
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
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
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
                'id' => $u->id,
                'name' => $u->name,
                'email' => $u->email,
                'role' => $u->role,
            ],
        ]);
    }
}

