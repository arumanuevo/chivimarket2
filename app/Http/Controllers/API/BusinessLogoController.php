<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Business;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;

class BusinessLogoController extends Controller
{
    use AuthorizesRequests;

    /**
     * @OA\Post(
     *     path="/api/businesses/{business}/logo",
     *     summary="Subir el logo de un negocio",
     *     description="Sube el logo asociado a un negocio específico. Solo el dueño del negocio puede subir el logo.",
     *     tags={"Logo de Negocio"},
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
     *         description="Archivo de logo (JPEG, PNG, JPG, GIF, máximo 1MB)",
     *         @OA\MediaType(
     *             mediaType="multipart/form-data",
     *             @OA\Schema(
     *                 required={"logo"},
     *                 @OA\Property(
     *                     property="logo",
     *                     type="string",
     *                     format="binary",
     *                     description="Archivo de imagen del logo"
     *                 )
     *             )
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Logo subido correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/Business")
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(
     *                 property="logo",
     *                 type="array",
     *                 @OA\Items(type="string", example={"El campo logo debe ser una imagen de tipo: jpeg, png, jpg, gif."})
     *             )
     *         )
     *     )
     * )
     */
    public function store(Request $request, Business $business)
    {
        $this->authorize('update', $business);

        $validator = Validator::make($request->all(), [
            'logo' => 'required|image|mimes:jpeg,png,jpg,gif|max:1024',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Eliminar logo anterior si existe
        if ($business->logo_url) {
            $oldLogoPath = public_path($business->logo_url);
            if (file_exists($oldLogoPath)) {
                unlink($oldLogoPath);
            }
        }

        // Guardar el nuevo logo
        $logoFile = $request->file('logo');
        $filename = 'logo_' . uniqid() . '.' . $logoFile->getClientOriginalExtension();
        $logoFile->move(public_path('business_logos'), $filename);

        $business->update(['logo_url' => 'business_logos/' . $filename]);

        return response()->json($business, 201);
    }

    /**
     * @OA\Delete(
     *     path="/api/businesses/{business}/logo",
     *     summary="Eliminar el logo de un negocio",
     *     description="Elimina el logo asociado a un negocio específico. Solo el dueño del negocio puede eliminar el logo.",
     *     tags={"Logo de Negocio"},
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
     *         description="Logo eliminado correctamente",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="Logo eliminado correctamente")
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado",
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     )
     * )
     */
    public function destroy(Business $business)
    {
        $this->authorize('update', $business);

        if ($business->logo_url) {
            $logoPath = public_path($business->logo_url);
            if (file_exists($logoPath)) {
                unlink($logoPath);
            }
            $business->update(['logo_url' => null]);
        }

        return response()->json(['message' => 'Logo eliminado correctamente']);
    }
}
