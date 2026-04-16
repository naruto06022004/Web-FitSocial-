<?php

namespace Database\Seeders;

use App\Models\Gym;
use App\Models\Post;
use App\Models\ChatMessage;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    private function userOptionalAttrs(array $attrs): array
    {
        $out = $attrs;
        foreach (['bio', 'gym_name', 'avatar_url'] as $c) {
            if (!Schema::hasColumn('users', $c)) {
                unset($out[$c]);
            }
        }
        return $out;
    }

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed roles (CRUD managed later from Admin UI).
        Role::query()->updateOrCreate(
            ['key' => 'admin'],
            [
                'label' => 'Admin',
                'permissions' => [
                    'admin_access' => true,
                    'roles_manage' => true,
                    'users_manage' => true,
                    'posts_manage' => true,
                ],
            ],
        );
        Role::query()->updateOrCreate(
            ['key' => 'staff'],
            [
                'label' => 'Teacher',
                'permissions' => [
                    'admin_access' => true,
                    'roles_manage' => false,
                    'users_manage' => true,
                    'posts_manage' => true,
                ],
            ],
        );
        Role::query()->updateOrCreate(
            ['key' => 'user'],
            [
                'label' => 'Student',
                'permissions' => [
                    'admin_access' => false,
                    'roles_manage' => false,
                    'users_manage' => false,
                    'posts_manage' => false,
                ],
            ],
        );

        // User::factory(10)->create();
        $admin = User::query()->updateOrCreate(
            ['email' => 'admin@fitnet.local'],
            $this->userOptionalAttrs([
                'name' => 'admin',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'bio' => 'Admin Fitnet • quản lý hệ thống',
                'gym_name' => 'Fitnet Gym Quận 1',
                'avatar_url' => 'https://i.pravatar.cc/256?img=12',
            ]),
        );

        $staff = User::query()->updateOrCreate(
            ['email' => 'staff@fitnet.local'],
            $this->userOptionalAttrs([
                'name' => 'Fitnet Staff',
                'password' => Hash::make('Password123!'),
                'role' => 'staff',
                'bio' => 'HLV/Teacher • hỗ trợ cộng đồng',
                'gym_name' => 'California Fitness',
                'avatar_url' => 'https://i.pravatar.cc/256?img=32',
            ]),
        );

        // Sample normal users
        $names = [
            'Nguyễn Tuấn', 'Trần Minh', 'Lê Huy', 'Phạm Linh', 'Đỗ Quỳnh',
            'Vũ Nam', 'Hoàng Anh', 'Bùi Trang', 'Phan Khang', 'Đặng Vy',
        ];
        $users = collect();
        foreach ($names as $i => $name) {
            $email = 'user'.($i + 1).'@fitnet.test';
            $users->push(
                User::query()->updateOrCreate(
                    ['email' => $email],
                    $this->userOptionalAttrs([
                        'name' => $name,
                        'password' => Hash::make('Password123!'),
                        'role' => 'user',
                        'bio' => 'Yêu fitness • tập đều mỗi tuần • demo profile',
                        'gym_name' => $i % 2 === 0 ? 'Fitnet Gym Quận 1' : 'Gym Thể hình 247',
                        'avatar_url' => 'https://i.pravatar.cc/256?img='.(50 + $i),
                    ]),
                ),
            );
        }

        $gyms = [
            ['name' => 'Fitnet Gym Quận 1', 'address' => 'TP.HCM', 'latitude' => 10.7769, 'longitude' => 106.7009],
            ['name' => 'California Fitness', 'address' => 'TP.HCM', 'latitude' => 10.7820, 'longitude' => 106.6950],
            ['name' => 'Gym Thể hình 247', 'address' => 'TP.HCM', 'latitude' => 10.7650, 'longitude' => 106.7100],
            ['name' => 'Iron Box', 'address' => 'TP.HCM', 'latitude' => 10.7900, 'longitude' => 106.7200],
        ];
        foreach ($gyms as $g) {
            Gym::query()->updateOrCreate(
                ['name' => $g['name']],
                $g,
            );
        }

        // Seed posts for feed (avoid duplicates by stable "seed_key" in title)
        $postTemplates = [
            ['title' => 'Hôm nay tập gì được nhỉ', 'content' => null],
            ['title' => 'Push day: ngực + vai', 'content' => "Bench press 5x5\nIncline DB press 4x10\nLateral raise 4x12"],
            ['title' => 'Leg day nặng quá', 'content' => "Squat 5x5\nRDL 4x8\nLeg press 4x12"],
            ['title' => 'Cardio nhẹ 20 phút', 'content' => 'Zone 2 — giữ nhịp tim ổn định, cảm giác rất đã.'],
            ['title' => 'PR deadlift!', 'content' => 'Hôm nay lên được 140kg. Cảm ơn anh em đã spot!'],
        ];

        $allAuthors = collect([$admin, $staff])->merge($users);
        foreach ($allAuthors as $idx => $author) {
            foreach ($postTemplates as $tIdx => $tpl) {
                $seedTitle = $tpl['title'].' #'.($idx + 1).'-'.($tIdx + 1);
                Post::query()->updateOrCreate(
                    ['user_id' => $author->id, 'title' => $seedTitle],
                    ['content' => $tpl['content']],
                );
            }
        }

        // Seed some chat messages between admin/staff and users
        $u1 = $users->first();
        if ($u1) {
            $msgs = [
                [$admin->id, $u1->id, 'Chào bạn, cần hỗ trợ gì không?'],
                [$u1->id, $admin->id, 'Em muốn hỏi lịch tập hợp lý cho người mới.'],
                [$admin->id, $u1->id, 'Ok, mình gợi ý full-body 3 buổi/tuần nhé.'],
                [$staff->id, $u1->id, 'Bạn nhớ khởi động kỹ trước squat nha!'],
            ];
            foreach ($msgs as $m) {
                ChatMessage::query()->updateOrCreate(
                    [
                        'sender_id' => $m[0],
                        'recipient_id' => $m[1],
                        'body' => $m[2],
                    ],
                    [
                        'read_at' => null,
                    ],
                );
            }
        }
    }
}
