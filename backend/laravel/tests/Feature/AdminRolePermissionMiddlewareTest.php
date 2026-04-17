<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminRolePermissionMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped('pdo_sqlite is required for this database-backed test.');
        }

        parent::setUp();
    }

    public function test_admin_users_requires_users_manage_permission(): void
    {
        Role::query()->create([
            'key' => 'auditor',
            'label' => 'Auditor',
            'permissions' => [
                'admin_access' => true,
                'users_manage' => false,
                'posts_manage' => false,
                'roles_manage' => false,
            ],
        ]);

        $u = User::factory()->create(['role' => 'auditor', 'email' => 'auditor@test.local']);

        Sanctum::actingAs($u);

        $this->getJson('/api/admin/users')->assertForbidden();
    }

    public function test_admin_roles_requires_roles_manage_permission(): void
    {
        Role::query()->create([
            'key' => 'mod',
            'label' => 'Moderator',
            'permissions' => [
                'admin_access' => true,
                'users_manage' => true,
                'posts_manage' => true,
                'roles_manage' => false,
            ],
        ]);

        $u = User::factory()->create(['role' => 'mod', 'email' => 'mod@test.local']);

        Sanctum::actingAs($u);

        $this->getJson('/api/admin/roles')->assertForbidden();
    }

    public function test_full_permissions_can_access_users_and_roles(): void
    {
        Role::query()->create([
            'key' => 'super',
            'label' => 'Super',
            'permissions' => [
                'admin_access' => true,
                'users_manage' => true,
                'posts_manage' => true,
                'roles_manage' => true,
            ],
        ]);

        $u = User::factory()->create(['role' => 'super', 'email' => 'super@test.local']);

        Sanctum::actingAs($u);

        $this->getJson('/api/admin/users')->assertOk();
        $this->getJson('/api/admin/roles')->assertOk();
    }
}
