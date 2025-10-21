<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *   schema="ProductCategory",
 *   required={"id", "name"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="name", type="string", example="Panadería"),
 *   @OA\Property(property="description", type="string", nullable=true, example="Productos de panadería y repostería"),
 *   @OA\Property(property="parent_id", type="integer", nullable=true, example=2),
 *   @OA\Property(property="is_active", type="boolean", example=true),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-20T13:50:00Z"),
 *   @OA\Property(
 *     property="children",
 *     type="array",
 *     @OA\Items(ref="#/components/schemas/ProductCategory")
 *   )
 * )
 */
class ProductCategorySchema {}