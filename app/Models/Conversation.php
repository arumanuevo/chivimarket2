<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * @OA\Schema(
 *     schema="Conversation",
 *     required={"user1_id", "user2_id"},
 *     @OA\Property(property="id", type="integer", example=1, description="ID de la conversación"),
 *     @OA\Property(property="user1_id", type="integer", example=1, description="ID del primer usuario"),
 *     @OA\Property(property="user2_id", type="integer", example=2, description="ID del segundo usuario"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:00:00.000000Z", description="Fecha de creación"),
 *     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-21T18:00:00.000000Z", description="Fecha de última actualización")
 * )
 */
class Conversation extends Model
{
    protected $fillable = ['user1_id', 'user2_id'];

    public function user1(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user1_id');
    }

    public function user2(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user2_id');
    }

    public function messages(): HasMany
    {
        return $this->hasMany(Message::class);
    }

    public function getOtherUser(User $user): User
    {
        return $this->user1_id === $user->id ? $this->user2 : $this->user1;
    }
}

