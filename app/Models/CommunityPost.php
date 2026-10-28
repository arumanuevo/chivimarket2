<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CommunityPost extends Model
{
    use HasFactory;

    protected $table = 'community_posts';

    protected $fillable = [
        'user_id',
        'type',             // 'barter', 'sale', 'both'
        'title',
        'description',
        'price',
        'barter_for',
        'condition',        // 'como_nuevo', 'muy_bueno', 'buen_estado', 'con_detalles'
        'contact_phone',
        'contact_whatsapp',
        'contact_name',
        'city',
        'zone',
        'image_url',
        'images',
        'is_active',
        'views_count',
        'accepted_terms',
        'accepted_terms_at',
        'ip_address',
        'reports_count',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_active' => 'boolean',
        'accepted_terms' => 'boolean',
        'accepted_terms_at' => 'datetime',
        'images' => 'array',
        'views_count' => 'integer',
        'reports_count' => 'integer',
    ];

    /**
     * Relación con el usuario autor de la publicación
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Reportes de usuarios sobre esta publicación
     */
    public function reports(): HasMany
    {
        return $this->hasMany(CommunityPostReport::class, 'community_post_id');
    }
}
