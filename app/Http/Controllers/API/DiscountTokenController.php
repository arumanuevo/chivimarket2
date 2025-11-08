<?php
/**
 * @OA\Schema(
 *     schema="DiscountToken",
 *     title="Token de Descuento",
 *     description="Token de descuento generado por un usuario para un negocio o producto",
 *     @OA\Property(property="id", type="integer", example=1),
 *     @OA\Property(property="code", type="string", example="ABCD-1234"),
 *     @OA\Property(property="business_id", type="integer", example=21),
 *     @OA\Property(property="product_id", type="integer", example=5),
 *     @OA\Property(property="user_id", type="integer", example=3),
 *     @OA\Property(property="discount_type", type="string", enum={"percentage", "fixed"}, example="percentage"),
 *     @OA\Property(property="discount_value", type="number", example=10),
 *     @OA\Property(property="min_purchase", type="number", example=50),
 *     @OA\Property(property="max_uses", type="integer", example=1),
 *     @OA\Property(property="uses_count", type="integer", example=0),
 *     @OA\Property(property="valid_from", type="string", format="date-time", example="2025-10-26T00:00:00.000000Z"),
 *     @OA\Property(property="valid_until", type="string", format="date-time", example="2025-11-02T00:00:00.000000Z"),
 *     @OA\Property(property="description", type="string", example="10% de descuento en tu próxima compra"),
 *     @OA\Property(property="is_active", type="boolean", example=true),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z"),
 *     @OA\Property(property="updated_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z")
 * )
 */
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\DiscountToken;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class DiscountTokenController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/businesses/{business}/discount-tokens",
     *     summary="Generar un token de descuento para un negocio",
     *     description="Genera un token de descuento que el usuario puede presentar al negocio",
     *     tags={"DiscountTokens"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"discount_type", "discount_value", "valid_days"},
     *             @OA\Property(property="product_id", type="integer", example=1, description="ID del producto (opcional)"),
     *             @OA\Property(property="discount_type", type="string", enum={"percentage", "fixed"}, example="percentage", description="Tipo de descuento"),
     *             @OA\Property(property="discount_value", type="number", example=10, description="Valor del descuento (10 para 10% o 5.00 para $5)"),
     *             @OA\Property(property="min_purchase", type="number", example=50, description="Mínimo de compra requerido (opcional)"),
     *             @OA\Property(property="valid_days", type="integer", example=7, description="Días de validez desde hoy"),
     *             @OA\Property(property="description", type="string", example="10% de descuento en tu próxima compra", description="Descripción del descuento")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Token generado exitosamente",
     *         @OA\JsonContent(ref="#/components/schemas/DiscountToken")
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Error de validación"),
     *             @OA\Property(property="errors", type="object")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     )
     * )
     */
    public function store(Request $request, Business $business)
    {
        $user = Auth::user();

        $validator = Validator::make($request->all(), [
            'product_id' => 'nullable|exists:products,id',
            'discount_type' => 'required|in:percentage,fixed',
            'discount_value' => 'required|numeric|min:0.01',
            'min_purchase' => 'nullable|numeric|min:0',
            'valid_days' => 'required|integer|min:1|max:365',
            'description' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $validator->errors()
            ], 400);
        }

        // Verificar que el producto pertenece al negocio (si se especifica)
        if ($request->product_id) {
            $product = Product::find($request->product_id);
            if ($product->business_id != $business->id) {
                return response()->json([
                    'message' => 'El producto no pertenece a este negocio'
                ], 400);
            }
        }

        // Crear el token
        $token = DiscountToken::create([
            'code' => DiscountToken::generateCode(),
            'business_id' => $business->id,
            'product_id' => $request->product_id,
            'user_id' => $user->id,
            'discount_type' => $request->discount_type,
            'discount_value' => $request->discount_value,
            'min_purchase' => $request->min_purchase,
            'valid_from' => now(),
            'valid_until' => now()->addDays($request->valid_days),
            'description' => $request->description
        ]);

        return response()->json([
            'message' => 'Token de descuento generado exitosamente',
            'token' => $token
        ], 201);
    }

    /**
     * @OA\Get(
     *     path="/api/users/me/discount-tokens",
     *     summary="Listar tokens de descuento del usuario",
     *     description="Devuelve todos los tokens de descuento generados por el usuario actual",
     *     tags={"DiscountTokens"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Lista de tokens de descuento",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/DiscountToken"))
     *     )
     * )
     */
    public function index()
    {
        $user = Auth::user();
        $tokens = $user->discountTokens()
            ->with(['business', 'product'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($tokens);
    }

    /**
     * @OA\Get(
     *     path="/api/discount-tokens/{token}",
     *     summary="Ver detalles de un token de descuento",
     *     description="Devuelve los detalles de un token de descuento usando su código",
     *     tags={"DiscountTokens"},
     *     @OA\Parameter(
     *         name="token",
     *         in="path",
     *         required=true,
     *         description="Código del token de descuento",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Detalles del token",
     *         @OA\JsonContent(ref="#/components/schemas/DiscountToken")
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Token no encontrado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Token no encontrado")
     *         )
     *     )
     * )
     */
    public function show($code)
    {
        $token = DiscountToken::where('code', $code)
            ->with(['business', 'product'])
            ->firstOrFail();

        return response()->json($token);
    }

    /**
     * @OA\Post(
     *     path="/api/discount-tokens/{token}/use",
     *     summary="Usar un token de descuento",
     *     description="Registra el uso de un token de descuento por parte de un cliente",
     *     tags={"DiscountTokens"},
     *     @OA\Parameter(
     *         name="token",
     *         in="path",
     *         required=true,
     *         description="Código del token de descuento",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Token usado exitosamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Token usado exitosamente"),
     *             @OA\Property(property="confirmation_code", type="string", example="ABCD1234", description="Código para que el negocio confirme el uso")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Token no válido o ya usado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Token no válido o ya usado")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Token no encontrado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Token no encontrado")
     *         )
     *     )
     * )
     */
    public function useToken($code)
    {
        $token = DiscountToken::where('code', $code)->firstOrFail();

        if (!$token->isValid()) {
            return response()->json([
                'message' => 'Token no válido o ya usado'
            ], 400);
        }

        $user = Auth::user();
        $use = $token->useToken($user);

        if (!$use) {
            return response()->json([
                'message' => 'No se pudo usar el token'
            ], 400);
        }

        // Generar código de confirmación para el negocio
        $confirmationCode = $token->uses()->latest()->first()->generateConfirmationCode();

        return response()->json([
            'message' => 'Token usado exitosamente',
            'confirmation_code' => $confirmationCode,
            'token' => $token->load(['business', 'product'])
        ]);
    }

    /**
     * @OA\Post(
     *     path="/api/discount-tokens/{token}/confirm",
     *     summary="Confirmar uso de un token de descuento",
     *     description="Permite al negocio confirmar que el token fue usado correctamente",
     *     tags={"DiscountTokens"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="token",
     *         in="path",
     *         required=true,
     *         description="Código del token de descuento",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             required={"confirmation_code"},
     *             @OA\Property(property="confirmation_code", type="string", example="ABCD1234", description="Código de confirmación generado al usar el token")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Uso del token confirmado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Uso del token confirmado")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Código de confirmación inválido",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Código de confirmación inválido")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado (el usuario no es dueño del negocio)",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Token no encontrado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Token no encontrado")
     *         )
     *     )
     * )
     */
    public function confirmUse($code, Request $request)
    {
        $token = DiscountToken::where('code', $code)->firstOrFail();
        $user = Auth::user();

        // Verificar que el usuario es dueño del negocio
        if ($token->business_id != $user->business->id) {
            return response()->json([
                'message' => 'No autorizado'
            ], 403);
        }

        $use = $token->uses()->latest()->first();

        if (!$use || $use->business_confirmation_code !== $request->confirmation_code) {
            return response()->json([
                'message' => 'Código de confirmación inválido'
            ], 400);
        }

        // Marcar como confirmado (ya está hecho en generateConfirmationCode)
        return response()->json([
            'message' => 'Uso del token confirmado'
        ]);
    }
}
