<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *   schema="Business",
 *   required={"id", "user_id", "name"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="user_id", type="integer", example=10),
 *   @OA\Property(property="name", type="string", example="Panadería San Jorge"),
 *   @OA\Property(property="description", type="string", nullable=true, example="Panadería artesanal con más de 20 años de experiencia"),
 *   @OA\Property(property="address", type="string", nullable=true, example="Calle Falsa 123"),
 *   @OA\Property(property="latitude", type="number", format="float", nullable=true, example=-34.6037),
 *   @OA\Property(property="longitude", type="number", format="float", nullable=true, example=-58.3816),
 *   @OA\Property(property="phone", type="string", nullable=true, example="+54 11 1234-5678"),
 *   @OA\Property(property="email", type="string", format="email", nullable=true, example="contacto@panaderiasanjorge.com"),
 *   @OA\Property(property="website", type="string", nullable=true, example="https://panaderiasanjorge.com"),
 *   @OA\Property(property="is_active", type="boolean", example=true),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-20T13:50:00Z"),
 *   @OA\Property(
 *     property="products",
 *     type="array",
 *     @OA\Items(ref="#/components/schemas/Product")
 *   ),
 *   @OA\Property(
 *     property="categories",
 *     type="array",
 *     @OA\Items(ref="#/components/schemas/BusinessCategory")
 *   )
 * )
 */
class BusinessSchema {}
