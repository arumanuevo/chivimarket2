<?php
namespace App\Http\Controllers;

use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Session;

class DeviceController extends Controller
{
    public function validateDevice(Request $request)
    {
        $deviceId = $request->input('device_id');
        $tempToken = $request->input('temp_token');

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

   // app/Http/Controllers/DeviceController.php
   public function generateToken(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');

    // Verificar si el temp_token ya fue usado en esta sesión
    if (Session::has('used_temp_token_' . $tempToken)) {
        return back()->with('error', 'El código QR ya ha sido usado. Escanea el QR nuevamente.');
    }

    if (empty($tempToken)) {
        return back()->with('error', 'El código QR ha caducado. Escanea el QR nuevamente.');
    }

    // Marcar el temp_token como usado en esta sesión
    Session::put('used_temp_token_' . $tempToken, true);

    $token = Str::random(16);
    AccessToken::create([
        'device_id' => $deviceId,
        'token' => $token,
        'expires_at' => now()->addMinutes(5),
        'used' => true  // Marcamos el token como usado inmediatamente
    ]);

    return view('token-generated', [
        'deviceId' => $deviceId,
        'token' => $token,
        'tempToken' => $tempToken
    ]);
}
}
