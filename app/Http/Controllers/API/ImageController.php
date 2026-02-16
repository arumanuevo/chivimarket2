<?php
// app/Http/Controllers/API/ImageController.php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

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
     *     description="Devuelve la imagen de portada de un negocio en formato binario.",
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

    /**
     * @OA\Get(
     *     path="/api/business-image/{filename}",
     *     summary="Obtener imagen de un negocio",
     *     description="Devuelve una imagen específica de un negocio en formato binario. El nombre del archivo debe coincidir con el almacenado en el campo `url` de la tabla `business_images`.",
     *     tags={"Imágenes"},
     *     @OA\Parameter(
     *         name="filename",
     *         in="path",
     *         required=true,
     *         description="Nombre del archivo de la imagen (ej: '69923fe433fd8.png').",
     *         @OA\Schema(type="string")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Imagen del negocio en formato binario (PNG, JPEG, etc.).",
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
    public function showBusinessImage($filename)
    {
        Log::info('Solicitud de imagen de negocio', ['filename' => $filename]);

        $path = public_path("business_images/{$filename}");

        if (!file_exists($path)) {
            Log::warning('Imagen no encontrada', ['filename' => $filename, 'path' => $path]);
            abort(404);
        }

        // Determinar el tipo MIME de la imagen
        $mimeType = $this->getImageMimeType($path);

        $file = file_get_contents($path);
        $response = response($file, 200);
        $response->header('Content-Type', $mimeType);
        $response->header('Cache-Control', 'public, max-age=31536000');
        $response->header('Access-Control-Allow-Origin', '*');

        Log::info('Imagen servida correctamente', ['filename' => $filename, 'mimeType' => $mimeType]);

        return $response;
    }

    /**
     * Determina el tipo MIME de una imagen a partir de su ruta.
     */
    protected function getImageMimeType($path)
    {
        $extension = strtolower(pathinfo($path, PATHINFO_EXTENSION));

        switch ($extension) {
            case 'jpg':
            case 'jpeg':
                return 'image/jpeg';
            case 'png':
                return 'image/png';
            case 'gif':
                return 'image/gif';
            case 'webp':
                return 'image/webp';
            default:
                return 'image/png'; // Default
        }
    }
}
