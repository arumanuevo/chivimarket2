<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class ImageController extends Controller
{
    public function show($filename)
    {
        $path = public_path("business_covers/{$filename}");

        if (!file_exists($path)) {
            abort(404);
        }

        $file = file_get_contents($path);
        $response = response($file, 200);
        $response->header('Content-Type', 'image/png'); // Ajusta el tipo de contenido según el tipo de imagen
        $response->header('Cache-Control', 'public, max-age=31536000'); // Cachear la imagen por un año
        $response->header('Access-Control-Allow-Origin', '*'); // Permitir solicitudes desde cualquier origen

        return $response;
    }
}



