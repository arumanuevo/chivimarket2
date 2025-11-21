<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Pusher\Pusher;

class MessageController extends Controller
{
    protected $pusher;

    public function __construct()
    {
        $this->pusher = new Pusher(
            config('broadcasting.connections.pusher.key'),
            config('broadcasting.connections.pusher.secret'),
            config('broadcasting.connections.pusher.app_id'),
            [
                'cluster' => config('broadcasting.connections.pusher.options.cluster'),
                'useTLS' => true
            ]
        );
    }

    // Iniciar una conversación
    public function startConversation(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:users,id|different:' . Auth::id()
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Error de validación', 'errors' => $validator->errors()], 400);
        }

        $user1 = Auth::id();
        $user2 = $request->user_id;

        $conversation = Conversation::where(function($query) use ($user1, $user2) {
            $query->where('user1_id', $user1)->where('user2_id', $user2);
        })->orWhere(function($query) use ($user1, $user2) {
            $query->where('user1_id', $user2)->where('user2_id', $user1);
        })->first();

        if (!$conversation) {
            $conversation = Conversation::create([
                'user1_id' => $user1,
                'user2_id' => $user2
            ]);
        }

        return response()->json([
            'message' => 'Conversación iniciada',
            'conversation' => $conversation
        ]);
    }

    // Enviar un mensaje
    public function sendMessage(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'conversation_id' => 'required|integer|exists:conversations,id',
            'message' => 'required|string|max:1000'
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Error de validación', 'errors' => $validator->errors()], 400);
        }

        $conversation = Conversation::find($request->conversation_id);
        if (!in_array(Auth::id(), [$conversation->user1_id, $conversation->user2_id])) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => Auth::id(),
            'message' => $request->message
        ]);

        // Obtener el otro usuario en la conversación
        $otherUserId = $conversation->user1_id == Auth::id() ? $conversation->user2_id : $conversation->user1_id;

        // Enviar notificación en tiempo real con Pusher
        $this->pusher->trigger(
            "user-{$otherUserId}",
            'message-received',
            [
                'conversation_id' => $conversation->id,
                'message_id' => $message->id,
                'sender_id' => Auth::id(),
                'message' => $message->message,
                'created_at' => $message->created_at->toDateTimeString(),
                'sender_name' => Auth::user()->name
            ]
        );

        return response()->json([
            'message' => 'Mensaje enviado exitosamente',
            'data' => $message
        ], 201);
    }

    // Listar mensajes de una conversación
    public function listMessages(Conversation $conversation)
    {
        if (!in_array(Auth::id(), [$conversation->user1_id, $conversation->user2_id])) {
            return response()->json(['message' => 'No autorizado'], 403);
        }

        // Marcar mensajes como leídos
        Message::where('conversation_id', $conversation->id)
            ->where('sender_id', '!=', Auth::id())
            ->where('is_read', false)
            ->update(['is_read' => true]);

        $messages = Message::where('conversation_id', $conversation->id)
            ->with(['sender' => function($query) {
                $query->select('id', 'name');
            }])
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($messages);
    }

    // Listar conversaciones del usuario
    public function listConversations()
    {
        $userId = Auth::id();

        $conversations = Conversation::where('user1_id', $userId)
            ->orWhere('user2_id', $userId)
            ->with(['user1', 'user2'])
            ->withCount(['messages as unread_count' => function($query) use ($userId) {
                $query->where('sender_id', '!=', $userId)->where('is_read', false);
            }])
            ->with(['messages' => function($query) {
                $query->latest()->limit(1);
            }])
            ->get()
            ->map(function($conversation) use ($userId) {
                $otherUser = $conversation->user1_id == $userId ? $conversation->user2 : $conversation->user1;
                $lastMessage = $conversation->messages->first();

                return [
                    'id' => $conversation->id,
                    'other_user' => [
                        'id' => $otherUser->id,
                        'name' => $otherUser->name
                    ],
                    'last_message' => $lastMessage ? [
                        'id' => $lastMessage->id,
                        'message' => $lastMessage->message,
                        'created_at' => $lastMessage->created_at,
                        'is_read' => $lastMessage->is_read || $lastMessage->sender_id == $userId
                    ] : null,
                    'unread_count' => $conversation->unread_count
                ];
            });

        return response()->json($conversations);
    }
}

