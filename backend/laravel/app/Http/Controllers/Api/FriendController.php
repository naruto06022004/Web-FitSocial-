<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class FriendController extends Controller
{
    /**
     * Danh sách gợi ý bạn bè / người dùng khác (tìm kiếm).
     */
    public function index(Request $request)
    {
        $me = $request->user()->id;
        $q = trim((string) $request->query('q', ''));

        $users = User::query()
            ->where('id', '!=', $me)
            ->when($q !== '', function ($query) use ($q) {
                $query->where(function ($query) use ($q) {
                    $query->where('name', 'like', '%'.$q.'%')
                        ->orWhere('email', 'like', '%'.$q.'%');
                });
            })
            ->orderBy('name')
            ->limit(100)
            ->get(['id', 'name', 'email', 'role', 'gym_name']);

        return response()->json(['data' => $users]);
    }
}
