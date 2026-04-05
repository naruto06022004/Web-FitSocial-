<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();
        User::query()->updateOrCreate(
            ['email' => 'admin@fitnet.local'],
            [
                'name' => 'admin',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
            ],
        );

        User::query()->updateOrCreate(
            ['email' => 'staff@fitnet.local'],
            [
                'name' => 'Fitnet Staff',
                'password' => Hash::make('Password123!'),
                'role' => 'staff',
            ],
        );
    }
}
