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
     * Subir una imagen para un negocio.
     */
  /*  public function store(Request $request, Business $business)
{
    $this->authorize('update', $business);

    // Validar que el negocio no tenga más de 2 imágenes en total
    $currentImagesCount = $business->images()->count();
    $imagesToUpload = count($request->file('images', []));

    if ($currentImagesCount + $imagesToUpload > 2) {
        return response()->json([
            'message' => 'No puedes tener más de 2 imágenes por negocio.'
        ], 403);
    }

    $validator = Validator::make($request->all(), [
        'images' => 'required|array|max:2',
        'images.*' => 'image|mimes:jpeg,png,jpg,gif|max:1024', // Máximo 1MB por imagen
        'is_primary' => 'boolean',
        'description' => 'nullable|string'
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    $uploadedImages = [];

    foreach ($request->file('images') as $index => $image) {
        $path = $image->store('business_images', 'public');

        $uploadedImages[] = $business->images()->create([
            'url' => $path,
            'is_primary' => $index === 0, // La primera imagen será la principal
            'description' => $request->description
        ]);
    }

    return response()->json($uploadedImages, 201);
}*/



    /**
     * @OA\Post(
     *     path="/api/businesses/{business}/images",
     *     summary="Subir una imagen para un negocio",
     *     description="Sube una imagen asociada a un negocio específico. Solo el dueño del negocio puede subir imágenes.",
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
        $user = $request->user();
    
        if ((int)$user->id !== (int)$business->user_id) {
            return response()->json(['message' => 'No tienes permiso para actualizar este negocio.'], 403);
        }
    
        $isPrimary = filter_var($request->is_primary, FILTER_VALIDATE_BOOLEAN);
    
        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:1024',
            'description' => 'nullable|string'
        ]);
    
        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }
    
        // Guardar la imagen en public/business_images
        $imageFile = $request->file('image');
        $filename = uniqid() . '.' . $imageFile->getClientOriginalExtension();
        $imageFile->move(public_path('business_images'), $filename);
    
        $image = $business->images()->create([
            'url' => 'business_images/' . $filename,
            'is_primary' => $isPrimary,
            'description' => $request->description
        ]);
    
        return response()->json($image, 201);
    }
    
    
    
    
    /**
     * @OA\Delete(
     *     path="/api/businesses/{business}/images/{image}",
     *     summary="Eliminar una imagen de un negocio",
     *     description="Elimina una imagen específica de un negocio. Solo el dueño del negocio puede eliminar imágenes.",
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
     * @OA\Put(
     *     path="/api/businesses/{business}/images/{image}",
     *     summary="Actualizar la descripción de una imagen de un negocio",
     *     description="Actualiza la descripción de una imagen específica de un negocio. Solo el dueño del negocio puede actualizar imágenes.",
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
     *             @OA\Property(property="description", type="string", example="Nueva descripción de la imagen")
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
            'description' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $image->update([
            'description' => $request->description
        ]);

        return response()->json($image, 200);
    }


}


    

