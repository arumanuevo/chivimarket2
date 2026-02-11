<?php
// app/Models/Device.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Device extends Model
{
    protected $table = 'devices';
    protected $primaryKey = 'id';
    public $timestamps = true;

    protected $fillable = [
        'device_id',
        'name',
        'location'
    ];

    /**
     * Relación con los logs de activación.
     */
    public function activationLogs()
    {
        return $this->hasMany(ActivationLog::class, 'device_id', 'device_id');
    }
}
