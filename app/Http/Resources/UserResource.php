<?php

// app/Http/Resources/UserResource.php
/*namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'email_verified_at' => $this->email_verified_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'roles' => $this->roles,
            'permissions' => $this->permissions,
            'businesses' => $this->businesses,
            'subscription' => $this->subscription ? new SubscriptionResource($this->subscription) : null,
        ];
    }
}*/

// app/Http/Resources/UserResource.php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Services\SubscriptionService;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'email_verified_at' => $this->email_verified_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,

            // Datos de suscripción (si existe)
            'subscription' => $this->subscription ? new SubscriptionResource($this->subscription) : null,

            // Roles y permisos
            'roles' => $this->roles,
            'permissions' => $this->permissions,

            // Negocios del usuario + conteo
            'businesses' => $this->businesses,
            'businesses_count' => $this->businesses->count(),  // <-- Conteo de negocios

            // Datos adicionales para evaluaciones posteriores
            'can_create_business' => $this->subscription ?
                SubscriptionService::canCreateBusiness($this)['can_create'] :
                false,

            'can_create_product' => $this->subscription ?
                SubscriptionService::canCreateProduct($this, $this->businesses->first()?->id)['can_create'] ?? false :
                false,

            // Límite de negocios según suscripción
            'max_businesses_allowed' => $this->subscription ?
                SubscriptionService::getMaxBusinessesForSubscription($this->subscription->type) :
                1,  // Default para suscripción 'free'

            // Límite de productos según suscripción
            'max_products_allowed' => $this->subscription ?
                SubscriptionService::getMaxProductsForSubscription($this->subscription->type) :
                10  // Default para suscripción 'free'
        ];
    }
}


