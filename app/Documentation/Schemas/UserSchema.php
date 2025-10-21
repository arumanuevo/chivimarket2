<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *   schema="User",
 *   required={"id", "name", "email"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="name", type="string", example="Juan Pérez"),
 *   @OA\Property(property="email", type="string", format="email", example="juan@example.com"),
 *   @OA\Property(property="email_verified_at", type="string", format="date-time", nullable=true, example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-20T13:50:00Z"),
 *   @OA\Property(
 *     property="businesses",
 *     type="array",
 *     @OA\Items(ref="#/components/schemas/Business")
 *   ),
 *   @OA\Property(
 *     property="subscription",
 *     type="object",
 *     ref="#/components/schemas/Subscription"
 *   )
 * )
 */
class UserSchema {}
