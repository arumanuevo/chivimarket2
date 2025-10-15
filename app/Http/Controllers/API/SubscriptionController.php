<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;
class SubscriptionController extends Controller
{
    // Obtener suscripción actual
    public function show()
    {
        $user = Auth::user();
        $subscription = $user->subscription ?? $user->subscription()->create([
            'type' => 'free',
            'product_limit' => 10,
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
                'product_limit' => $this->getProductLimitForPlan($plan),
                'starts_at' => now(),
                'ends_at' => now()->addYear(),
                'is_active' => true
            ]
        );

        return response()->json([
            'message' => sprintf(
                '¡Suscripción actualizada a %s! Ahora puedes tener hasta %d negocios y %d productos.',
                ucfirst($plan),
                $this->getMaxBusinessesForSubscription($plan),
                $this->getProductLimitForPlan($plan)
            )
        ]);
    }

    /**
     * Obtener el límite de negocios según el plan.
     */
    protected function getMaxBusinessesForSubscription($subscriptionType)
    {
        $limits = [
            'free' => 1,      // Usuarios free pueden tener 1 negocio
            'basic' => 3,     // Usuarios basic pueden tener 3 negocios
            'premium' => 10,   // Usuarios premium pueden tener 10 negocios
            'enterprise' => 50 // Usuarios enterprise pueden tener 50 negocios
        ];
        return $limits[$subscriptionType] ?? 1;
    }

    /**
     * Obtener el límite de productos según el plan.
     */
    protected function getProductLimitForPlan($plan)
    {
        $limits = [
            'basic' => 50,      // 50 productos
            'premium' => 1000,  // 1000 productos
            'enterprise' => 5000 // 5000 productos
        ];
        return $limits[$plan] ?? 10;
    }
}


