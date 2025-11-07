<?php

namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
/**
 * @OA\Tag(
 *     name="ProductRatings",
 *     description="API para gestionar calificaciones de productos"
 * )
 */
class ProductRatingController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/products/{product}/ratings",
     *     summary="Calificar un producto",
     *     description="Permite a un usuario calificar la calidad de un producto (1-5 estrellas).",
     *     tags={"ProductRatings"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto a calificar",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"quality"},
     *             @OA\Property(property="quality", type="integer", description="Calificación (1-5 estrellas)", example=4),
     *             @OA\Property(property="comment", type="string", description="Comentario opcional", example="Producto de buena calidad, cumple con lo prometido")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Calificación registrada correctamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Calificación registrada correctamente"),
     *             @OA\Property(property="rating", type="object", ref="#/components/schemas/ProductRating")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado (ej: ya calificaste este producto)",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Ya has calificado este producto.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Error de validación"),
     *             @OA\Property(property="errors", type="object", example={"quality": {"The quality field is required."}})
     *         )
     *     )
     * )
     */

    public function store(Request $request, Product $product)
    {
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'quality' => 'required|integer|between:1,5',
            'comment' => 'nullable|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Verificar si el usuario ya calificó este producto
        $existingRating = ProductRating::where('product_id', $product->id)
            ->where('user_id', $user->id)
            ->first();

        if ($existingRating) {
            return response()->json([
                'message' => 'Ya has calificado este producto.'
            ], 403);
        }

        $rating = ProductRating::create([
            'product_id' => $product->id,
            'user_id' => $user->id,
            'quality' => $request->quality,
            'comment' => $request->comment
        ]);

        return response()->json([
            'message' => 'Calificación registrada correctamente',
            'rating' => $rating
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/api/products/{product}/ratings",
     *     summary="Listar calificaciones de un producto",
     *     description="Devuelve todas las calificaciones de un producto, incluyendo el promedio y el total.",
     *     tags={"ProductRatings"},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de calificaciones y promedio",
     *         @OA\JsonContent(
     *             @OA\Property(property="ratings", type="array", @OA\Items(ref="#/components/schemas/ProductRating")),
     *             @OA\Property(property="average_rating", type="number", format="float", example=4.2),
     *             @OA\Property(property="total_ratings", type="integer", example=5)
     *         )
     *     )
     * )
     */
    
    public function index(Product $product)
    {
        $ratings = ProductRating::where('product_id', $product->id)
            ->with(['user'])
            ->orderBy('created_at', 'desc')
            ->get();

        $averageRating = $ratings->avg('quality');

        return response()->json([
            'ratings' => $ratings,
            'average_rating' => round($averageRating, 1),
            'total_ratings' => $ratings->count()
        ]);
    }
}
