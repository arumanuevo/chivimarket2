<?php

// app/Models/TokenUse.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TokenUse extends Model
{
    protected $fillable = [
        'token_id', 'used_by', 'used_at',
        'business_confirmation_code', 'confirmed_at'
    ];

    protected $casts = [
        'used_at' => 'datetime',
        'confirmed_at' => 'datetime'
    ];

    public function token(): BelongsTo
    {
        return $this->belongsTo(DiscountToken::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'used_by');
    }

    /**
     * Genera un código de confirmación para el negocio.
     */
    public function generateConfirmationCode(): string
    {
        $code = strtoupper(substr(md5(uniqid(rand(), true)), 0, 8));
        $this->update([
            'business_confirmation_code' => $code,
            'confirmed_at' => now()
        ]);
        return $code;
    }
}

