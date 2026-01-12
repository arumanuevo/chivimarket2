<?php

// app/Http/Resources/SubscriptionResource.php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SubscriptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'type' => $this->type,                     // Valor original
            'formatted_type' => $this->formatted_type,  // Accessor
            'product_limit' => $this->product_limit,
            'starts_at' => $this->starts_at,          // Valor original
            'formatted_starts_at' => $this->formatted_starts_at,  // Accessor
            'ends_at' => $this->ends_at,              // Valor original
            'formatted_ends_at' => $this->formatted_ends_at,  // Accessor
            'is_active' => $this->is_active,
            'status' => $this->status,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}

