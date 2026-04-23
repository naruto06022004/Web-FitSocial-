<?php

/**
 * One-off helper: ensure default admin exists for local/dev login.
 *
 * Usage (from backend/laravel):
 *   php scripts/ensure_admin_user.php
 */

use App\Models\User;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\Support\Facades\Hash;

require __DIR__.'/../vendor/autoload.php';

$app = require __DIR__.'/../bootstrap/app.php';

/** @var Kernel $kernel */
$kernel = $app->make(Kernel::class);
$kernel->bootstrap();

User::query()->updateOrCreate(
    ['email' => 'admin@fitnet.local'],
    [
        'name' => 'admin',
        'password' => Hash::make('admin123'),
        'role' => 'admin',
    ],
);

echo "OK: ensured admin@fitnet.local / admin123\n";
