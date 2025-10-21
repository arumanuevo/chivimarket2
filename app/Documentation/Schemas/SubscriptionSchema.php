<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *   schema="Subscription",
 *   required={"id", "user_id", "type", "product_limit", "is_active"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="user_id", type="integer", example=10),
 *   @OA\Property(property="type", type="string", example="premium"),
 *   @OA\Property(property="product_limit", type="integer", example=100),
 *   @OA\Property(property="starts_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="ends_at", type="string", format="date-time", nullable=true, example="2026-10-20T13:45:00Z"),
 *   @OA\Property(property="is_active", type="boolean", example=true),
 *   @OA\Property(property="status", type="string", example="active"),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-20T13:50:00Z")
 * )
 */
class SubscriptionSchema {}
