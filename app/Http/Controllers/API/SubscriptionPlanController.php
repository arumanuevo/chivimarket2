<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class SubscriptionPlanController extends Controller
{
    /**
     * Devuelve todos los planes actuales (ya sea DB o fallback).
     */
    public function index()
    {
        // Se asume middleware auth:sanctum y checkeo de rol si aplica
        $plans = SubscriptionPlan::all();
        // Si no han corrido el SQL, devolvemos un array simulado
        if ($plans->isEmpty()) {
            return response()->json([
                ['id' => 1, 'plan_name' => 'free', 'max_businesses' => 1, 'max_products' => 10],
                ['id' => 2, 'plan_name' => 'basic', 'max_businesses' => 5, 'max_products' => 100],
                ['id' => 3, 'plan_name' => 'premium', 'max_businesses' => 10, 'max_products' => 500],
                ['id' => 4, 'plan_name' => 'enterprise', 'max_businesses' => 20, 'max_products' => 1000]
            ]);
        }

        return response()->json($plans);
    }

    /**
     * Actualiza masivamente los alcances de los planes.
     */
    public function updateMassive(Request $request)
    {
        $data = $request->validate([
            'plans' => 'required|array',
            'plans.*.plan_name' => 'required|string',
            'plans.*.max_businesses' => 'required|integer|min:1',
            'plans.*.max_products' => 'required|integer|min:1'
        ]);

        foreach ($data['plans'] as $p) {
            SubscriptionPlan::updateOrCreate(
                ['plan_name' => $p['plan_name']],
                [
                    'max_businesses' => $p['max_businesses'],
                    'max_products' => $p['max_products']
                ]
            );
        }

        // Importante: Purgar el caché para que el Servicio lea los nuevos límites al instante
        Cache::forget('subscription_plans_cache');

        return response()->json(['message' => 'Límites actualizados con éxito.']);
    }
}
