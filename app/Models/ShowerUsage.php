<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShowerUsage extends Model
{
    use HasFactory;

    protected $fillable = ['device_id', 'user_id', 'used_at'];

    protected $dates = ['used_at'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}