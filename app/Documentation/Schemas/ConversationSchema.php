<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *     schema="Conversation",
 *     required={"user1_id", "user2_id"},
 *     @OA\Property(property="id", type="integer", example=1, description="ID de la conversación"),
 *     @OA\Property(property="user1_id", type="integer", example=1, description="ID del primer usuario"),
 *     @OA\Property(property="user2_id", type="integer", example=2, description="ID del segundo usuario"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:00:00.000000Z", description="Fecha de creación"),
 *     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-11-21T18:00:00.000000Z", description="Fecha de última actualización"),
 *     @OA\Property(
 *         property="other_user",
 *         type="object",
 *         description="Datos del otro usuario en la conversación",
 *         @OA\Property(property="id", type="integer", example=2),
 *         @OA\Property(property="name", type="string", example="María Gómez")
 *     ),
 *     @OA\Property(
 *         property="last_message",
 *         type="object",
 *         description="Último mensaje de la conversación",
 *         @OA\Property(property="id", type="integer", example=5),
 *         @OA\Property(property="message", type="string", example="Hola, ¿cómo estás?"),
 *         @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:01:00.000000Z"),
 *         @OA\Property(property="is_read", type="boolean", example=true)
 *     ),
 *     @OA\Property(property="unread_count", type="integer", example=1, description="Número de mensajes no leídos")
 * )
 */
class ConversationSchema {}
