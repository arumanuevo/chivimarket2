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
        // Guardar el modelo User original en una variable para usarlo en los métodos
        $userModel = $this->resource; // <-- Esto es el modelo User original

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'email_verified_at' => $this->email_verified_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,

            // Datos de suscripción
            'subscription' => $this->subscription ? new SubscriptionResource($this->subscription) : null,

            // Roles y permisos
            'roles' => $this->roles,
            'permissions' => $this->permissions,

            // Negocios del usuario + conteo
            'businesses' => $this->businesses,
            'businesses_count' => $this->businesses->count(),

            // Datos adicionales para evaluaciones posteriores
            // Usar $userModel (el modelo User original) en lugar de $this
            'can_create_business' => $this->subscription ?
                SubscriptionService::canCreateBusiness($userModel)['can_create'] :  // <-- Usar $userModel
                false,

            'can_create_product' => $this->subscription ?
                (SubscriptionService::canCreateProduct($userModel, $this->businesses->first()?->id)['can_create'] ?? false) :  // <-- Usar $userModel
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