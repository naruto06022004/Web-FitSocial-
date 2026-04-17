<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminRoleDeleteReassignsUsersTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        if (! extension_loaded('pdo_sqlite')) {
            $this->markTestSkipped('pdo_sqlite is required for this database-backed test.');
        }

        parent::setUp();
    }

    public function test_deleting_custom_role_reassigns_users_to_user(): void
    {
        Role::query()->create([
            'key' => 'moderator',
            'label' => 'Moderator',
            'permissions' => ['admin_access' => true],
        ]);

        $admin = User::factory()->create(['role' => 'admin']);
        $member = User::factory()->create(['role' => 'moderator']);

        $mod = Role::query()->where('key', 'moderator')->firstOrFail();

        Sanctum::actingAs($admin);

        $response = $this->deleteJson('/api/admin/roles/'.$mod->id);
        $response->assertOk()
            ->assertJsonPath('ok', true)
            ->assertJsonPath('reassigned_users', 1)
            ->assertJsonPath('fallback_role', 'user');

        $this->assertDatabaseMissing('roles', ['key' => 'moderator']);
        $this->assertSame('user', $member->fresh()->role);
    }

    public function test_cannot_delete_system_user_role(): void
    {
        Role::query()->create([
            'key' => 'user',
            'label' => 'Student',
            'permissions' => [],
        ]);

        $admin = User::factory()->create(['role' => 'admin']);
        $userRole = Role::query()->where('key', 'user')->firstOrFail();

        Sanctum::actingAs($admin);

        $this->deleteJson('/api/admin/roles/'.$userRole->id)->assertStatus(422);
    }
}
