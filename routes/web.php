<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EspMessageController;
use Illuminate\Support\Str;
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Http\Request;
use App\Http\Controllers\DeviceController;

// Ruta principal (welcome)
Route::get('/', function () {
    return view('welcome');
});

// Rutas para el formulario de mensajes al ESP32
Route::get('/send-to-esp32', [EspMessageController::class, 'create'])->name('send-to-esp32.form');
Route::post('/send-to-esp32', [EspMessageController::class, 'store'])->name('send-to-esp32');


// Ruta para generar un QR (opcional, si decides usarla)
Route::get('/qr/{token}', function ($token) {
    // Lógica para generar el QR (usando SimpleSoftwareIO/qr-code)
    // Ejemplo: return QrCode::size(200)->generate("ESP32-ACTIVATE:{$token}");
    return response()->json(['qr' => "QR para token: {$token}"]);
});

Route::get('/validate-device', [DeviceController::class, 'validateDevice']);
Route::post('/generate-token', [DeviceController::class, 'generateToken']);
Route::get('/activate', [DeviceController::class, 'showActivateForm']);


