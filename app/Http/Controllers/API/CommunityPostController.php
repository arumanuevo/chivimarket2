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
     * Reescalar y comprimir una imagen usando PHP GD nativo
     * Limita resolución a máx 1200x1200px y comprime a calidad 80 (pesa ~150-250KB)
     */
    private function processAndSaveImage($file): ?string
    {
        $destinationDir = public_path('community_images');
        if (!file_exists($destinationDir)) {
            @mkdir($destinationDir, 0755, true);
        }

        $extension = strtolower($file->getClientOriginalExtension());
        $filePath = $file->getRealPath();

        // 1. Crear recurso de imagen según extensión
        $srcImage = null;
        if (in_array($extension, ['jpg', 'jpeg'])) {
            $srcImage = @imagecreatefromjpeg($filePath);
        } elseif ($extension === 'png') {
            $srcImage = @imagecreatefrompng($filePath);
        } elseif ($extension === 'webp') {
            $srcImage = @imagecreatefromwebp($filePath);
        }

        $filename = time() . '_' . Str::random(10) . '.jpg';
        $targetPath = $destinationDir . DIRECTORY_SEPARATOR . $filename;

        // Si GD no puede procesarla por algún motivo, guardarla directamente como fallback
        if (!$srcImage) {
            $file->move($destinationDir, $filename);
            return 'community_images/' . $filename;
        }

        // 2. Calcular nuevas dimensiones proporcionales (máx 1200px)
        $origWidth = imagesx($srcImage);
        $origHeight = imagesy($srcImage);
        $maxDim = 1200;

        if ($origWidth > $maxDim || $origHeight > $maxDim) {
            if ($origWidth > $origHeight) {
                $newWidth = $maxDim;
                $newHeight = (int) round(($origHeight * $maxDim) / $origWidth);
            } else {
                $newHeight = $maxDim;
                $newWidth = (int) round(($origWidth * $maxDim) / $origHeight);
            }
        } else {
            $newWidth = $origWidth;
            $newHeight = $origHeight;
        }

        // 3. Reescalar con suavizado de alta calidad (resample)
        $dstImage = imagecreatetruecolor($newWidth, $newHeight);

        // Fondo blanco (evita fondos negros en PNG transparentes)
        $white = imagecolorallocate($dstImage, 255, 255, 255);
        imagefilledrectangle($dstImage, 0, 0, $newWidth, $newHeight, $white);

        imagecopyresampled($dstImage, $srcImage, 0, 0, 0, 0, $newWidth, $newHeight, $origWidth, $origHeight);

        // 4. Guardar comprimida a calidad 80
        imagejpeg($dstImage, $targetPath, 80);

        // Liberar memoria de GD
        imagedestroy($srcImage);
        imagedestroy($dstImage);

        return 'community_images/' . $filename;
    }

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
     * Crear una nueva publicación de trueque o usado (Hasta 4 fotos optimizadas)
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
            'photos' => 'nullable|array|max:4',
            'photos.*' => 'image|mimes:jpeg,png,jpg,webp|max:10240',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:10240',
            'accepted_terms' => 'required|accepted',
        ], [
            'accepted_terms.accepted' => 'Es obligatorio aceptar la declaración jurada y los términos legales de trueques y usados para publicar.',
            'title.required' => 'El título de la publicación es obligatorio.',
            'description.required' => 'La descripción del estado del producto es obligatoria.',
            'contact_whatsapp.required' => 'Debes ingresar un número de WhatsApp para que los vecinos interesados puedan contactarte.',
            'photos.max' => 'Podés subir hasta un máximo de 4 fotos por artículo.'
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

        // Procesar hasta 4 fotos con reescalado y compresión
        $savedImages = [];

        if ($request->hasFile('photos')) {
            $files = $request->file('photos');
            $filesToProcess = is_array($files) ? array_slice($files, 0, 4) : [$files];
            foreach ($filesToProcess as $file) {
                $savedPath = $this->processAndSaveImage($file);
                if ($savedPath) {
                    $savedImages[] = $savedPath;
                }
            }
        } elseif ($request->hasFile('image')) {
            $savedPath = $this->processAndSaveImage($request->file('image'));
            if ($savedPath) {
                $savedImages[] = $savedPath;
            }
        }

        $imageUrl = !empty($savedImages) ? $savedImages[0] : $request->image_url;

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
            'images' => !empty($savedImages) ? $savedImages : ($request->image_url ? [$request->image_url] : null),
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
            'photos' => 'nullable|array|max:4',
            'photos.*' => 'image|mimes:jpeg,png,jpg,webp|max:10240',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:10240',
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

        if ($request->hasFile('photos')) {
            $files = $request->file('photos');
            $filesToProcess = is_array($files) ? array_slice($files, 0, 4) : [$files];
            $savedImages = [];
            foreach ($filesToProcess as $file) {
                $savedPath = $this->processAndSaveImage($file);
                if ($savedPath) $savedImages[] = $savedPath;
            }
            if (!empty($savedImages)) {
                $post->images = $savedImages;
                $post->image_url = $savedImages[0];
            }
        } elseif ($request->hasFile('image')) {
            $savedPath = $this->processAndSaveImage($request->file('image'));
            if ($savedPath) {
                $post->images = [$savedPath];
                $post->image_url = $savedPath;
            }
        } elseif ($request->filled('image_url')) {
            $post->image_url = $request->image_url;
            $post->images = [$request->image_url];
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
     * Eliminar publicación y limpiar sus fotos del disco para no consumir espacio
     */
    public function destroy(Request $request, $id)
    {
        $post = CommunityPost::findOrFail($id);

        if ($post->user_id !== $request->user()->id) {
            return response()->json(['message' => 'No autorizado para eliminar esta publicación.'], 403);
        }

        // Limpieza de fotos físicas en el servidor
        if ($post->images && is_array($post->images)) {
            foreach ($post->images as $imgPath) {
                $fullPath = public_path($imgPath);
                if (file_exists($fullPath) && is_file($fullPath)) {
                    @unlink($fullPath);
                }
            }
        } elseif ($post->image_url) {
            $fullPath = public_path($post->image_url);
            if (file_exists($fullPath) && is_file($fullPath)) {
                @unlink($fullPath);
            }
        }

        $post->delete();

        return response()->json(['message' => 'Publicación y fotos eliminadas correctamente.']);
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
