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


