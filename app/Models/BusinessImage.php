<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BusinessImage extends Model
{
    use HasFactory;

    /**
     * Campos asignables en masa.
     *
     * @var array
     */
    protected $fillable = [
        'business_id',
        'url',          // Ruta o URL de la imagen
        'is_primary',   // Si es la imagen principal del negocio
        'description'   // Descripción opcional
    ];

    /**
     * Relación con el negocio al que pertenece la imagen.
     */
    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    /**
     * Accesor para obtener la URL completa de la imagen.
     * Útil si las imágenes se almacenan en un servicio como S3.
     */
    public function getFullUrlAttribute()
    {
        if (strpos($this->url, 'http') === 0) {
            return $this->url; // Si ya es una URL completa, devolverla tal cual
        }

        return rtrim(env('APP_URL'), '/') . '/' . ltrim($this->url, '/');
    }


    public function scopePrimary($query)
    {
        return $query->where('is_primary', true);
    }
   
    

}
