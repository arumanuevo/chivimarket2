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
// app/Http/Resources/UserResource.php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use App\Services\SubscriptionService;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $userModel = $this->resource;

        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'email_verified_at' => $this->email_verified_at,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,

            'subscription' => $this->subscription ? new SubscriptionResource($this->subscription) : null,
            'roles' => $this->roles,
            'permissions' => $this->permissions,

            // Usar BusinessResource para formatear los negocios y cargar las categorías e imágenes
            'businesses' => BusinessResource::collection($this->whenLoaded('businesses')),

            'businesses_count' => $this->businesses->count(),
            'has_business' => $this->businesses->isNotEmpty(),

            'can_create_business' => $this->subscription ?
                SubscriptionService::canCreateBusiness($userModel)['can_create'] :
                false,

            'can_create_product' => $this->subscription ?
                ($this->businesses->isNotEmpty() ?
                    (SubscriptionService::canCreateProduct($userModel, $this->businesses->first()->id)['can_create'] ?? false) :
                    false) :
                false,

            'max_businesses_allowed' => $this->subscription ?
                SubscriptionService::getMaxBusinessesForSubscription($this->subscription->type) :
                1,

            'max_products_allowed' => $this->subscription ?
                SubscriptionService::getMaxProductsForSubscription($this->subscription->type) :
                10
        ];
    }
}
