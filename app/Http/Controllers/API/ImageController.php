<?php
// app/Http/Controllers/API/ImageController.php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Response;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

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
     *             mediaType="image/*",
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
        return $this->serveImage("business_covers/{$filename}");
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
     *             mediaType="image/*",
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
        return $this->serveImage("business_images/{$filename}");
    }

    /**
     * Sirve una imagen con los encabezados adecuados.
     */
    protected function serveImage($relativePath)
    {
        $path = public_path($relativePath);

        if (!file_exists($path)) {
            Log::warning('Imagen no encontrada', ['path' => $path]);
            abort(404, 'Imagen no encontrada');
        }

        // Determinar el tipo MIME de la imagen
        $mimeType = $this->getImageMimeType($path);

        // Obtener el tamaño del archivo
        $fileSize = filesize($path);

        // Crear una respuesta de archivo binario
        $response = Response::make(file_get_contents($path), 200);
        $response->header('Content-Type', $mimeType);
        $response->header('Content-Length', $fileSize);
        $response->header('Cache-Control', 'public, max-age=31536000');
        $response->header('Access-Control-Allow-Origin', '*');
        $response->header('Access-Control-Allow-Methods', 'GET');
        $response->header('Content-Disposition', 'inline; filename="' . basename($path) . '"');

        Log::info('Imagen servida correctamente', [
            'path' => $path,
            'mimeType' => $mimeType,
            'fileSize' => $fileSize
        ]);

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
            case 'svg':
                return 'image/svg+xml';
            default:
                // Intentar detectar el tipo MIME usando finfo
                $finfo = finfo_open(FILEINFO_MIME_TYPE);
                if ($finfo) {
                    $mime = finfo_file($finfo, $path);
                    finfo_close($finfo);
                    return $mime ?: 'image/png'; // Default si no se puede detectar
                }
                return 'image/png'; // Default
        }
    }
}
