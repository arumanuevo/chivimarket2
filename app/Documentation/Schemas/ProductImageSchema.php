<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *   schema="ProductImage",
 *   required={"id", "product_id", "url"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="product_id", type="integer", example=5),
 *   @OA\Property(property="url", type="string", example="https://cdn.example.com/images/pan.jpg"),
 *   @OA\Property(property="is_primary", type="boolean", example=true),
 *   @OA\Property(property="description", type="string", nullable=true, example="Imagen principal del pan integral"),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-20T13:50:00Z")
 * )
 */
class ProductImageSchema {}
