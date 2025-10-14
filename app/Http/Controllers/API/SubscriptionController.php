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
        $subscription = Auth::user()->subscription ?? Auth::user()->subscription()->create([
            'type' => 'free',
            'product_limit' => 10
        ]);

        return response()->json($subscription);
    }

    // Actualizar a premium
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
            'message' => sprintf('¡Suscripción actualizada a %s! Ahora puedes tener hasta %d negocios.',
                ucfirst($plan),
                $this->getProductLimitForPlan($plan)
            )
        ]);
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

        return $limits[$plan] ?? 10; // Default: 10 (si no existe el plan)
    }
}

