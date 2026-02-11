<?php
// app/Models/ActivationLog.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActivationLog extends Model
{
    /**
     * Nombre de la tabla en la base de datos.
     */
    protected $table = 'activation_logs';

    /**
     * Clave primaria.
     */
    protected $primaryKey = 'id';

    /**
     * Campos que pueden ser asignados masivamente.
     */
    protected $fillable = [
        'device_id',
        'token',
        'duration_seconds',
        'source_ip',
        'status'
    ];

    /**
     * Campos que deben ser tratados como fechas.
     */
    protected $dates = ['activated_at'];

    /**
     * Relación con el dispositivo (ESP32).
     */
    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id', 'device_id');
    }

    /**
     * Alcance para activaciones recientes (últimas 24 horas).
     */
    public function scopeRecent($query)
    {
        return $query->where('activated_at', '>=', now()->subDay());
    }

    /**
     * Alcance para activaciones exitosas.
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }
}
