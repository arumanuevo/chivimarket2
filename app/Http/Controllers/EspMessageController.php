<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\EspMessage;

class EspMessageController extends Controller
{
    // Muestra el formulario para enviar mensajes
    public function create()
    {
        return view('send-to-esp32');
    }

    // Procesa el formulario y guarda el mensaje
    public function store(Request $request)
    {
        $validated = $request->validate([
            'message' => 'required|string|max:255',
            'color' => 'required|string|max:4',
        ]);

        // Guardar el mensaje en la base de datos
        EspMessage::create([
            'content' => $validated['message'],
            'color' => '0x' . $validated['color'],
        ]);

        return back()->with('success', '¡Mensaje enviado al ESP32 correctamente!');
    }
}

