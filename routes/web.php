<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EspMessageController;
use Illuminate\Support\Str;
use App\Models\Device;
use App\Models\AccessToken;
use Illuminate\Http\Request;
use App\Http\Controllers\DeviceController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ShowerAdminController;

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
/*Route::get('/qr/{deviceId}/{tempToken}', function ($deviceId, $tempToken) {
    $url = url("/validate-device?device_id={$deviceId}&temp_token={$tempToken}");
    // Aquí debes generar el QR con la URL anterior.
    return response()->json(['url' => $url]);
});*/

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
//Route::post('/generate-token', [DeviceController::class, 'generateToken']); 

/*Route::get('/create-payment', [PaymentController::class, 'createPayment'])->name('payment.create');
Route::get('/payment/success', [PaymentController::class, 'handleSuccess'])->name('payment.success');
Route::get('/payment/failure', [PaymentController::class, 'handleFailure'])->name('payment.failure');
Route::get('/payment/pending', [PaymentController::class, 'handlePending'])->name('payment.pending');*/
//Route::post('/payment/webhook', [PaymentController::class, 'handleWebhook'])->name('payment.webhook');

// Rutas para el pago con Mercado Pago
Route::get('/create-payment', [PaymentController::class, 'createPayment'])->name('payment.create');
/*Route::get('/payment/success', [PaymentController::class, 'handleSuccess'])->name('payment.success');
Route::get('/payment/failure', [PaymentController::class, 'handleFailure'])->name('payment.failure');
Route::get('/payment/pending', [PaymentController::class, 'handlePending'])->name('payment.pending');*/

Route::get('/payment/success', [PaymentController::class, 'handleSuccess'])->name('payment.success');
Route::get('/payment/failure', [PaymentController::class, 'handleFailure'])->name('payment.failure');
Route::get('/payment/pending', [PaymentController::class, 'handlePending'])->name('payment.pending');

Route::post('/create-preference', [PaymentController::class, 'createPreference'])->name('create.preference');

// Ruta para mostrar la vista de nueva transacción
Route::get('/nueva-transaccion', [PaymentController::class, 'showNewTransaction'])->name('nueva.transaccion');
/*_____________________testing mercado pago_____________________________________*/

Route::get('/test-payment', [PaymentController::class, 'showTestPayment'])->name('test.payment');
Route::post('/create-test-preference', [PaymentController::class, 'createTestPreference'])->name('create.test.preference');
Route::get('/test-payment-success', [PaymentController::class, 'handleTestPaymentSuccess'])->name('test.payment.success');
Route::get('/test-payment-failure', [PaymentController::class, 'handleTestPaymentFailure'])->name('test.payment.failure');
Route::get('/test-payment-pending', [PaymentController::class, 'handleTestPaymentPending'])->name('test.payment.pending');


Route::get('/test-connection', [PaymentController::class, 'testConnection'])->name('test.connection');

Route::get('/test-sdk', [PaymentController::class, 'testSDK'])->name('test.sdk');

Route::get('/simple-payment', [PaymentController::class, 'showSimplePayment'])->name('simple.payment');

Route::post('/create-simple-preference', [PaymentController::class, 'createSimplePreference'])->name('create.simple.preference');

//Route::get('/simple-payment-success', [PaymentController::class, 'handleSimplePaymentSuccess'])->name('simple.payment.success');
Route::get('/simple-payment-failure', [PaymentController::class, 'handleSimplePaymentFailure'])->name('simple.payment.failure');
Route::get('/simple-payment-pending', [PaymentController::class, 'handleSimplePaymentPending'])->name('simple.payment.pending');
//Route::post('/simple-payment-success', [PaymentController::class, 'handleWebhook'])->name('payment.webhook');
Route::post('/payment/webhook', [PaymentController::class, 'handleWebhook'])->name('payment.webhook');
Route::get('/simple-payment-success', [PaymentController::class, 'handleSimplePaymentSuccess'])->name('simple.payment.success');
// Pago exitoso
Route::get('/pago-exitoso', function (Request $request) {
    return view('pago-exitoso');
})->name('pago.exitoso');

// Pago fallido
Route::get('/pago-fallido', function (Request $request) {
    return view('pago-fallido');
})->name('pago.fallido');

// Pago pendiente
Route::get('/pago-pendiente', function (Request $request) {
    return view('pago-pendiente');
})->name('pago.pendiente');

Route::get('/session-completed', function () {
    return view('session-completed');
})->name('session.completed');

Route::get('/shower-admin', function () {
    return view('shower-admin');
})->middleware('auth:sanctum')->name('shower.admin');

Route::post('/shower-admin/login', [ShowerAdminController::class, 'login']);