<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    use HasFactory;

    protected $fillable = [
        'promotion_id',
        'user_id',
        'code',
        'status', // 'claimed', 'redeemed', 'expired'
        'redeemed_at'
    ];

    protected $casts = [
        'redeemed_at' => 'datetime',
    ];

    public function promotion()
    {
        return $this->belongsTo(Promotion::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
