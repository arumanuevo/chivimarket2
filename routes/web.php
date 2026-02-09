<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EspMessageController;

Route::get('/', function () {
    return view('welcome');
});

/*Route::get('/send-to-esp32', function () {
    return view('send-to-esp32');
});
Route::post('/send-to-esp32', function (Request $request) {
    // Guardar el mensaje en la base de datos
    \App\Models\EspMessage::create([
        'content' => $request->input('message'),
        'color' => $request->input('color', '0x07FF')
    ]);

    return back()->with('success', 'Mensaje enviado al ESP32');
});*/

// Ruta para mostrar el formulario
Route::get('/send-to-esp32', [EspMessageController::class, 'create'])->name('send-to-esp32.form');

// Ruta para procesar el formulario
Route::post('/send-to-esp32', [EspMessageController::class, 'store'])->name('send-to-esp32');
