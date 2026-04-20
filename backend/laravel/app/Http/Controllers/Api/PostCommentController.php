<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Post;
use App\Models\PostComment;
use Illuminate\Http\Request;

class PostCommentController extends Controller
{
    public function index(Post $post)
    {
        if (! $post->isExercisePost()) {
            return response()->json(['message' => 'Comments only available for exercise posts'], 422);
        }

        $rows = PostComment::query()
            ->where('post_id', $post->id)
            ->latest()
            ->limit(200)
            ->get(['id', 'post_id', 'user_id', 'body', 'created_at']);

        return response()->json(['data' => $rows]);
    }

    public function store(Request $request, Post $post)
    {
        if (! $post->isExercisePost()) {
            return response()->json(['message' => 'Comments only available for exercise posts'], 422);
        }

        $data = $request->validate([
            'body' => ['required', 'string', 'max:2000'],
        ]);

        $row = PostComment::query()->create([
            'post_id' => $post->id,
            'user_id' => $request->user()->id,
            'body' => trim($data['body']),
        ]);

        return response()->json(['data' => $row], 201);
    }
}

