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
     * Subir una imagen para un negocio.
     */
    public function store(Request $request, Business $business)
    {
        // Depuración: Verificar el usuario autenticado y el negocio
        $user = $request->user();

        \Log::info('User ID:', ['user_id' => $user->id, 'type' => gettype($user->id)]);
        \Log::info('Business User ID:', ['business_user_id' => $business->user_id, 'type' => gettype($business->user_id)]);
    
        if ((int)$user->id !== (int)$business->user_id) {
            \Log::error('Usuario no es dueño del negocio', [
                'user_id' => $user->id,
                'business_user_id' => $business->user_id
            ]);
            return response()->json(['message' => 'No tienes permiso para actualizar este negocio.'], 403);
        }
    
        // Intentar autorizar manualmente
        try {
            $this->authorize('update', $business);
        } catch (\Illuminate\Auth\Access\AuthorizationException $e) {
            \Log::error('Error de autorización:', ['error' => $e->getMessage()]);
            return response()->json(['message' => 'No autorizado: ' . $e->getMessage()], 403);
        }
    
        // Validar que el negocio no tenga más de 2 imágenes
        if ($business->images()->count() >= 2) {
            return response()->json([
                'message' => 'No puedes subir más de 2 imágenes por negocio.'
            ], 403);
        }
    
        // Validar la imagen
        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:1024',
            'is_primary' => 'boolean',
            'description' => 'nullable|string'
        ]);
    
        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }
    
        // Guardar la imagen
        $path = $request->file('image')->store('business_images', 'public');
    
        $image = $business->images()->create([
            'url' => $path,
            'is_primary' => $request->is_primary ?? false,
            'description' => $request->description
        ]);
    
        return response()->json($image, 201);
    }
    
    

    /**
     * Eliminar una imagen de un negocio.
     */
    public function destroy(Business $business, BusinessImage $image)
    {
        $this->authorize('update', $business);

        // Eliminar la imagen del storage
        Storage::disk('public')->delete($image->url);

        // Eliminar el registro de la base de datos
        $image->delete();

        return response()->json(['message' => 'Imagen eliminada correctamente']);
    }
}


    

