<?php
namespace App\Http\Controllers;

use App\Models\Device;
use App\Models\AccessToken;
use App\Models\ShowerUsage;
use App\Models\ShowerPrice;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Facades\Log;

class DeviceController extends Controller
{
    public function validateDevice(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');

    Log::info("validateDevice: device_id = " . $deviceId);
    Log::info("validateDevice: temp_token = " . $tempToken);

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
   // app/Http/Controllers/DeviceController.php
/*public function generateToken(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');

    \Log::info("GenerateToken: device_id = " . $deviceId . ", temp_token = " . $tempToken);

    if (empty($tempToken)) {
        return back()->with('error', 'El código QR ha caducado. Escanea el QR nuevamente.');
    }

    if (Session::has('used_temp_token_' . $tempToken)) {
        return back()->with('error', 'El código QR ya ha sido usado. Escanea el QR nuevamente.');
    }

    Session::put('used_temp_token_' . $tempToken, true);

    $token = Str::random(16);
    $accessToken = AccessToken::create([
        'device_id' => $deviceId,
        'token' => $token,
        'expires_at' => now()->addMinutes(5),
        'used' => false
    ]);

    \Log::info("GenerateToken: Token guardado en la base de datos, ID = " . $accessToken->id . ", token = " . $accessToken->token);

    return view('token-generated', [
        'deviceId' => $deviceId,
        'token' => $token,
        'tempToken' => $tempToken
    ]);
}*/

/*public function generateToken(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');

    \Log::info("GenerateToken: device_id = " . $deviceId . ", temp_token = " . $tempToken);

    if (empty($tempToken)) {
        return back()->with('error', 'El código QR ha caducado. Escanea el QR nuevamente.');
    }

    if (Session::has('used_temp_token_' . $tempToken)) {
        return back()->with('error', 'El código QR ya ha sido usado. Escanea el QR nuevamente.');
    }

    Session::put('used_temp_token_' . $tempToken, true);

    $token = Str::random(16);
    $accessToken = AccessToken::create([
        'device_id' => $deviceId,
        'token' => $token,
        'expires_at' => now()->addMinutes(5),
        'used' => false
    ]);

    \Log::info("GenerateToken: Token guardado en la base de datos, ID = " . $accessToken->id . ", token = " . $accessToken->token);

    return view('token-generated', [
        'deviceId' => $deviceId,
        'token' => $token,
        'tempToken' => $tempToken
    ]);
}*/

public function generateToken(Request $request)
{
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');

    \Log::info("GenerateToken: device_id = " . $deviceId . ", temp_token = " . $tempToken);

    if (empty($tempToken)) {
        return back()->with('error', 'El código QR ha caducado. Escanea el QR nuevamente.');
    }

    // Generar un nuevo token único para esta sesión
    $token = Str::random(16);

    // Crear un nuevo token de acceso
    $accessToken = AccessToken::create([
        'device_id' => $deviceId,
        'token' => $token,
        'expires_at' => now()->addMinutes(5),
        'used' => false
    ]);

    \Log::info("GenerateToken: Token guardado en la base de datos, ID = " . $accessToken->id . ", token = " . $accessToken->token);

    // Obtener el precio actual de la tabla shower_prices
    try {
        $price = ShowerPrice::latest()->first()->price;
    } catch (\Exception $e) {
        \Log::error("Error al obtener el precio: " . $e->getMessage());
        $price = 2.00; // Valor por defecto si no se puede obtener el precio
    }

    // Registrar el uso del dispositivo
    ShowerUsage::create([
        'device_id' => $deviceId,
        'user_id' => auth()->check() ? auth()->id() : null,
        'used_at' => now(),
        'amount' => $price,
        'water_consumption' => 50.00 // Consumo de agua estimado en litros
    ]);

    return view('token-generated', [
        'deviceId' => $deviceId,
        'token' => $token,
        'tempToken' => $tempToken
    ]);
}
}
