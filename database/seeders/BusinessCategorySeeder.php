<?php
namespace Database\Seeders;
use App\Models\BusinessCategory;
use Illuminate\Database\Seeder;

class BusinessCategorySeeder extends Seeder
{
    public function run()
    {
        $categories = [
            ['name' => 'Panaderías', 'description' => 'Negocios de panadería y repostería'],
            ['name' => 'Alimentos', 'description' => 'Venta de alimentos en general'],
            ['name' => 'Ropa', 'description' => 'Tiendas de ropa y accesorios'],
            ['name' => 'Servicios', 'description' => 'Servicios profesionales y técnicos'],
        ];

        foreach ($categories as $category) {
            BusinessCategory::firstOrCreate($category);
        }
    }
}
