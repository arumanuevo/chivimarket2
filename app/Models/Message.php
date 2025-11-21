<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @OA\Schema(
 *     schema="Message",
 *     required={"conversation_id", "sender_id", "message"},
 *     @OA\Property(property="id", type="integer", example=1, description="ID del mensaje"),
 *     @OA\Property(property="conversation_id", type="integer", example=1, description="ID de la conversación"),
 *     @OA\Property(property="sender_id", type="integer", example=1, description="ID del usuario que envió el mensaje"),
 *     @OA\Property(property="message", type="string", example="Hola, ¿cómo estás?", description="Contenido del mensaje"),
 *     @OA\Property(property="is_read", type="boolean, example=false, description="Si el mensaje ha sido leído"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:01:00.000000Z", description="Fecha de creación")
 * )
 */
class Message extends Model
{
    protected $fillable = ['conversation_id', 'sender_id', 'message', 'is_read'];

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(Conversation::class);
    }

    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}

