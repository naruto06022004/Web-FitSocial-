<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Post;

class PostController extends Controller
{
    public function index(Request $request)
    {
        $posts = Post::query()
            ->latest()
            ->limit(100)
            ->get(['id', 'user_id', 'title', 'content', 'created_at', 'updated_at']);

        return response()->json(['data' => $posts]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:120'],
            'content' => ['nullable', 'string', 'max:5000'],
        ]);

        $post = Post::query()->create([
            'user_id' => $request->user()->id,
            'title' => $data['title'],
            'content' => $data['content'] ?? null,
        ]);

        return response()->json(['data' => $post], 201);
    }

    public function show(Post $post)
    {
        return response()->json(['data' => $post]);
    }

    public function update(Request $request, Post $post)
    {
        if ($request->user()->role !== 'admin'
            && $request->user()->role !== 'staff'
            && $post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $data = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:120'],
            'content' => ['nullable', 'string', 'max:5000'],
        ]);

        $post->fill($data);
        $post->save();

        return response()->json(['data' => $post]);
    }

    public function destroy(Request $request, Post $post)
    {
        if ($request->user()->role !== 'admin'
            && $request->user()->role !== 'staff'
            && $post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Forbidden'], 403);
        }

        $post->delete();
        return response()->json(['ok' => true]);
    }
}

