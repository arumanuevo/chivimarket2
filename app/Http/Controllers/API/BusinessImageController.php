<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\BusinessImage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class BusinessImageController extends Controller
{
    /**
     * Subir una imagen para un negocio.
     */
    public function store(Request $request, Business $business)
    {
        $this->authorize('update', $business); // Política de autorización

        $validator = Validator::make($request->all(), [
            'image' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_primary' => 'boolean',
            'description' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Guardar la imagen en storage
        $path = $request->file('image')->store('business_images', 'public');

        // Crear el registro en la base de datos
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
