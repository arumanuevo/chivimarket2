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

        // Cargar los accessors
        $subscription->load('user');
        $subscription->append(['formatted_type', 'formatted_starts_at', 'formatted_ends_at']);

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
   /* public function upgrade(Request $request)
    {
        

        $validator = Validator::make($request->all(), [
            'plan' => ['required', 'in:Free,Basic,Premium,Enterprise,free,basic,premium,enterprise'],
            'payment_method' => $request->plan !== 'free' ?
                ['required', 'string', 'in:MercadoPago,Transferencia,Tarjeta,mercadopago,transferencia,tarjeta'] :
                'nullable'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = Auth::user();
        $plan = $request->plan;
        $formattedPlan = ucfirst($plan); // Capitalizar primera letra

        if ($plan !== 'free') {
            $user->subscription()->updateOrCreate(
                ['user_id' => $user->id],
                [
                    'type' => $plan,
                    'product_limit' => SubscriptionService::getMaxProductsForSubscription($plan),
                    'starts_at' => now(),
                    'ends_at' => now()->addMonth(),
                    'is_active' => true
                ]
            );
        } else {
            SubscriptionService::changePlan($user, $plan);
        }

        return response()->json([
            'message' => sprintf(
                '¡Suscripción actualizada a %s! Ahora puedes tener hasta %d negocios y %d productos.',
                $formattedPlan,
                SubscriptionService::getMaxBusinessesForSubscription($plan),
                SubscriptionService::getMaxProductsForSubscription($plan)
            )
        ]);
    }*/

    // En SubscriptionController.php
    public function upgrade(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan' => ['required', 'in:free,basic,premium,enterprise'],
            'payment_method' => $request->plan !== 'free' ?
                ['required', 'string', 'in:mercadopago,transferencia,tarjeta'] :
                'nullable'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = Auth::user();
        $currentSubscription = $user->subscription ?? SubscriptionService::createDefaultSubscription($user);
        $newPlan = strtolower($request->plan);
        $isDowngrade = in_array($currentSubscription->type, ['premium', 'enterprise', 'basic']) &&
                    in_array($newPlan, ['free', 'basic']) &&
                    $currentSubscription->type !== $newPlan;

        // Bloquear downgrade si no está permitido
        if ($isDowngrade && !$currentSubscription->can_downgrade) {
            return response()->json([
                'error' => sprintf(
                    'No puedes hacer downgrade hasta el %s. Tu suscripción actual vence el %s.',
                    $currentSubscription->downgrade_lock_until?->format('d-m-Y'),
                    $currentSubscription->next_payment_due?->format('d-m-Y')
                )
            ], 403);
        }

        // Procesar upgrade/downgrade
        if ($newPlan !== 'free') {
            $paymentDue = now()->addMonth(); // Próximo vencimiento
            $user->subscription()->updateOrCreate(
                ['user_id' => $user->id],
                [
                    'type' => $newPlan,
                    'product_limit' => SubscriptionService::getMaxProductsForSubscription($newPlan),
                    'payment_method' => $request->payment_method ? strtolower($request->payment_method) : null,
                    'last_payment_date' => now(),
                    'next_payment_due' => $paymentDue,
                    'can_downgrade' => false, // Bloquear downgrade hasta próximo pago
                    'downgrade_lock_until' => $paymentDue,
                    'payment_status' => 'paid',
                    'starts_at' => now(),
                    'ends_at' => $paymentDue,
                    'is_active' => true
                ]
            );
        } else {
            // Downgrade a free (sin bloqueos)
            SubscriptionService::changePlan($user, $newPlan);
            $user->subscription()->update([
                'can_downgrade' => true,
                'downgrade_lock_until' => null,
                'payment_status' => 'cancelled'
            ]);
        }

        return response()->json([
            'message' => sprintf(
                '¡Suscripción actualizada a %s! Ahora puedes tener hasta %d negocios y %d productos.',
                ucfirst($newPlan),
                SubscriptionService::getMaxBusinessesForSubscription($newPlan),
                SubscriptionService::getMaxProductsForSubscription($newPlan)
            ),
            'next_payment_due' => $newPlan !== 'free' ? now()->addMonth()->format('d-m-Y') : null,
            'can_downgrade' => $newPlan === 'free' ? true : false
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
        $formattedNewPlan = ucfirst($newPlan); // Capitalizar primera letra

        SubscriptionService::changePlan($user, $newPlan);

        return response()->json([
            'message' => sprintf(
                'Suscripción cambiada a %s correctamente. Algunos negocios o productos pueden haber sido desactivados si excedían los límites del nuevo plan.',
                $formattedNewPlan
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

        // Añadir los accessors al response
        $subscription->append(['formatted_type', 'formatted_starts_at', 'formatted_ends_at']);

        return response()->json([
            'type' => $subscription->type,
            'formatted_type' => $subscription->formatted_type,
            'product_limit' => $subscription->product_limit,
            'is_active' => $subscription->is_active,
            'status' => $subscription->status,
            'max_businesses' => SubscriptionService::getMaxBusinessesForSubscription($subscription->type),
            'max_products' => SubscriptionService::getMaxProductsForSubscription($subscription->type),
            'starts_at' => $subscription->starts_at,
            'formatted_starts_at' => $subscription->formatted_starts_at,
            'ends_at' => $subscription->ends_at,
            'formatted_ends_at' => $subscription->formatted_ends_at,
        ]);
    }

    /**
     * @OA\Post(
     *     path="/api/subscription/register-payment",
     *     summary="Registrar pago de suscripción",
     *     description="Registra un pago exitoso para la suscripción actual del usuario.",
     *     tags={"Suscripciones"},
     *     security={{"bearerAuth": {}}},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             @OA\Property(property="payment_method", type="string", enum={"mercadopago", "transferencia", "tarjeta"}, example="mercadopago"),
     *             @OA\Property(property="transaction_id", type="string", example="MP123456789", description="ID de la transacción")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Pago registrado correctamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Pago registrado. Tu suscripción está activa hasta el 13-02-2026."),
     *             @OA\Property(property="next_payment_due", type="string", example="13-02-2026")
     *         )
     *     )
     * )
     */
    public function registerPayment(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'payment_method' => ['required', 'string', 'in:mercadopago,transferencia,tarjeta'],
            'transaction_id' => ['required', 'string']
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = Auth::user();
        $subscription = $user->subscription;

        if (!$subscription || $subscription->type === 'free') {
            return response()->json(['error' => 'No tienes una suscripción que requiera pago.'], 400);
        }

        // Actualizar suscripción
        $nextDue = now()->addMonth();
        $subscription->update([
            'last_payment_date' => now(),
            'next_payment_due' => $nextDue,
            'can_downgrade' => true, // Permitir downgrade hasta próximo vencimiento
            'downgrade_lock_until' => $nextDue,
            'payment_status' => 'paid'
        ]);

        return response()->json([
            'message' => sprintf(
                'Pago registrado. Tu suscripción está activa hasta el %s.',
                $nextDue->format('d-m-Y')
            ),
            'next_payment_due' => $nextDue->format('d-m-Y')
        ]);
    }


}


