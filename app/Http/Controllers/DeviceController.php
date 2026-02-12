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
    // app/Http/Controllers/DeviceController.php
    public function validateDevice(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');  // Asegúrate de que este parámetro se esté recibiendo

    if (empty($tempToken)) {
        return view('validate-device', [
            'deviceId' => $deviceId,
            'error' => 'El código QR ha caducado. Escanea el QR nuevamente.'
        ]);
    }

    $device = Device::firstOrCreate(
        ['device_id' => $deviceId],
        ['name' => 'Dispositivo ' . substr($deviceId, -4)]
    );

    return view('validate-device', [
        'deviceId' => $deviceId,
        'tempToken' => $tempToken
    ]);
}

    /**
     * Genera un token de acceso para el dispositivo.
     */
    public function generateToken(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');
    
        // Validar que el temp_token no esté vacío
        if (empty($tempToken)) {
            return back()->with('error', 'El código QR ha caducado. Escanea el QR nuevamente.');
        }
    
        // Aquí podrías validar el temp_token contra el último generado por el ESP32.
        // Por ahora, asumimos que es válido si no está vacío.
    
        $token = Str::random(16);
        AccessToken::create([
            'device_id' => $deviceId,
            'token' => $token,
            'expires_at' => now()->addMinutes(5)
        ]);
    
        return view('token-generated', [
            'deviceId' => $deviceId,
            'token' => $token
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
