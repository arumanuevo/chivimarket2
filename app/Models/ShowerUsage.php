<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShowerUsage extends Model
{
    use HasFactory;

    protected $fillable = ['device_id', 'used_at', 'amount', 'water_consumption'];

    protected $attributes = [
        'amount' => 0.00,
        'water_consumption' => 0.00,
    ];
}