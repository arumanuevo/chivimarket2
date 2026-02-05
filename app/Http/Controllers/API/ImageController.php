<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller; // Importa la clase base Controller
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

        return response()->file($path);
    }
}


