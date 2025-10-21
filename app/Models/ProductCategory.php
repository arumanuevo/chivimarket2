<?php

namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProductCategory extends Model
{

    use HasFactory;

    /**
     * Campos asignables en masa.
     *
     * @var array
     */
    protected $fillable = [
        'name',
        'description',
        'parent_id',    // Para categorías jerárquicas (ej: "Alimentos" -> "Panadería")
        'is_active'     // Si la categoría está activa
    ];

    /**
     * Relación con la categoría padre (para jerarquías).
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    /**
     * Relación con las subcategorías.
     */
    public function children(): HasMany
    {
        return $this->hasMany(self::class, 'parent_id');
    }

    /**
     * Relación con los productos de esta categoría.
     */
    public function products(): HasMany
    {
        return $this->hasMany(Product::class, 'category_id');
    }

    /**
     * Scope para obtener solo categorías activas.
     */
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
