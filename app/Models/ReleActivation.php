<?php

// app/Models/ReleActivation.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ReleActivation extends Model
{
    protected $table = 'rele_activations';
    protected $primaryKey = 'id';
    public $timestamps = false; // Usamos `activated_at` en lugar de `created_at`

    protected $fillable = [
        'device_id',
        'token',
        'duration_seconds',
        'source_ip'
    ];

    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id', 'device_id');
    }
}
