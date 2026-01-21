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
        // Guardar el modelo User original en una variable
        $userModel = $this->resource;

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

            // Negocios del usuario + conteo + existencia
            'businesses' => $this->businesses,
            'businesses_count' => $this->businesses->count(),
            'has_business' => $this->businesses->isNotEmpty(),  // <-- Nuevo campo booleano

            // Datos adicionales para evaluaciones posteriores
            'can_create_business' => $this->subscription ?
                SubscriptionService::canCreateBusiness($userModel)['can_create'] :
                false,

            'can_create_product' => $this->subscription ?
                (SubscriptionService::canCreateProduct($userModel, $this->businesses->first()?->id)['can_create'] ?? false) :
                false,

            // Límites según suscripción
            'max_businesses_allowed' => $this->subscription ?
                SubscriptionService::getMaxBusinessesForSubscription($this->subscription->type) :
                1,

            'max_products_allowed' => $this->subscription ?
                SubscriptionService::getMaxProductsForSubscription($this->subscription->type) :
                10
        ];
    }
}