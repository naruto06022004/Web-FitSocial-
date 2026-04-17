<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminUsersWithoutRolesTableTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped('pdo_sqlite is required for this database-backed test.');
        }

        parent::setUp();
    }

    public function test_admin_can_list_users_when_roles_table_is_missing(): void
    {
        Schema::dropIfExists('roles');

        $admin = User::factory()->create(['role' => 'admin']);

        Sanctum::actingAs($admin);

        $this->getJson('/api/admin/users')
            ->assertOk()
            ->assertJsonStructure(['data']);
    }

    public function test_non_admin_cannot_list_users_when_roles_table_is_missing(): void
    {
        Schema::dropIfExists('roles');

        $user = User::factory()->create(['role' => 'user']);

        Sanctum::actingAs($user);

        $this->getJson('/api/admin/users')->assertForbidden();
    }

    public function test_admin_roles_index_returns_empty_payload_when_roles_table_is_missing(): void
    {
        Schema::dropIfExists('roles');

        $admin = User::factory()->create(['role' => 'admin']);

        Sanctum::actingAs($admin);

        $this->getJson('/api/admin/roles')
            ->assertOk()
            ->assertJsonPath('data', [])
            ->assertJsonPath('meta.schema_incomplete', true);
    }
}
