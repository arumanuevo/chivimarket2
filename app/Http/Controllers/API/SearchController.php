<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Product;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    /**
     * @OA\Get(
     *     path="/api/search",
     *     summary="Búsqueda global de negocios y productos",
     *     description="Busca tanto en negocios como productos según el término ingresado. Permite filtrar por ubicación y radio.",
     *     tags={"Búsquedas"},
     *     @OA\Parameter(name="query", in="query", required=true, description="Texto de búsqueda", @OA\Schema(type="string")),
     *     @OA\Parameter(name="lat", in="query", description="Latitud del usuario", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="lng", in="query", description="Longitud del usuario", @OA\Schema(type="number", format="float")),
     *     @OA\Parameter(name="radius", in="query", description="Radio de búsqueda en metros (por defecto 10000)", @OA\Schema(type="integer")),
     *     @OA\Response(
     *         response=200,
     *         description="Resultados encontrados",
     *         @OA\JsonContent(
     *             @OA\Property(property="businesses", type="array", @OA\Items(type="object")),
     *             @OA\Property(property="products", type="array", @OA\Items(type="object"))
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="No se envió query de búsqueda"
     *     )
     * )
     */

    public function globalSearch(Request $request)
    {
        $query = $request->get('query');
        $lat = $request->get('lat');
        $lng = $request->get('lng');
        $radius = $request->get('radius', 10000); // Default: 10km

        $results = [
            'businesses' => [],
            'products' => []
        ];

        // Buscar negocios si hay un query
        if ($query) {
            $businessQuery = Business::with(['categories', 'images'])
                ->where('name', 'like', '%' . $query . '%')
                ->orWhere('description', 'like', '%' . $query . '%')
                ->orWhereHas('categories', function($q) use ($query) {
                    $q->where('name', 'like', '%' . $query . '%');
                });

            if ($lat && $lng) {
                $businessQuery->selectRaw("*, (6371 * ACOS(COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(longitude) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitude)))) AS distance", [$lat, $lng, $lat])
                    ->having('distance', '<=', $radius)
                    ->orderBy('distance');
            }

            $results['businesses'] = $businessQuery->get();
        }

        // Buscar productos si hay un query
        if ($query) {
            $productQuery = Product::with(['business', 'category', 'images'])
                ->where('name', 'like', '%' . $query . '%')
                ->orWhere('description', 'like', '%' . $query . '%')
                ->orWhereHas('category', function($q) use ($query) {
                    $q->where('name', 'like', '%' . $query . '%');
                });

            $results['products'] = $productQuery->get();
        }

        // Si no hay query, devolver mensaje
        if (!$query) {
            return response()->json([
                'message' => 'Ingresa un término de búsqueda (query).'
            ], 400);
        }

        return response()->json($results);
    }
}

