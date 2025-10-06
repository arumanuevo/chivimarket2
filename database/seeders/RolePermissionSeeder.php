<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use App\Models\User;

class RolePermissionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Crear permisos
        Permission::create(['name' => 'create-users']);
        Permission::create(['name' => 'view-users']);

        // Crear rol
        $admin = Role::create(['name' => 'admin']);
        $admin->givePermissionTo(['create-users', 'view-users']);

        // Crear usuario de prueba
        $user = User::create([
            'name' => 'Admin User',
            'email' => 'admin@example.com',
            'password' => bcrypt('password123'),
        ]);

        $user->assignRole('admin');
    }
}
