<?php
namespace App\Documentation\Schemas;
/**
 * @OA\Schema(
 *     schema="DiscountToken",
 *     title="Token de Descuento",
 *     description="Token de descuento generado por un usuario para un negocio o producto",
 *     @OA\Property(property="id", type="integer", example=1, description="ID del token"),
 *     @OA\Property(property="code", type="string", example="ABCD-1234", description="Código único del token"),
 *     @OA\Property(property="business_id", type="integer", example=21, description="ID del negocio"),
 *     @OA\Property(property="product_id", type="integer", example=5, description="ID del producto (nullable)"),
 *     @OA\Property(property="user_id", type="integer", example=3, description="ID del usuario que generó el token"),
 *     @OA\Property(property="discount_type", type="string", enum={"percentage", "fixed"}, example="percentage", description="Tipo de descuento"),
 *     @OA\Property(property="discount_value", type="number", example=10, description="Valor del descuento (10 para 10% o 5.00 para $5)"),
 *     @OA\Property(property="min_purchase", type="number", example=50, description="Mínimo de compra requerido (nullable)"),
 *     @OA\Property(property="max_uses", type="integer", example=1, description="Número máximo de usos"),
 *     @OA\Property(property="uses_count", type="integer", example=0, description="Número de veces que se ha usado"),
 *     @OA\Property(property="valid_from", type="string", format="date-time", example="2025-10-26T00:00:00.000000Z", description="Fecha desde cuando es válido"),
 *     @OA\Property(property="valid_until", type="string", format="date-time", example="2025-11-02T00:00:00.000000Z", description="Fecha hasta cuando es válido"),
 *     @OA\Property(property="description", type="string", example="10% de descuento en tu próxima compra", description="Descripción del descuento"),
 *     @OA\Property(property="is_active", type="boolean", example=true, description="Si el cupón está activo"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z", description="Fecha de creación"),
 *     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z", description="Fecha de última actualización"),
 *     @OA\Property(property="business", ref="#/components/schemas/Business"),
 *     @OA\Property(property="product", ref="#/components/schemas/Product"),
 *     @OA\Property(property="user", ref="#/components/schemas/User")
 * )
 */
class DiscountToken {}
