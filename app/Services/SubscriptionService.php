<?php

namespace App\Services;

use App\Models\User;
use App\Models\Subscription;
use App\Models\SubscriptionPlan;
use App\Models\Business;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class SubscriptionService
{
    /**
     * Obtener los límites de productos según el tipo de suscripción.
     */
    public static function getMaxProductsForSubscription(string $plan): int
    {
        $planData = self::getPlanData(strtolower($plan));
        return $planData['max_products'] ?? 0;
    }

    public static function getMaxBusinessesForSubscription(string $plan): int
    {
        $planData = self::getPlanData(strtolower($plan));
        return $planData['max_businesses'] ?? 0;
    }

    /**
     * Obtiene los datos del plan desde caché (o DB) 
     */
    private static function getPlanData(string $planName): array
    {
        $plans = Cache::rememberForever('subscription_plans_cache', function () {
            try {
                return SubscriptionPlan::all()->keyBy('plan_name')->toArray();
            } catch (\Exception $e) {
                return []; // Si la tabla no existe aún, devuelve array vacío para hacer fallback
            }
        });

        // Hacemos Fallback a los quemados en código por si la DB falla temporalmente
        if (empty($plans) || !isset($plans[$planName])) {
            $defaultLimits = [
                'free' => ['max_businesses' => 1, 'max_products' => 10],
                'basic' => ['max_businesses' => 5, 'max_products' => 100],
                'premium' => ['max_businesses' => 10, 'max_products' => 500],
                'enterprise' => ['max_businesses' => 20, 'max_products' => 1000]
            ];
            return $defaultLimits[$planName] ?? ['max_businesses' => 0, 'max_products' => 0];
        }

        return $plans[$planName];
    }

    /**
     * Verificar si el usuario puede crear más negocios.
     */
    public static function canCreateBusiness(User $user)
    {
        $subscription = $user->subscription ?? self::createDefaultSubscription($user);
        $maxBusinesses = self::getMaxBusinessesForSubscription($subscription->type);
        $currentBusinesses = $user->businesses()->count();

        return [
            'can_create' => $currentBusinesses < $maxBusinesses,
            'message' => $currentBusinesses >= $maxBusinesses ?
                sprintf(
                    'Has alcanzado el límite de %d negocios para tu plan (%s). Actualiza tu suscripción para crear más negocios.',
                    $maxBusinesses,
                    $subscription->type
                ) : null,
            'max_businesses' => $maxBusinesses,
            'current_businesses' => $currentBusinesses
        ];
    }

    /**
     * Verificar si el usuario puede crear más productos en un negocio.
     */
    public static function canCreateProduct(User $user, $businessId)
    {
        $subscription = $user->subscription ?? self::createDefaultSubscription($user);
        $maxProducts = self::getMaxProductsForSubscription($subscription->type);
        $currentProducts = Business::find($businessId)->products()->count();

        return [
            'can_create' => $currentProducts < $maxProducts,
            'message' => $currentProducts >= $maxProducts ?
                sprintf(
                    'Has alcanzado el límite de %d productos para tu plan (%s). Actualiza tu suscripción para crear más productos.',
                    $maxProducts,
                    $subscription->type
                ) : null,
            'max_products' => $maxProducts,
            'current_products' => $currentProducts
        ];
    }

    /**
     * Crear una suscripción por defecto si no existe.
     */
    public static function createDefaultSubscription(User $user)
    {
        return $user->subscription()->create([
            'type' => 'free',
            'product_limit' => 10,
            'is_active' => true
        ]);
    }

    /**
     * Cambiar el plan de suscripción de un usuario.
     */
    public static function changePlan(User $user, $newPlan)
    {
        $subscription = $user->subscription ?? self::createDefaultSubscription($user);

        $maxBusinesses = self::getMaxBusinessesForSubscription($newPlan);
        $maxProducts = self::getMaxProductsForSubscription($newPlan);

        $businesses = $user->businesses()->withCount('products')->get();
        $currentBusinesses = $businesses->count();

        // Si el usuario tiene más negocios que el límite del nuevo plan, desactivar los excedentes
        if ($currentBusinesses > $maxBusinesses) {
            $businessesToDeactivate = $businesses->sortBy('created_at')->take($currentBusinesses - $maxBusinesses);

            foreach ($businessesToDeactivate as $business) {
                $business->update(['is_active' => false]);

                // Si el negocio tiene más productos que el límite del nuevo plan, desactivar los productos excedentes
                if ($business->products_count > $maxProducts) {
                    $products = $business->products()->orderBy('created_at')->get();
                    $productsToDeactivate = $products->take($business->products_count - $maxProducts);

                    foreach ($productsToDeactivate as $product) {
                        $product->update(['is_active' => false]);
                    }
                }
            }
        } else {
            // Si no excede el límite de negocios, verificar productos en cada negocio
            foreach ($businesses as $business) {
                if ($business->products_count > $maxProducts) {
                    $products = $business->products()->orderBy('created_at')->get();
                    $productsToDeactivate = $products->take($business->products_count - $maxProducts);

                    foreach ($productsToDeactivate as $product) {
                        $product->update(['is_active' => false]);
                    }
                }
            }
        }

        // Actualizar la suscripción al nuevo plan
        $subscription->update([
            'type' => $newPlan,
            'product_limit' => $maxProducts,
            'is_active' => true,
            'ends_at' => $newPlan === 'free' ? null : now()->addYear()
        ]);

        return true;
    }



}

