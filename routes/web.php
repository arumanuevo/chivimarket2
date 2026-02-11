<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EspMessageController;
use Illuminate\Support\Str;
use App\Models\Device;
use App\Models\AccessToken;

// Ruta principal (welcome)
Route::get('/', function () {
    return view('welcome');
});

// Rutas para el formulario de mensajes al ESP32
Route::get('/send-to-esp32', [EspMessageController::class, 'create'])->name('send-to-esp32.form');
Route::post('/send-to-esp32', [EspMessageController::class, 'store'])->name('send-to-esp32');

// Rutas para el flujo de activación del relé
Route::get('/validate-device', function (Request $request) {
    $deviceId = $request->input('device_id');
    $device = Device::firstOrCreate(
        ['device_id' => $deviceId],
        ['name' => 'Dispositivo ' . substr($deviceId, -4)]
    );
    return view('validate-device', ['deviceId' => $deviceId]);
});

Route::post('/generate-token', function (Request $request) {
    $deviceId = $request->input('device_id');
    $token = Str::random(16);
    AccessToken::create([
        'device_id' => $deviceId,
        'token' => $token,
        'expires_at' => now()->addMinutes(5)
    ]);
    return view('token', ['deviceId' => $deviceId, 'token' => $token]);
});

Route::get('/activate', function (Request $request) {
    $deviceId = $request->input('device_id');
    $tempToken = $request->input('temp_token');
    $device = Device::where('device_id', $deviceId)->firstOrFail();
    return view('activate-ducha', [
        'deviceId' => $deviceId,
        'tempToken' => $tempToken,
        'esp32Ip' => $request->ip()
    ]);
});

// Ruta para generar un QR (opcional, si decides usarla)
Route::get('/qr/{token}', function ($token) {
    // Lógica para generar el QR (usando SimpleSoftwareIO/qr-code)
    // Ejemplo: return QrCode::size(200)->generate("ESP32-ACTIVATE:{$token}");
    return response()->json(['qr' => "QR para token: {$token}"]);
});


