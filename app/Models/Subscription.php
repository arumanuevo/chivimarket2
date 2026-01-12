<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'type', 'product_limit', 'starts_at', 'ends_at', 'is_active', 'status'
    ];
    
    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'is_active' => 'boolean'
    ];
    

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    // Accessor para capitalizar el tipo de suscripción
    public function getFormattedTypeAttribute(): string
    {
        return ucfirst($this->type);
    }

    // Accessor para formatear la fecha de inicio
    public function getFormattedStartsAtAttribute(): string
    {
        return $this->starts_at ? $this->starts_at->format('d-m-Y') : '-';
    }

    // Accessor para formatear la fecha de finalización
    public function getFormattedEndsAtAttribute(): string
    {
        return $this->ends_at ? $this->ends_at->format('d-m-Y') : '-';
    }
}
