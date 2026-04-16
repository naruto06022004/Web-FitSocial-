<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ChatMessage;
use App\Models\User;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function conversations(Request $request)
    {
        $me = $request->user()->id;

        $peerIds = ChatMessage::query()
            ->where(function ($q) use ($me) {
                $q->where('sender_id', $me)->orWhere('recipient_id', $me);
            })
            ->get(['sender_id', 'recipient_id'])
            ->flatMap(static fn ($m) => [$m->sender_id, $m->recipient_id])
            ->filter(static fn ($id) => (int) $id !== $me)
            ->unique()
            ->values();

        $data = $peerIds->map(function (int $peerId) use ($me) {
            $peer = User::query()->find($peerId, ['id', 'name', 'email', 'role']);
            if ($peer === null) {
                return null;
            }
            $last = ChatMessage::query()
                ->betweenUsers($me, $peerId)
                ->latest('id')
                ->first(['id', 'sender_id', 'recipient_id', 'body', 'read_at', 'created_at']);

            $unread = ChatMessage::query()
                ->where('sender_id', $peerId)
                ->where('recipient_id', $me)
                ->whereNull('read_at')
                ->count();

            return [
                'peer' => $peer,
                'last_message' => $last,
                'unread_count' => $unread,
            ];
        })->filter()->values();

        return response()->json(['data' => $data]);
    }

    public function directory(Request $request)
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
            ->get(['id', 'name', 'email', 'role']);

        return response()->json(['data' => $users]);
    }

    public function messages(Request $request)
    {
        $data = $request->validate([
            'with_user_id' => ['required', 'integer', 'exists:users,id'],
            'mark_seen' => ['sometimes', 'boolean'],
            'page' => ['sometimes', 'integer', 'min:1'],
        ]);

        $me = $request->user()->id;
        $with = (int) $data['with_user_id'];
        if ($with === $me) {
            return response()->json(['message' => 'Không thể xem hội thoại với chính mình.'], 422);
        }

        if ($request->boolean('mark_seen')) {
            ChatMessage::query()
                ->where('sender_id', $with)
                ->where('recipient_id', $me)
                ->whereNull('read_at')
                ->update(['read_at' => now()]);
        }

        $messages = ChatMessage::query()
            ->betweenUsers($me, $with)
            ->with([
                'sender' => static fn ($q) => $q->select('id', 'name'),
                'recipient' => static fn ($q) => $q->select('id', 'name'),
            ])
            ->latest('id')
            ->paginate(50);

        return response()->json([
            'data' => $messages->items(),
            'meta' => [
                'current_page' => $messages->currentPage(),
                'last_page' => $messages->lastPage(),
                'per_page' => $messages->perPage(),
                'total' => $messages->total(),
            ],
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'recipient_id' => ['required', 'integer', 'exists:users,id'],
            'body' => ['required', 'string', 'max:5000'],
        ]);

        $me = $request->user()->id;
        $recipient = (int) $data['recipient_id'];
        if ($recipient === $me) {
            return response()->json(['message' => 'Không thể gửi tin cho chính mình.'], 422);
        }

        $msg = ChatMessage::query()->create([
            'sender_id' => $me,
            'recipient_id' => $recipient,
            'body' => $data['body'],
        ]);

        $msg->load([
            'sender' => static fn ($q) => $q->select('id', 'name'),
            'recipient' => static fn ($q) => $q->select('id', 'name'),
        ]);

        return response()->json(['data' => $msg], 201);
    }

    public function markSeen(Request $request, User $user)
    {
        $me = $request->user()->id;
        if ($user->id === $me) {
            return response()->json(['message' => 'Không hợp lệ.'], 422);
        }

        $updated = ChatMessage::query()
            ->where('sender_id', $user->id)
            ->where('recipient_id', $me)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['ok' => true, 'marked_count' => $updated]);
    }
}
