<?php

namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Business extends Model
{
    
    use HasFactory;

    protected $casts = [
        'user_id' => 'integer',
        'is_active' => 'boolean'
    ];
    
    protected $fillable = [
        'user_id', // <-- Asegúrate de que esté incluido
        'name',
        'description',
        'address',
        'latitude',
        'longitude',
        'phone',
        'email',
        'website',
        'is_active',
        'logo_url',
    ];
    

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    /**
 * Relación muchos-a-muchos con categorías de negocio.
 */
public function categories(): BelongsToMany
{
    return $this->belongsToMany(
        BusinessCategory::class,  // Modelo relacionado
        'business_category',       // Nombre exacto de la tabla pivote
        'business_id',            // Clave foránea de este modelo
        'category_id'             // Clave foránea del modelo BusinessCategory
    );
}


    public function images(): HasMany
    {
        return $this->hasMany(BusinessImage::class);
    }

    public function primaryImage()
    {
        return $this->images()->where('is_primary', true)->first();
    }

    public function getLogoUrlAttribute($value)
    {
        return $value ? rtrim(env('APP_URL'), '/') . '/' . $value : null;
    }
}
