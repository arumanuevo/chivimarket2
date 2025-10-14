<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'business_id',
        'category_id',  // Añadido para la relación con ProductCategory
        'name',
        'description',
        'price',
        'stock',
        'is_active'
    ];

    /**
     * Relación con el negocio al que pertenece el producto.
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    /**
     * Relación con la categoría del producto.
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ProductCategory::class, 'category_id');
    }

    /**
     * Relación con las imágenes del producto.
     */
    public function images(): HasMany
    {
        return $this->hasMany(ProductImage::class);
    }
}
