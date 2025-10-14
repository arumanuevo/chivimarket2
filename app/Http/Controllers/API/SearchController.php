<?php
namespace App\Http\Controllers\API;
use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Product;
use Illuminate\Http\Request;

class SearchController extends Controller
{
    /**
     * Búsqueda global de negocios y productos.
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

