<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
use App\Services\SubscriptionService;

class SubscriptionController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/subscription",
     *     summary="Obtener suscripción actual",
     *     description="Devuelve la suscripción actual del usuario autenticado. Si no tiene suscripción, crea una por defecto (plan 'free').",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Suscripción del usuario",
     *         @OA\JsonContent(ref="#/components/schemas/Subscription")
     *     )
     * )
     */
    public function show()
    {
        $user = Auth::user();
        $subscription = $user->subscription ?? $user->subscription()->create([
            'type' => 'free',
            'product_limit' => SubscriptionService::getMaxProductsForSubscription('free'),
            'is_active' => true
        ]);
        return response()->json($subscription);
    }

    /**
     * @OA\Put(
     *     path="/api/subscription/upgrade",
     *     summary="Actualizar suscripción",
     *     description="Actualiza el plan de suscripción del usuario autenticado. Si el plan no es 'free', se requiere un método de pago.",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="plan", type="string", enum={"free", "basic", "premium", "enterprise"}, example="premium"),
     *             @OA\Property(property="payment_method", type="string", enum={"mercadopago", "transferencia", "tarjeta"}, nullable=true, example="mercadopago")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Suscripción actualizada correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="¡Suscripción actualizada a Premium! Ahora puedes tener hasta 10 negocios y 500 productos.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function upgrade(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan' => 'required|in:free,basic,premium,enterprise',
            'payment_method' => $request->plan !== 'free' ? 'required|string|in:mercadopago,transferencia,tarjeta' : 'nullable'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = Auth::user();
        $plan = $request->plan;

        if ($plan !== 'free') {
            $user->subscription()->updateOrCreate(
                ['user_id' => $user->id],
                [
                    'type' => $plan,
                    'product_limit' => SubscriptionService::getMaxProductsForSubscription($plan),
                    'starts_at' => now(),
                    'ends_at' => now()->addYear(),
                    'is_active' => true
                ]
            );
        } else {
            // Si es degradación a free, usar la lógica de degradación
            SubscriptionService::changePlan($user, $plan);
        }

        return response()->json([
            'message' => sprintf(
                '¡Suscripción actualizada a %s! Ahora puedes tener hasta %d negocios y %d productos.',
                ucfirst($plan),
                SubscriptionService::getMaxBusinessesForSubscription($plan),
                SubscriptionService::getMaxProductsForSubscription($plan)
            )
        ]);
    }

    /**
     * @OA\Get(
     *     path="/api/subscription/check-business-creation",
     *     summary="Verificar si puede crear un negocio",
     *     description="Verifica si el usuario autenticado puede crear un nuevo negocio según su suscripción actual.",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Resultado de la verificación",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="can_create", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Puedes crear un nuevo negocio.")
     *         )
     *     )
     * )
     */
    public function checkBusinessCreation()
    {
        $user = Auth::user();
        return response()->json(SubscriptionService::canCreateBusiness($user));
    }

    /**
     * @OA\Get(
     *     path="/api/subscription/check-product-creation/{business}",
     *     summary="Verificar si puede crear un producto",
     *     description="Verifica si el usuario autenticado puede crear un nuevo producto en un negocio específico según su suscripción actual.",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Resultado de la verificación",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="can_create", type="boolean", example=true),
     *             @OA\Property(property="message", type="string", example="Puedes crear un nuevo producto en este negocio.")
     *         )
     *     )
     * )
     */
    public function checkProductCreation(Business $business)
    {
        $user = Auth::user();
        return response()->json(SubscriptionService::canCreateProduct($user, $business->id));
    }

    /**
     * @OA\Put(
     *     path="/api/subscription/change-plan",
     *     summary="Cambiar plan de suscripción",
     *     description="Cambia el plan de suscripción de un usuario específico. Solo accesible para administradores.",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="user_id", type="integer", example=1),
     *             @OA\Property(property="new_plan", type="string", enum={"free", "basic", "premium", "enterprise"}, example="premium")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Plan de suscripción cambiado correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Suscripción cambiada a Premium correctamente. Algunos negocios o productos pueden haber sido desactivados si excedían los límites del nuevo plan.")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function changePlan(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'new_plan' => 'required|in:free,basic,premium,enterprise'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = User::find($request->user_id);
        $newPlan = $request->new_plan;

        SubscriptionService::changePlan($user, $newPlan);

        return response()->json([
            'message' => sprintf(
                'Suscripción cambiada a %s correctamente. Algunos negocios o productos pueden haber sido desactivados si excedían los límites del nuevo plan.',
                ucfirst($newPlan)
            )
        ]);
    }

    /**
     * @OA\Get(
     *     path="/api/subscription/status",
     *     summary="Estado de la suscripción",
     *     description="Devuelve el estado actual de la suscripción del usuario autenticado, incluyendo límites de negocios y productos según el plan.",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Response(
     *         response=200,
     *         description="Estado de la suscripción",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="type", type="string", example="premium"),
     *             @OA\Property(property="product_limit", type="integer", example=500),
     *             @OA\Property(property="is_active", type="boolean", example=true),
     *             @OA\Property(property="status", type="string", example="active"),
     *             @OA\Property(property="max_businesses", type="integer", example=10),
     *             @OA\Property(property="max_products", type="integer", example=500)
     *         )
     *     )
     * )
     */
    public function status()
    {
        $user = Auth::user();
        $subscription = $user->subscription ?? SubscriptionService::createDefaultSubscription($user);

        return response()->json([
            'type' => $subscription->type,
            'product_limit' => $subscription->product_limit,
            'is_active' => $subscription->is_active,
            'status' => $subscription->status,
            'max_businesses' => SubscriptionService::getMaxBusinessesForSubscription($subscription->type),
            'max_products' => SubscriptionService::getMaxProductsForSubscription($subscription->type),
        ]);
    }

}


