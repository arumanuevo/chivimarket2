<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class MLSyncController extends Controller
{
    /**
     * Importa la raíz del árbol de categorías puras de MercadoLibre 
     * directamente hacia nuestra base de datos local de ChiviMarket.
     */
    public function importTopCategories()
    {
        // Incrementamos el tiempo límite por si la API es lenta (hosting compartido)
        set_time_limit(100);

        try {
            // 1. Obtener árbol de categorías raíz de MercadoLibre (Para Argentina: MLA)
            $response = Http::timeout(10)->get('https://api.mercadolibre.com/sites/MLA/categories');

            if (!$response->successful()) {
                return response()->json(['error' => 'Falló la conexión con MercadoLibre'], 500);
            }

            $mlCategories = $response->json();
            $importedCount = 0;

            foreach ($mlCategories as $mlCat) {
                // 2. Comprobar si ya existe en la BD para no duplicar
                $exists = DB::table('business_categories')
                    ->where('name', $mlCat['name'])
                    ->exists();

                if (!$exists) {
                    // 3. Extracción mágica. 
                    // Guardamos el ID original de ML en la descripción como rastreador invisible 
                    // por si después queremos extraer sus atributos profundos (hijos).
                    $localCategoryId = DB::table('business_categories')->insertGetId([
                        'name' => $mlCat['name'],
                        'description' => 'ML_ID:' . $mlCat['id'],
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    // (OPCIONAL EN EL FUTURO) 
                    // Si MercadoLibre tuviese atributos estructurados en la raíz, podríamos 
                    // hacer aquí un Http::get(...) a sus hijos y llenar la tabla category_attributes.
                    // Generalmente, ML pide pegarle a una subcategoría (Ej: MLA4015).

                    $importedCount++;
                }
            }

            return response()->json([
                'status' => 'success',
                'message' => "Operación completada. Se importaron $importedCount nuevas categorías maestras a ChiviMarket desde ML.",
                'total_escaneadas' => count($mlCategories)
            ]);

        } catch (\Exception $e) {
            Log::error("Error importando desde ML: " . $e->getMessage());
            return response()->json(['error' => 'Error interno en el scraper', 'details' => $e->getMessage()], 500);
        }
    }
}
