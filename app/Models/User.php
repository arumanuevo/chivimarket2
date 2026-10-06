<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable implements MustVerifyEmail
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, HasApiTokens, HasRoles;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'xp_points',
        'level'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    public function businesses()
    {
        return $this->hasMany(Business::class);
    }

    /**
     * Relación con la suscripción del usuario.
     */
    public function subscription()
    {
        return $this->hasOne(Subscription::class);
    }

    public function notifications()
    {
        return $this->morphMany(Notification::class, 'notifiable')
            ->orderBy('created_at', 'desc');
    }

    public function vouchers()
    {
        return $this->hasMany(Voucher::class);
    }

    public function favoriteBusinesses()
    {
        return $this->belongsToMany(Business::class, 'favorite_businesses', 'user_id', 'business_id')->withTimestamps();
    }

    public function favoriteProducts()
    {
        return $this->belongsToMany(Product::class, 'favorite_products', 'user_id', 'product_id')->withTimestamps();
    }
}
