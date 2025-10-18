<?php

namespace App\Services;

use App\Models\User;
use App\Models\Subscription;

class SubscriptionService
{
    /**
     * Obtener los límites de negocios según el tipo de suscripción.
     */
    public static function getMaxBusinessesForSubscription($subscriptionType)
    {
        $limits = [
            'free' => 1,
            'basic' => 3,
            'premium' => 10,
            'enterprise' => 50
        ];
        return $limits[$subscriptionType] ?? 1;
    }

    /**
     * Obtener los límites de productos según el tipo de suscripción.
     */
    public static function getMaxProductsForSubscription($subscriptionType)
    {
        $limits = [
            'free' => 10,
            'basic' => 50,
            'premium' => 1000,
            'enterprise' => 5000
        ];
        return $limits[$subscriptionType] ?? 10;
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
        $currentProducts = \App\Models\Business::find($businessId)->products()->count();

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
}
