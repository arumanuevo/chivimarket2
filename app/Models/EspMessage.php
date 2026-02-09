<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EspMessage extends Model
{
    use HasFactory;

    protected $fillable = ['content', 'color'];
}
