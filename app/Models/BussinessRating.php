<?php

// app/Models/BusinessRating.php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BusinessRating extends Model
{
    protected $fillable = [
        'business_id',
        'user_id',
        'service_quality',
        'comment'
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

