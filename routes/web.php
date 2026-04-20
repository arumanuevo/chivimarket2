<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EspMessageController;
use Illuminate\Support\Str;
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Http\Request;
use App\Http\Controllers\DeviceController;
use App\Http\Controllers\PaymentController;


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


/*Route::get('/validate-device', function (Request $request) {
    $deviceId = $request->input('device_id');
    return view('validate-device', ['deviceId' => $deviceId]);
});*/

/*Route::post('/generate-token', function (Request $request) {
    $deviceId = $request->input('device_id');
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
});*/

//Route::post('/generate-token', [DeviceController::class, 'generateToken'])->middleware('check.temp.token');
//Route::post('/generate-token', [DeviceController::class, 'generateToken'])->middleware('check.temp.token');
Route::post('/generate-token', [DeviceController::class, 'generateToken']); 

Route::get('/create-payment', [PaymentController::class, 'createPayment'])->name('payment.create');
Route::get('/payment/success', [PaymentController::class, 'handleSuccess'])->name('payment.success');
Route::get('/payment/failure', [PaymentController::class, 'handleFailure'])->name('payment.failure');
Route::get('/payment/pending', [PaymentController::class, 'handlePending'])->name('payment.pending');
Route::post('/payment/webhook', [PaymentController::class, 'handleWebhook'])->name('payment.webhook');



