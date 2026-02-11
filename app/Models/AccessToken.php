<?php

// app/Models/AccessToken.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AccessToken extends Model
{
    protected $table = 'access_tokens';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'device_id',
        'token',
        'expires_at',
        'used'
    ];

    protected $dates = ['expires_at'];

    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id', 'device_id');
    }
}
