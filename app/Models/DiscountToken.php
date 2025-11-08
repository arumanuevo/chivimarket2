<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DiscountToken extends Model
{
    protected $fillable = [
        'code', 'business_id', 'product_id', 'user_id',
        'discount_type', 'discount_value', 'min_purchase',
        'max_uses', 'valid_from', 'valid_until', 'description', 'is_active'
    ];

    protected $casts = [
        'valid_from' => 'datetime',
        'valid_until' => 'datetime',
        'is_active' => 'boolean'
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function uses()
    {
        return $this->hasMany(TokenUse::class);
    }

    /**
     * Genera un código único para el token.
     */
    public static function generateCode(): string
    {
        return strtoupper(
            substr(md5(uniqid(rand(), true)), 0, 4) . '-' .
            substr(md5(uniqid(rand(), true)), 4, 4)
        );
    }

    /**
     * Verifica si el token es válido.
     */
    public function isValid(): bool
    {
        return $this->is_active &&
               $this->valid_from <= now() &&
               $this->valid_until >= now() &&
               ($this->max_uses == 0 || $this->uses_count < $this->max_uses);
    }

    /**
     * Incrementa el contador de usos.
     */
    public function useToken(?User $user = null): bool
    {
        if (!$this->isValid()) {
            return false;
        }

        $this->increment('uses_count');
        $this->save();

        TokenUse::create([
            'token_id' => $this->id,
            'used_by' => $user?->id,
            'used_at' => now()
        ]);

        return true;
    }
}

