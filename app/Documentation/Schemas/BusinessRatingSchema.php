<?php
namespace App\Documentation\Schemas;  

/**
 * @OA\Schema(
 *     schema="BusinessRating",
 *     required={"id", "business_id", "user_id", "service_quality", "created_at", "updated_at"},
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="business_id", type="integer", example=1),
 *     @OA\Property(property="user_id", type="integer", example=1),
 *     @OA\Property(property="service_quality", type="integer", description="Calificación (1-5)", example=5),
 *     @OA\Property(property="comment", type="string", description="Comentario opcional", example="Excelente servicio"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z"),
 *     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z"),
 *     @OA\Property(property="user", type="object", ref="#/components/schemas/User")
 * )
 */
class BusinessRatingSchema {}