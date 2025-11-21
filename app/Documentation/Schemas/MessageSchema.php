<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *     schema="Message",
 *     required={"conversation_id", "sender_id", "message"},
 *     @OA\Property(property="id", type="integer", example=1, description="ID del mensaje"),
 *     @OA\Property(property="conversation_id", type="integer", example=1, description="ID de la conversación"),
 *     @OA\Property(property="sender_id", type="integer", example=1, description="ID del usuario que envió el mensaje"),
 *     @OA\Property(property="message", type="string", example="Hola, ¿cómo estás?", description="Contenido del mensaje"),
 *     @OA\Property(property="is_read", type="boolean", example=false, description="Indica si el mensaje ha sido leído"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-11-21T18:01:00.000000Z", description="Fecha de creación del mensaje"),
 *     @OA\Property(
 *         property="sender",
 *         type="object",
 *         description="Datos del usuario que envió el mensaje",
 *         @OA\Property(property="id", type="integer", example=1, description="ID del usuario"),
 *         @OA\Property(property="name", type="string", example="Juan Pérez", description="Nombre del usuario")
 *     )
 * )
 */
class MessageSchema {}


