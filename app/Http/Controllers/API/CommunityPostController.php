<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\CommunityPost;
use App\Models\CommunityPostReport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class CommunityPostController extends Controller
{
    /**
     * Palabras y patrones prohibidos para proteger legalmente a la plataforma
     */
    protected array $prohibitedKeywords = [
        'arma', 'armas', 'pistola', 'revolver', 'rifle', 'escopeta', 'municion', 'municiones',
        'bala', 'balas', 'polvora', 'tumbera', 'tumbero', 'chumbera', 'fogueo',
        'droga', 'drogas', 'cocaina', 'marihuana', 'faso', 'porro', 'paco', 'clonazepam',
        'tramadol', 'morfina', 'medicamento', 'medicamentos', 'pastillas', 'receta',
        'anabolico', 'anabolicos', 'esteroides', 'viagra', 'sildenafil',
        'robado', 'robada', 'afanado', 'afanada', 'inhibidor', 'clonado', 'trucho', 'falsificado',
        'replica 1:1', 'replica aaa', 'documento trucho', 'dni falso', 'billetes falsos'
    ];

    /**
     * Listado público de publicaciones de trueques y usados
     */
    public function index(Request $request)
    {
        $query = CommunityPost::with(['user:id,name,email,created_at'])
            ->where('is_active', true);

        // Filtro por tipo (barter, sale, both)
        if ($request->has('type') && in_array($request->type, ['barter', 'sale', 'both'])) {
            if ($request->type === 'barter') {
                $query->whereIn('type', ['barter', 'both']);
            } elseif ($request->type === 'sale') {
                $query->whereIn('type', ['sale', 'both']);
            } else {
                $query->where('type', $request->type);
            }
        }

        // Filtro por condición
        if ($request->has('condition') && !empty($request->condition)) {
            $query->where('condition', $request->condition);
        }

        // Búsqueda por texto (título, descripción, qué busca en trueque)
        if ($request->filled('search')) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('barter_for', 'like', "%{$search}%")
                  ->orWhere('zone', 'like', "%{$search}%");
            });
        }

        // Ordenamiento
        $sort = $request->get('sort', 'newest');
        switch ($sort) {
            case 'price_asc':
                $query->orderBy('price', 'asc');
                break;
            case 'price_desc':
                $query->orderBy('price', 'desc');
                break;
            case 'popular':
                $query->orderBy('views_count', 'desc');
                break;
            case 'newest':
            default:
                $query->orderBy('id', 'desc');
                break;
        }

        $posts = $query->paginate(24);

        return response()->json($posts);
    }

    /**
     * Ver una publicación individual y registrar vista
     */
    public function show($id)
    {
        $post = CommunityPost::with(['user:id,name,email,created_at'])->findOrFail($id);

        if (!$post->is_active && (!auth('sanctum')->check() || auth('sanctum')->id() !== $post->user_id)) {
            return response()->json(['message' => 'Esta publicación ya no se encuentra disponible.'], 404);
        }

        // Incrementar vistas
        $post->increment('views_count');

        // Retornar información con deslinde legal explícito
        return response()->json([
            'post' => $post,
            'legal_disclaimer' => [
                'notice' => 'ChiviMarket es una plataforma tecnológica de contacto comunitario entre vecinos de Chivilcoy.',
                'intermediation' => 'ChiviMarket no es propietario de los bienes publicados, no interviene en las negociaciones, no cobra comisiones, ni garantiza el estado, funcionamiento o legitimidad de los artículos.',
                'safety_advice' => 'Las operaciones son directas entre particulares bajo modalidad "ad-corpus" (como está). Acordá siempre el encuentro en lugares públicos e iluminados durante el día y revisá el producto antes de entregar o recibir cualquier valor. No transfieras dinero por adelantado.'
            ]
        ]);
    }

    /**
     * Mis publicaciones (usuario autenticado)
     */
    public function myPosts(Request $request)
    {
        $posts = CommunityPost::where('user_id', $request->user()->id)
            ->orderBy('id', 'desc')
            ->get();

        return response()->json($posts);
    }

    /**
     * Crear una nueva publicación de trueque o usado
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|min:3|max:150',
            'type' => 'required|in:barter,sale,both',
            'description' => 'required|string|min:10|max:2500',
            'price' => 'nullable|numeric|min:0',
            'barter_for' => 'nullable|string|max:500',
            'condition' => 'required|string|in:como_nuevo,muy_bueno,buen_estado,con_detalles',
            'contact_whatsapp' => 'required|string|min:6|max:30',
            'contact_name' => 'nullable|string|max:100',
            'zone' => 'nullable|string|max:100',
            'image_url' => 'nullable|string|max:1000',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
            'accepted_terms' => 'required|accepted',
        ], [
            'accepted_terms.accepted' => 'Es obligatorio aceptar la declaración jurada y los términos legales de trueques y usados para publicar.',
            'title.required' => 'El título de la publicación es obligatorio.',
            'description.required' => 'La descripción del estado del producto es obligatoria.',
            'contact_whatsapp.required' => 'Debes ingresar un número de WhatsApp para que los vecinos interesados puedan contactarte.'
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error de validación en la publicación',
                'errors' => $validator->errors()
            ], 422);
        }

        // Filtro legal preventivo de contenido ilícito
        $textToScan = Str::lower($request->title . ' ' . $request->description . ' ' . ($request->barter_for ?? ''));
        foreach ($this->prohibitedKeywords as $keyword) {
            if (preg_match('/\b' . preg_quote($keyword, '/') . '\b/i', $textToScan)) {
                return response()->json([
                    'message' => 'Publicación rechazada por infracción a las Políticas de Seguridad de ChiviMarket.',
                    'detail' => 'No está permitido publicar armas, medicamentos, réplicas no autorizadas, sustancias reguladas ni bienes de procedencia dudosa. Cuidemos nuestra comunidad.'
                ], 422);
            }
        }

        // Manejo de imagen
        $imageUrl = $request->image_url;
        if ($request->hasFile('image')) {
            $destinationPath = public_path('community_images');
            if (!file_exists($destinationPath)) {
                @mkdir($destinationPath, 0755, true);
            }
            $filename = time() . '_' . Str::random(10) . '.' . $request->file('image')->getClientOriginalExtension();
            $request->file('image')->move($destinationPath, $filename);
            $imageUrl = 'community_images/' . $filename;
        }

        $user = $request->user();

        $post = CommunityPost::create([
            'user_id' => $user->id,
            'type' => $request->type,
            'title' => trim($request->title),
            'description' => trim($request->description),
            'price' => $request->price,
            'barter_for' => $request->barter_for ? trim($request->barter_for) : null,
            'condition' => $request->condition,
            'contact_phone' => $request->contact_phone,
            'contact_whatsapp' => trim($request->contact_whatsapp),
            'contact_name' => $request->contact_name ?: $user->name,
            'city' => 'Chivilcoy',
            'zone' => $request->zone ? trim($request->zone) : null,
            'image_url' => $imageUrl,
            'is_active' => true,
            'views_count' => 0,
            'accepted_terms' => true,
            'accepted_terms_at' => now(),
            'ip_address' => $request->ip(),
            'reports_count' => 0,
        ]);

        return response()->json([
            'message' => '¡Publicación de trueque/usado creada con éxito!',
            'post' => $post
        ], 201);
    }

    /**
     * Modificar una publicación (solo el autor)
     */
    public function update(Request $request, $id)
    {
        $post = CommunityPost::findOrFail($id);

        if ($post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'No estás autorizado a modificar esta publicación.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|required|string|min:3|max:150',
            'type' => 'sometimes|required|in:barter,sale,both',
            'description' => 'sometimes|required|string|min:10|max:2500',
            'price' => 'nullable|numeric|min:0',
            'barter_for' => 'nullable|string|max:500',
            'condition' => 'sometimes|required|string|in:como_nuevo,muy_bueno,buen_estado,con_detalles',
            'contact_whatsapp' => 'sometimes|required|string|min:6|max:30',
            'contact_name' => 'nullable|string|max:100',
            'zone' => 'nullable|string|max:100',
            'image_url' => 'nullable|string|max:1000',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Error de validación',
                'errors' => $validator->errors()
            ], 422);
        }

        // Filtro legal preventivo si modifican texto
        $textToScan = Str::lower(($request->title ?? $post->title) . ' ' . ($request->description ?? $post->description));
        foreach ($this->prohibitedKeywords as $keyword) {
            if (preg_match('/\b' . preg_quote($keyword, '/') . '\b/i', $textToScan)) {
                return response()->json([
                    'message' => 'Contenido rechazado por infracción a las Políticas de Seguridad de ChiviMarket.'
                ], 422);
            }
        }

        if ($request->hasFile('image')) {
            $destinationPath = public_path('community_images');
            if (!file_exists($destinationPath)) {
                @mkdir($destinationPath, 0755, true);
            }
            $filename = time() . '_' . Str::random(10) . '.' . $request->file('image')->getClientOriginalExtension();
            $request->file('image')->move($destinationPath, $filename);
            $post->image_url = 'community_images/' . $filename;
        } elseif ($request->filled('image_url')) {
            $post->image_url = $request->image_url;
        }

        $post->update($request->only([
            'title', 'type', 'description', 'price', 'barter_for',
            'condition', 'contact_whatsapp', 'contact_name', 'zone'
        ]));

        return response()->json([
            'message' => 'Publicación actualizada correctamente.',
            'post' => $post
        ]);
    }

    /**
     * Pausar, reactivar o marcar como intercambiado
     */
    public function toggleStatus(Request $request, $id)
    {
        $post = CommunityPost::findOrFail($id);

        if ($post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $post->is_active = !$post->is_active;
        $post->save();

        return response()->json([
            'message' => $post->is_active ? 'Publicación reactivada.' : 'Publicación pausada / finalizada.',
            'is_active' => $post->is_active
        ]);
    }

    /**
     * Eliminar publicación
     */
    public function destroy(Request $request, $id)
    {
        $post = CommunityPost::findOrFail($id);

        if ($post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'No autorizado para eliminar esta publicación.'], 403);
        }

        $post->delete();

        return response()->json(['message' => 'Publicación eliminada correctamente.']);
    }

    /**
     * Denunciar publicación por motivos de seguridad o legalidad
     */
    public function report(Request $request, $id)
    {
        $post = CommunityPost::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:100',
            'details' => 'nullable|string|max:500'
        ]);

        if ($validator->fails()) {
            return response()->json(['message' => 'Datos de denuncia incompletos.'], 422);
        }

        $userId = auth('sanctum')->check() ? auth('sanctum')->id() : null;

        CommunityPostReport::create([
            'community_post_id' => $post->id,
            'reporter_user_id' => $userId,
            'reason' => $request->reason,
            'details' => $request->details,
            'reporter_ip' => $request->ip()
        ]);

        $post->increment('reports_count');

        // Mecanismo preventivo "Notice & Take-Down": Si acumula 3 o más reportes, se desactiva preventivamente
        if ($post->reports_count >= 3) {
            $post->update(['is_active' => false]);
        }

        return response()->json([
            'message' => 'Denuncia recibida. El equipo de ChiviMarket revisará la publicación a la brevedad. Gracias por cuidar nuestra comunidad.'
        ]);
    }
}
