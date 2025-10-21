<?php
    namespace App\Documentation\Schemas;
    
/**
 * @OA\Schema(
 *   schema="Product",
 *   required={"id", "name", "price", "stock"},
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="name", type="string", example="Pan artesanal integral"),
 *   @OA\Property(property="description", type="string", nullable=true, example="Pan con harina integral y semillas"),
 *   @OA\Property(property="price", type="number", format="float", example=350.50),
 *   @OA\Property(property="stock", type="integer", example=20),
 *   @OA\Property(property="is_active", type="boolean", example=true),
 *   @OA\Property(property="category_id", type="integer", example=3),
 *   @OA\Property(property="business_id", type="integer", example=5),
 *   @OA\Property(
 *     property="category",
 *     type="object",
 *     @OA\Property(property="id", type="integer", example=3),
 *     @OA\Property(property="name", type="string", example="Panadería")
 *   ),
 *   @OA\Property(
 *     property="business",
 *     type="object",
 *     @OA\Property(property="id", type="integer", example=5),
 *     @OA\Property(property="name", type="string", example="Panadería San Jorge")
 *   ),
 *   @OA\Property(
 *     property="images",
 *     type="array",
 *     @OA\Items(
 *       type="object",
 *       @OA\Property(property="url", type="string", example="https://cdn.chivimarket.arumasoft.com/pan.jpg")
 *     )
 *   )
 * )
 */
class ProductSchema {}