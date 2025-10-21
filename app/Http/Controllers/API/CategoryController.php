<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\BusinessCategory;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CategoryController extends Controller
{
 
        /**
     * @OA\Get(
     *     path="/api/categories",
     *     summary="Listar todas las categorías de negocios",
     *     description="Devuelve un listado de todas las categorías de negocios registradas.",
     *     tags={"Categorías"},
     *     @OA\Response(
     *         response=200,
     *         description="Lista de categorías",
     *         @OA\JsonContent(type="array", @OA\Items(ref="#/components/schemas/BusinessCategory"))
     *     )
     * )
     */
    public function index()
    {
        return response()->json(BusinessCategory::all());
    }


      /**
     * @OA\Get(
     *     path="/api/categories/{businessCategory}",
     *     summary="Mostrar una categoría específica",
     *     description="Devuelve la información detallada de una categoría por su ID.",
     *     tags={"Categorías"},
     *     @OA\Parameter(
     *         name="businessCategory",
     *         in="path",
     *         required=true,
     *         description="ID de la categoría",
     *         @OA\Schema(type="integer")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Detalle de la categoría",
     *         @OA\JsonContent(ref="#/components/schemas/BusinessCategory")
     *     ),
     *     @OA\Response(response=404, description="Categoría no encontrada")
     * )
     */

    public function show(BusinessCategory $businessCategory)
    {
        return response()->json($businessCategory);
    }

        /**
     * @OA\Post(
     *     path="/api/categories",
     *     summary="Crear una nueva categoría",
     *     description="Crea una nueva categoría de negocio.",
     *     tags={"Categorías"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(
     *             type="object",
     *             @OA\Property(property="name", type="string", example="Restaurantes"),
     *             @OA\Property(property="description", type="string", example="Negocios gastronómicos")
     *         )
     *     ),
     *     @OA\Response(
     *         response=201,
     *         description="Categoría creada correctamente",
     *         @OA\JsonContent(ref="#/components/schemas/BusinessCategory")
     *     ),
     *     @OA\Response(
     *         response=422,
     *         description="Error de validación de los datos enviados"
     *     )
     * )
     */
  
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255|unique:business_categories',
            'description' => 'nullable|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $category = BusinessCategory::create($request->all());
        return response()->json($category, 201);
    }
}
