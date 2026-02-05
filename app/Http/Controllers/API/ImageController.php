<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/**
 * @OA\Tag(
 *     name="Imágenes",
 *     description="Endpoints relacionados con la gestión de imágenes de negocios."
 * )
 */
class ImageController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/image/{filename}",
     *     summary="Obtener imagen de portada de un negocio",
     *     description="Devuelve la imagen de portada de un negocio en formato binario. El nombre del archivo debe coincidir con el almacenado en el campo `cover_image_url` del negocio.",
     *     tags={"Imágenes"},
     *     @OA\Parameter(
     *         name="filename",
     *         in="path",
     *         required=true,
     *         description="Nombre del archivo de la imagen de portada (ej: '698397b188896.png').",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Imagen de portada del negocio en formato binario (PNG, JPEG, etc.).",
     *         @OA\MediaType(
     *             mediaType="image/png",
     *             @OA\Schema(type="string", format="binary")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Imagen no encontrada."
     *     )
     * )
     */
    public function show($filename)
    {
        $path = public_path("business_covers/{$filename}");

        if (!file_exists($path)) {
            abort(404);
        }

        $file = file_get_contents($path);
        $response = response($file, 200);
        $response->header('Content-Type', 'image/png');
        $response->header('Cache-Control', 'public, max-age=31536000');
        $response->header('Access-Control-Allow-Origin', '*');

        return $response;
    }
}

