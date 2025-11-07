<?php

namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\BusinessRating;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
/**
 * @OA\Tag(
 *     name="BusinessRatings",
 *     description="API para gestionar calificaciones de negocios"
 * )
 */
class BusinessRatingController extends Controller
{
 
    /**
     * @OA\Post(
     *     path="/api/businesses/{business}/ratings",
     *     summary="Calificar un negocio",
     *     description="Permite a un usuario calificar la calidad del servicio de un negocio (1-5 estrellas).",
     *     tags={"BusinessRatings"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio a calificar",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"service_quality"},
     *             @OA\Property(property="service_quality", type="integer", description="Calificación (1-5 estrellas)", example=5),
     *             @OA\Property(property="comment", type="string", description="Comentario opcional", example="Excelente servicio y atención al cliente")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Calificación registrada correctamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Calificación registrada correctamente"),
     *             @OA\Property(property="rating", type="object", ref="#/components/schemas/BusinessRating")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado (ej: ya calificaste este negocio)",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Ya has calificado este negocio.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Error de validación"),
     *             @OA\Property(property="errors", type="object", example={"service_quality": {"The service quality field is required."}})
     *         )
     *     )
     * )
     */
    public function store(Request $request, Business $business)
    {
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'service_quality' => 'required|integer|between:1,5',
            'comment' => 'nullable|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Verificar si el usuario ya calificó este negocio
        $existingRating = BusinessRating::where('business_id', $business->id)
            ->where('user_id', $user->id)
            ->first();

        if ($existingRating) {
            return response()->json([
                'message' => 'Ya has calificado este negocio.'
            ], 403);
        }

        $rating = BusinessRating::create([
            'business_id' => $business->id,
            'user_id' => $user->id,
            'service_quality' => $request->service_quality,
            'comment' => $request->comment
        ]);

        return response()->json([
            'message' => 'Calificación registrada correctamente',
            'rating' => $rating
        ], 201);
    }


      /**
     * @OA\Get(
     *     path="/api/businesses/{business}/ratings",
     *     summary="Listar calificaciones de un negocio",
     *     description="Devuelve todas las calificaciones de un negocio, incluyendo el promedio y el total.",
     *     tags={"BusinessRatings"},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de calificaciones y promedio",
     *         @OA\JsonContent(
     *             @OA\Property(property="ratings", type="array", @OA\Items(ref="#/components/schemas/BusinessRating")),
     *             @OA\Property(property="average_rating", type="number", format="float", example=4.5),
     *             @OA\Property(property="total_ratings", type="integer", example=10)
     *         )
     *     )
     * )
     */

    public function index(Business $business)
    {
        $ratings = BusinessRating::where('business_id', $business->id)
            ->with(['user'])
            ->orderBy('created_at', 'desc')
            ->get();

        $averageRating = $ratings->avg('service_quality');

        return response()->json([
            'ratings' => $ratings,
            'average_rating' => round($averageRating, 1),
            'total_ratings' => $ratings->count()
        ]);
    }
}
