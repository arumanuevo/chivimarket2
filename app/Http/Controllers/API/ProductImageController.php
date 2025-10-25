<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

/**
 * @OA\Tag(
 *     name="ProductImages",
 *     description="API para gestionar imágenes de productos"
 * )
 */
class ProductImageController extends Controller
{
    use AuthorizesRequests;

    /**
     * @OA\Post(
     *     path="/api/products/{product}/images",
     *     summary="Subir una imagen para un producto",
     *     description="Sube una imagen y la asocia a un producto. Solo el dueño del negocio puede subir imágenes.",
     *     tags={"ProductImages"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         description="Imagen a subir (form-data)",
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 required={"image"},
     *                 @OA\Property(property="image", type="string", format="binary", description="Archivo de imagen"),
     *                 @OA\Property(property="is_primary", type="boolean", description="Si es la imagen principal", example=false),
     *                 @OA\Property(property="description", type="string", description="Descripción de la imagen", example="Foto del producto desde el frente")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Imagen subida correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/ProductImage")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para subir imágenes a este producto"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación (ej: archivo no es una imagen)"
     *     )
     * )
     */
    public function store(Request $request, Product $product)
{
    \Log::info('Solicitud para subir imagen de producto', [
        'product_id' => $product->id,
        'request_all' => $request->all(),
        'has_file' => $request->hasFile('image'),
        'is_primary_raw' => $request->is_primary,
    ]);

    $this->authorize('update', $product->business);

    // Convertir is_primary a booleano explícitamente
    $isPrimary = filter_var($request->is_primary, FILTER_VALIDATE_BOOLEAN);

    $validator = Validator::make($request->all(), [
        'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        'is_primary' => 'boolean',
        'description' => 'nullable|string|max:255'
    ]);

    // 👇 Usar el valor convertido en la validación
    $validator->after(function ($validator) use ($isPrimary) {
        if ($validator->errors()->has('is_primary')) {
            $validator->errors()->forget('is_primary');
        }
    });

    if ($validator->fails()) {
        \Log::error('Errores de validación:', $validator->errors()->toArray());
        return response()->json([
            'message' => 'Error de validación',
            'errors' => $validator->errors()
        ], 422);
    }

    try {
        $path = $request->file('image')->store('product_images', 'public');

        // Usar el valor booleano convertido
        if ($isPrimary) {
            $product->images()->update(['is_primary' => false]);
        }

        $image = $product->images()->create([
            'url' => $path,
            'is_primary' => $isPrimary,
            'description' => $request->description
        ]);

        return response()->json([
            'message' => 'Imagen subida correctamente',
            'image' => $image
        ], 201);

    } catch (\Exception $e) {
        \Log::error('Error al subir imagen:', [
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        return response()->json([
            'message' => 'Error al procesar la imagen',
            'error' => $e->getMessage()
        ], 500);
    }
}
    /**
     * @OA\Get(
     *     path="/api/products/{product}/images",
     *     summary="Listar imágenes de un producto",
     *     description="Devuelve todas las imágenes asociadas a un producto.",
     *     tags={"ProductImages"},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Lista de imágenes del producto",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/ProductImage"))
     *     )
     * )
     */
    public function index(Product $product)
    {
        return response()->json($product->images);
    }

    /**
     * @OA\Delete(
     *     path="/api/products/{product}/images/{image}",
     *     summary="Eliminar una imagen de un producto",
     *     description="Elimina una imagen específica de un producto. Solo el dueño del negocio puede hacerlo.",
     *     tags={"ProductImages"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="image",
     *         in="path",
     *         required=true,
     *         description="ID de la imagen",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Imagen eliminada correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Imagen eliminada correctamente")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para eliminar esta imagen"
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Imagen no encontrada"
     *     )
     * )
     */
    public function destroy(Product $product, ProductImage $image)
    {
        $this->authorize('update', $product->business); // Verificar que el usuario sea dueño del negocio

        // Eliminar la imagen del storage
        Storage::disk('public')->delete($image->url);

        // Eliminar el registro de la base de datos
        $image->delete();

        return response()->json(['message' => 'Imagen eliminada correctamente']);
    }

    /**
     * @OA\Patch(
     *     path="/api/products/{product}/images/{image}/set-primary",
     *     summary="Establecer una imagen como principal",
     *     description="Marca una imagen como la principal del producto. Solo el dueño del negocio puede hacerlo.",
     *     tags={"ProductImages"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="product",
     *         in="path",
     *         required=true,
     *         description="ID del producto",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="image",
     *         in="path",
     *         required=true,
     *         description="ID de la imagen",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Imagen establecida como principal",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Imagen principal actualizada correctamente"),
     *             @OA\Property(property="image", type="object", ref="#/components/schemas/ProductImage")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para modificar este producto"
     *     )
     * )
     */
    public function setPrimary(Product $product, ProductImage $image)
    {
        $this->authorize('update', $product->business);

        // Desmarcar todas las imágenes como principales
        $product->images()->update(['is_primary' => false]);

        // Marcar la imagen seleccionada como principal
        $image->update(['is_primary' => true]);

        return response()->json([
            'message' => 'Imagen principal actualizada correctamente',
            'image' => $image->fresh()
        ]);
    }
}
