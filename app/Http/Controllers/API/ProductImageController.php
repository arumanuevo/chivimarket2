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
        $this->authorize('update', $product->business); // Verificar que el usuario sea dueño del negocio

        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048', // Máx. 2MB
            'is_primary' => 'boolean',
            'description' => 'nullable|string|max:255'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Subir la imagen al storage
        $path = $request->file('image')->store('product_images', 'public');

        // Crear el registro en la base de datos
        $image = $product->images()->create([
            'url' => $path,
            'is_primary' => $request->is_primary ?? false,
            'description' => $request->description
        ]);

        return response()->json($image, 201);
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
