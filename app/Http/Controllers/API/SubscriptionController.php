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
    // Obtener suscripción actual
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

    // Actualizar suscripción
    public function upgrade(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'plan' => 'required|in:basic,premium,enterprise',
            'payment_method' => 'required|string|in:mercadopago,transferencia,tarjeta'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = Auth::user();
        $plan = $request->plan;

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

        return response()->json([
            'message' => sprintf(
                '¡Suscripción actualizada a %s! Ahora puedes tener hasta %d negocios y %d productos.',
                ucfirst($plan),
                SubscriptionService::getMaxBusinessesForSubscription($plan),
                SubscriptionService::getMaxProductsForSubscription($plan)
            )
        ]);
    }

    public function checkBusinessCreation()
    {
        $user = Auth::user();
        return response()->json(SubscriptionService::canCreateBusiness($user));
    }

    public function checkProductCreation(Business $business)
    {
        $user = Auth::user();
        return response()->json(SubscriptionService::canCreateProduct($user, $business->id));
    }
}


