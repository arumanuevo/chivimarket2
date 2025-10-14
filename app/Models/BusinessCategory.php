<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class BusinessCategory extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description'];

    /**
     * Relación muchos-a-muchos con negocios.
     */
    public function businesses(): BelongsToMany
    {
        return $this->belongsToMany(
            Business::class,
            'business_category', // Nombre exacto de la tabla pivote
            'category_id',      // Clave foránea de este modelo
            'business_id'       // Clave foránea del modelo Business
        );
    }
}

