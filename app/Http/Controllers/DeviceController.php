<?php

// app/Http/Controllers/DeviceController.php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Support\Str;

class DeviceController extends Controller
{
    /**
     * Muestra el formulario para validar un dispositivo.
     */
    public function validateDevice(Request $request)
{
    $deviceId = $request->input('device_id');
    $esp32Ip = $request->input('esp32_ip', '');  // Leer la IP del QR

    $device = Device::firstOrCreate(
        ['device_id' => $deviceId],
        ['name' => 'Dispositivo ' . substr($deviceId, -4)]
    );

    return view('validate-device', [
        'deviceId' => $deviceId,
        'esp32Ip' => $esp32Ip  // Pasar la IP a la vista
    ]);
}
    /**
     * Genera un token de acceso para el dispositivo.
     */
    public function generateToken(Request $request)
{
    $deviceId = $request->input('device_id');
    $esp32Ip = $request->input('esp32_ip', '');  // Obtener la IP del QR

    $token = Str::random(16);
    AccessToken::create([
        'device_id' => $deviceId,
        'token' => $token,
        'expires_at' => now()->addMinutes(5)
    ]);

    return view('token', [
        'deviceId' => $deviceId,
        'token' => $token,
        'esp32Ip' => $esp32Ip  // Pasar la IP a la vista
    ]);
}

    /**
     * Muestra el formulario para activar el relé.
     */
    public function showActivateForm(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');
        $device = Device::where('device_id', $deviceId)->firstOrFail();
        return view('activate-ducha', [
            'deviceId' => $deviceId,
            'tempToken' => $tempToken,
            'esp32Ip' => $request->ip()
        ]);
    }

    /**
     * Valida la activación del relé (API).
     */
    public function validateActivation(Request $request)
    {
        $request->validate([
            'device_id' => 'required|string',
            'token' => 'required|string',
            'temp_token' => 'required|string'
        ]);

        $device = Device::where('device_id', $request->device_id)->first();
        if (!$device) {
            return response()->json(['status' => 'error', 'message' => 'Dispositivo no encontrado'], 404);
        }

        if (!Str::startsWith($request->token, 'PAY_')) {
            return response()->json(['status' => 'error', 'message' => 'Token de pago inválido'], 403);
        }

        ActivationLog::create([
            'device_id' => $request->device_id,
            'token' => $request->token,
            'duration_seconds' => 10,
            'source_ip' => $request->ip(),
            'status' => 'completed'
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Relé activado por 10 segundos'
        ]);
    }
}
