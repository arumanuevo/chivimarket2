<?php
// app/Http/Resources/BusinessResource.php
namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BusinessResource extends JsonResource
{
    public function toArray($request)
    {
        // Obtener el dominio base de la aplicación
        $baseUrl = rtrim(env('APP_URL'), '/');

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'name' => $this->name,
            'description' => $this->description,
            'address' => $this->address,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'phone' => $this->phone,
            'email' => $this->email,
            'website' => $this->website,
            'logo_url' => $this->logo_url ? $baseUrl . '/' . $this->logo_url : null,
            'cover_image_url' => $this->cover_image_url ? $baseUrl . '/api/image/' . basename($this->cover_image_url) : null,
            'is_active' => $this->is_active,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
            'categories' => $this->whenLoaded('categories'),
            'images' => $this->whenLoaded('images', function () use ($baseUrl) {
                return $this->images->map(function ($image) use ($baseUrl) {
                    return [
                        'id' => $image->id,
                        'business_id' => $image->business_id,
                        'url' => $baseUrl . '/' . $image->url, // URL completa
                        'full_url' => $image->full_url, // Usar el accessor del modelo
                        'is_primary' => $image->is_primary,
                        'description' => $image->description,
                        'created_at' => $image->created_at,
                        'updated_at' => $image->updated_at
                    ];
                });
            }),
            'first_image_url' => $this->first_image_url ? $baseUrl . '/' . $this->first_image_url : 'https://via.placeholder.com/300x200?text=Sin+Imagen',
            'products' => $this->whenLoaded('products')
        ];
    }
}
