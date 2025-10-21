<?php
namespace App\Documentation\Schemas;

/**
 * @OA\Schema(
 *   schema="BusinessImage",
 *   required={"id", "business_id", "url"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="business_id", type="integer", example=5),
 *   @OA\Property(property="url", type="string", example="business_images/abc123.jpg"),
 *   @OA\Property(property="is_primary", type="boolean", example=false),
 *   @OA\Property(property="description", type="string", nullable=true, example="Fachada de la panadería"),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T13:45:00Z"),
 *   @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-20T13:50:00Z")
 * )
 */
class BusinessImageSchema {}