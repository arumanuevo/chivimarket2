<?php

// app/Http/Controllers/DeviceController.php
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Support\Str;

class DeviceController extends Controller
{
    public function validateDevice(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        // Verificar si el dispositivo existe
        $device = Device::firstOrCreate(
            ['device_id' => $deviceId],
            ['name' => 'Dispositivo ' . substr($deviceId, -4)]
        );

        return view('validate-device', [
            'deviceId' => $deviceId,
            'tempToken' => $tempToken
        ]);
    }

    public function generateToken(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

        // Validar que el temp_token no esté vacío
        if (empty($tempToken)) {
            return back()->with('error', 'El código QR ha caducado. Escanea el QR nuevamente.');
        }

        // Generar un token de acceso único
        $token = Str::random(16);
        AccessToken::create([
            'device_id' => $deviceId,
            'token' => $token,
            'expires_at' => now()->addMinutes(5),
            'used' => false
        ]);

        return view('token-generated', [
            'deviceId' => $deviceId,
            'token' => $token
        ]);
    }
}
