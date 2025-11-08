<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Notifications\ContactReceived;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

/**
 * @OA\Tag(
 *     name="Contacts",
 *     description="API para registrar y gestionar contactos con negocios/productos"
 * )
 *
 * @OA\Schema(
 *     schema="Contact",
 *     required={"contactable_type", "contactable_id", "contact_type"},
 *     @OA\Property(property="user_id", type="integer", example=1, description="ID del usuario (nullable si no está autenticado)"),
 *     @OA\Property(property="contactable_type", type="string", enum={"business", "product"}, example="business", description="Tipo de entidad contactada"),
 *     @OA\Property(property="contactable_id", type="integer", example=21, description="ID de la entidad contactada"),
 *     @OA\Property(property="contact_type", type="string", enum={
 *         "phone_view", "email_view", "address_view",
 *         "website_click", "social_click", "copy_contact",
 *         "favorite", "share", "map_view", "catalog_download"
 *     }, example="phone_view", description="Tipo de contacto"),
 *     @OA\Property(property="ip", type="string", example="192.168.1.1", description="IP del visitante"),
 *     @OA\Property(property="user_agent", type="string", example="Mozilla/5.0", description="User agent del navegador"),
 *     @OA\Property(property="referer", type="string", example="https://chivimarket.arumasoft.com", description="URL de referencia"),
 *     @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-26T12:34:56.000000Z", description="Fecha de creación")
 * )
 */
class ContactController extends Controller
{
    /**
     * @OA\Post(
     *     path="/api/track-contact",
     *     summary="Registrar un contacto con un negocio o producto",
     *     description="Registra cuando un usuario realiza una acción que indica interés en un negocio o producto (ej: ver teléfono, hacer clic en sitio web, etc.)",
     *     tags={"Contacts"},
     *     @OA\RequestBody(
     *         required=true,
     *         @OA\JsonContent(ref="#/components/schemas/Contact")
     *     ),
     *     @OA\Response(
     *         response=200,
     *         description="Contacto registrado exitosamente",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Contacto registrado")
     *         )
     *     ),
     *     @OA\Response(
     *         response=400,
     *         description="Error de validación",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Error de validación"),
     *             @OA\Property(property="errors", type="object")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Negocio no encontrado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Negocio no encontrado")
     *         )
     *     )
     * )
     */
    public function trackContact(Request $request)
    {
        // Validar los datos de entrada
        $validator = Validator::make($request->all(), [
            'type' => 'required|in:business,product',
            'id' => 'required|integer|exists:businesses,id', // Validar que el negocio/producto exista
            'contact_type' => [
                'required',
                Rule::in([
                    'phone_view', 'email_view', 'address_view',
                    'website_click', 'social_click', 'copy_contact',
                    'favorite', 'share', 'map_view', 'catalog_download'
                ])
            ]
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $validator->errors()
            ], 400);
        }

        try {
            // Preparar datos para registrar el contacto
            $data = [
                'user_id' => Auth::check() ? Auth::id() : null,
                'contactable_type' => $request->type,
                'contactable_id' => $request->id,
                'contact_type' => $request->contact_type,
                'ip' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'referer' => $request->header('referer'),
                'created_at' => now()
            ];

            // Registrar el contacto en la base de datos
            DB::table('contacts')->insert($data);

            // Si es un negocio, notificar al dueño
            if ($request->type === 'business') {
                $business = Business::find($request->id);
                if ($business) {
                    $business->user->notify(new ContactReceived($request->contact_type));
                }
            }

            return response()->json(['message' => 'Contacto registrado']);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al registrar el contacto',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * @OA\Get(
     *     path="/api/businesses/{business}/contact-stats",
     *     summary="Obtener estadísticas de contactos para un negocio",
     *     description="Devuelve estadísticas de contactos para un negocio específico en los últimos 30 días",
     *     tags={"Contacts"},
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
     *         description="Estadísticas de contactos",
     *         @OA\JsonContent(
     *             @OA\Property(property="last_30_days", type="array", @OA\Items(
     *                 @OA\Property(property="date", type="string", format="date", example="2025-10-26"),
     *                 @OA\Property(property="count", type="integer", example=5)
     *             )),
     *             @OA\Property(property="by_type", type="array", @OA\Items(
     *                 @OA\Property(property="contact_type", type="string", example="phone_view"),
     *                 @OA\Property(property="count", type="integer", example=3)
     *             )),
     *             @OA\Property(property="total", type="integer", example=42)
     *         )
     *     ),
     *     @OA\Response(
     *         response=403,
     *         description="No autorizado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="No autorizado")
     *         )
     *     ),
     *     @OA\Response(
     *         response=404,
     *         description="Negocio no encontrado",
     *         @OA\JsonContent(
     *             @OA\Property(property="message", type="string", example="Negocio no encontrado")
     *         )
     *     )
     * )
     */
    public function contactStats(Business $business)
    {
        $this->authorize('view', $business);

        try {
            // Contactos en los últimos 30 días por día
            $last30Days = DB::table('contacts')
                ->where('contactable_type', 'business')
                ->where('contactable_id', $business->id)
                ->where('created_at', '>=', now()->subDays(30))
                ->select(DB::raw('DATE(created_at) as date'), DB::raw('COUNT(*) as count'))
                ->groupBy('date')
                ->orderBy('date')
                ->get();

            // Contactos por tipo
            $byType = DB::table('contacts')
                ->where('contactable_type', 'business')
                ->where('contactable_id', $business->id)
                ->where('created_at', '>=', now()->subDays(30))
                ->select('contact_type', DB::raw('COUNT(*) as count'))
                ->groupBy('contact_type')
                ->get();

            // Total de contactos
            $total = $last30Days->sum('count');

            return response()->json([
                'last_30_days' => $last30Days,
                'by_type' => $byType,
                'total' => $total
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al obtener estadísticas',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
