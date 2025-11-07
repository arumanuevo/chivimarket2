<?php
namespace App\Documentation\Schemas;
/**
 * @OA\Schema(
 *     schema="ProductRating",
 *     required={"id", "product_id", "user_id", "quality", "created_at", "updated_at"},
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="product_id", type="integer", example=1),
 *     @OA\Property(property="user_id", type="integer", example=1),
 *     @OA\Property(property="quality", type="integer", description="Calificación (1-5)", example=4),
 *     @OA\Property(property="comment", type="string", description="Comentario opcional", example="Producto de buena calidad"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z"),
 *     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z"),
 *     @OA\Property(property="user", type="object", ref="#/components/schemas/User")
 * )
 */
class ProductRatingSchema {}