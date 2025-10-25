<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\BusinessImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class BusinessImageController extends Controller
{
    use AuthorizesRequests;

    /**
     * @OA\Post(
     *     path="/api/businesses/{business}/images",
     *     summary="Subir una imagen para un negocio",
     *     description="Sube una imagen asociada a un negocio específico. Solo el dueño del negocio puede subir imágenes. Si se marca como principal, se desmarcará automáticamente la imagen principal actual.",
     *     tags={"Imágenes de Negocio"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         description="Imagen y datos adicionales",
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 required={"image"},
     *                 @OA\Property(property="image", type="string", format="binary", description="Archivo de imagen (JPEG, PNG, JPG, GIF)"),
     *                 @OA\Property(property="is_primary", type="boolean", description="Indica si la imagen es la principal del negocio", example=false),
     *                 @OA\Property(property="description", type="string", description="Descripción opcional de la imagen", example="Fachada de la panadería")
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Imagen subida correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/BusinessImage")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para subir imágenes a este negocio"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function store(Request $request, Business $business)
    {
        $this->authorize('update', $business);

        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:1024',
            'is_primary' => 'boolean',
            'description' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Si se marca como principal, desmarcar la actual
        if ($request->has('is_primary') && filter_var($request->is_primary, FILTER_VALIDATE_BOOLEAN)) {
            BusinessImage::where('business_id', $business->id)
                ->where('is_primary', true)
                ->update(['is_primary' => false]);
        }

        // Guardar la imagen en public/business_images
        $imageFile = $request->file('image');
        $filename = uniqid() . '.' . $imageFile->getClientOriginalExtension();
        $imageFile->move(public_path('business_images'), $filename);

        $image = $business->images()->create([
            'url' => 'business_images/' . $filename,
            'is_primary' => $request->has('is_primary') ? filter_var($request->is_primary, FILTER_VALIDATE_BOOLEAN) : false,
            'description' => $request->description
        ]);

        return response()->json($image, 201);
    }

    /**
     * @OA\Delete(
     *     path="/api/businesses/{business}/images/{image}",
     *     summary="Eliminar una imagen de un negocio",
     *     description="Elimina una imagen específica de un negocio. Solo el dueño del negocio puede eliminar imágenes. Si la imagen eliminada era la principal, se asignará automáticamente otra imagen como principal (si existe).",
     *     tags={"Imágenes de Negocio"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
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
     *         description="No autorizado para eliminar imágenes de este negocio"
     *     )
     * )
     */
    public function destroy(Business $business, BusinessImage $image)
    {
        $this->authorize('update', $business);

        // Si es la imagen principal, asignar otra como principal (si existe)
        if ($image->is_primary) {
            $newPrimary = BusinessImage::where('business_id', $business->id)
                ->where('id', '!=', $image->id)
                ->first();
            if ($newPrimary) {
                $newPrimary->update(['is_primary' => true]);
            }
        }

        // Eliminar la imagen del directorio public/business_images
        $imagePath = public_path($image->url);
        if (file_exists($imagePath)) {
            unlink($imagePath);
        }

        // Eliminar el registro de la base de datos
        $image->delete();

        return response()->json(['message' => 'Imagen eliminada correctamente']);
    }

    /**
     * @OA\Patch(
     *     path="/api/businesses/{business}/images/{image}",
     *     summary="Actualizar una imagen de un negocio",
     *     description="Actualiza la descripción o el estado de principal de una imagen específica de un negocio. Solo el dueño del negocio puede actualizar imágenes. Si se marca como principal, se desmarcará automáticamente la imagen principal actual.",
     *     tags={"Imágenes de Negocio"},
     *     security={{"bearerAuth": {}}},
     *     @OA\Parameter(
     *         name="business",
     *         in="path",
     *         required=true,
     *         description="ID del negocio",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Parameter(
     *         name="image",
     *         in="path",
     *         required=true,
     *         description="ID de la imagen",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="is_primary", type="boolean", description="Indica si la imagen debe ser la principal", example=true),
     *             @OA\Property(property="description", type="string", description="Nueva descripción de la imagen", example="Fachada renovada de la panadería")
     *         )
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Imagen actualizada correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/BusinessImage")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado para actualizar imágenes de este negocio"
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
    public function update(Request $request, Business $business, BusinessImage $image)
{
    $this->authorize('update', $business);

    $validator = Validator::make($request->all(), [
        'is_primary' => 'boolean',
        'description' => 'nullable|string'
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    // Si se marca como principal, desmarcar la actual
    if ($request->has('is_primary') && filter_var($request->is_primary, FILTER_VALIDATE_BOOLEAN)) {
        BusinessImage::where('business_id', $business->id)
            ->where('id', '!=', $image->id)
            ->update(['is_primary' => false]);
    }

    $image->update([
        'is_primary' => $request->has('is_primary') ? filter_var($request->is_primary, FILTER_VALIDATE_BOOLEAN) : $image->is_primary,
        'description' => $request->description ?? $image->description
    ]);

    return response()->json($image);
}

/**
 * @OA\Patch(
 *     path="/api/businesses/{business}/images/reset-primary",
 *     summary="Restablecer imágenes principales de un negocio",
 *     description="Restablece todas las imágenes de un negocio para que ninguna sea principal. Solo el dueño del negocio puede realizar esta acción.",
 *     tags={"Imágenes de Negocio"},
 *     security={{"bearerAuth": {}}},
 *     @OA\Parameter(
 *         name="business",
 *         in="path",
 *         required=true,
 *         description="ID del negocio",
 *         @OA\Schema(type="integer")
 *     ),
 *     @OA\Response(
 *         response=200,
 *         description="Imágenes restablecidas correctamente",
 *         @OA\JsonContent(
 *             type="object",
 *             @OA\Property(property="message", type="string", example="Imágenes restablecidas")
 *         )
 *     ),
 *     @OA\Response(
 *         response=403,
 *         description="No autorizado para restablecer imágenes de este negocio"
 *     )
 * )
 */
public function resetPrimary(Business $business)
{
    $this->authorize('update', $business);
    BusinessImage::where('business_id', $business->id)->update(['is_primary' => false]);
    return response()->json(['message' => 'Imágenes restablecidas']);
}
}



    

