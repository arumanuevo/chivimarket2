<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Pusher\Pusher;

/**
 * @OA\Tag(
 *     name="Messaging",
 *     description="API para el sistema de mensajería entre usuarios"
 * )
 */
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

    /**
     * @OA\Post(
     *     path="/api/conversations/start",
     *     summary="Iniciar una conversación",
     *     description="Inicia una conversación con otro usuario o devuelve una existente",
     *     tags={"Messaging"},
     *     security={{"bearerAuth": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"user_id"},
     *             @OA\Property(property="user_id", type="integer", example=2, description="ID del otro usuario")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Conversación iniciada",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Conversación iniciada"),
     *             @OA\Property(property="conversation", ref="#/components/schemas/Conversation")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Error de validación"),
     *             @OA\Property(property="errors", type="object")
     *         )
     *     )
     * )
     */
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

    /**
     * @OA\Post(
     *     path="/api/messages",
     *     summary="Enviar un mensaje",
     *     description="Envía un mensaje a una conversación existente",
     *     tags={"Messaging"},
     *     security={{"bearerAuth": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"conversation_id", "message"},
     *             @OA\Property(property="conversation_id", type="integer", example=1, description="ID de la conversación"),
     *             @OA\Property(property="message", type="string", example="Hola, ¿cómo estás?", description="Contenido del mensaje")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Mensaje enviado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Mensaje enviado exitosamente"),
     *             @OA\Property(property="data", ref="#/components/schemas/Message")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Error de validación"),
     *             @OA\Property(property="errors", type="object")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     )
     * )
     */
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

        $otherUser = User::find($otherUserId);

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

         // Enviar notificación persistente (base de datos)
        try {
            $otherUser->notify(new NewMessageNotification($message));
        } catch (\Exception $e) {
            \Log::error("Error al enviar notificación: " . $e->getMessage());
            // El mensaje aún se guarda en la base de datos y se envía por Pusher
        } 

        return response()->json([
            'message' => 'Mensaje enviado exitosamente',
            'data' => $message
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/api/conversations/{conversation}/messages",
     *     summary="Listar mensajes de una conversación",
     *     description="Devuelve todos los mensajes de una conversación específica",
     *     tags={"Messaging"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="conversation",
     *         in="path",
     *         required=true,
     *         description="ID de la conversación",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de mensajes",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/Message"))
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     )
     * )
     */
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

/**
 * @OA\Get(
 *     path="/api/conversations",
 *     summary="Listar conversaciones del usuario",
 *     description="Devuelve todas las conversaciones del usuario autenticado",
 *     tags={"Messaging"},
 *     security={{"bearerAuth": {}}},
 *     @OA\Response(
 *         response=200,
 *         description="Lista de conversaciones",
 *         @OA\JsonContent(
 *             type="array",
 *             @OA\Items(
 *                 @OA\Property(property="id", type="integer", example=1),
 *                 @OA\Property(property="user1_id", type="integer", example=1),
 *                 @OA\Property(property="user2_id", type="integer", example=2),
 *                 @OA\Property(
 *                     property="other_user",
 *                     type="object",
 *                     @OA\Property(property="id", type="integer", example=2),
 *                     @OA\Property(property="name", type="string", example="María Gómez")
 *                 ),
 *                 @OA\Property(
 *                     property="last_message",
 *                     type="object",
 *                     @OA\Property(property="id", type="integer", example=5),
 *                     @OA\Property(property="message", type="string", example="Hola, ¿cómo estás?"),
 *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:01:00.000000Z"),
 *                     @OA\Property(property="is_read", type="boolean", example=true)
 *                 ),
 *                 @OA\Property(property="unread_count", type="integer", example=1)
 *             )
 *         )
 *     )
 * )
 */
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

/**
 * @OA\Get(
 *     path="/api/notifications",
 *     summary="Listar notificaciones del usuario",
 *     description="Devuelve las notificaciones no leídas del usuario autenticado",
 *     tags={"Messaging"},
 *     security={{"bearerAuth": {}}},
 *     @OA\Response(
 *         response=200,
 *         description="Lista de notificaciones",
 *         @OA\JsonContent(
 *             type="array",
 *             @OA\Items(
 *                 @OA\Property(property="id", type="string", example="uuid-notification-id"),
 *                 @OA\Property(property="type", type="string", example="App\Notifications\NewMessageNotification"),
 *                 @OA\Property(
 *                     property="data",
 *                     type="object",
 *                     @OA\Property(property="message_id", type="integer", example=1),
 *                     @OA\Property(property="conversation_id", type="integer", example=1),
 *                     @OA\Property(property="sender_id", type="integer", example=2),
 *                     @OA\Property(property="sender_name", type="string", example="Juan Pérez"),
 *                     @OA\Property(property="message", type="string", example="Hola, ¿cómo estás?"),
 *                     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:01:00.000000Z")
 *                 ),
 *                 @OA\Property(property="read_at", type="string", format="date-time", example=null)
 *             )
 *         )
 *     )
 * )
 */
    public function listNotifications()
    {
        $notifications = Auth::user()->unreadNotifications;

        return response()->json($notifications);
    }

    /**
 * @OA\Post(
 *     path="/api/notifications/{notification}/read",
 *     summary="Marcar notificación como leída",
 *     description="Marca una notificación como leída",
 *     tags={"Messaging"},
 *     security={{"bearerAuth": {}}},
 *     @OA\Parameter(
 *         name="notification",
 *         in="path",
 *         required=true,
 *         description="ID de la notificación",
 *         @OA\Schema(type="string")
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Notificación marcada como leída",
 *         @OA\JsonContent(
 *             @OA\Property(property="message", type="string", example="Notificación marcada como leída")
 *         )
 *     )
 * )
 */
    public function markAsRead($notificationId)
    {
        Auth::user()->notifications()->where('id', $notificationId)->first()->markAsRead();

        return response()->json(['message' => 'Notificación marcada como leída']);
    }

}

