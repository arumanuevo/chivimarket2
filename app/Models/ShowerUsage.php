<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShowerUsage extends Model
{
    use HasFactory;

    protected $table = 'shower_usages';

    protected $fillable = ['device_id', 'user_id', 'used_at', 'amount'];

    protected $dates = ['used_at'];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}