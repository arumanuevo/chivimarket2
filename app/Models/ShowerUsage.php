<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShowerUsage extends Model
{
    use HasFactory;

    protected $fillable = ['device_id', 'used_at'];
}