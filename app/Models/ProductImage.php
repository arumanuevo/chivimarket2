<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductImage extends Model
{
    use HasFactory;

    /**
     * Campos asignables en masa.
     *
     * @var array
     */
    protected $fillable = [
        'product_id',
        'url',          // Ruta o URL de la imagen
        'is_primary',   // Si es la imagen principal del producto
        'description'   // Descripción opcional
    ];

    /**
     * Relación con el producto al que pertenece la imagen.
     */
    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    /**
     * Accesor para obtener la URL completa de la imagen.
     */
    public function getFullUrlAttribute(): string
    {
        return config('app.url') . '/storage/' . $this->url;
    }
}

