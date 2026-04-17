# Data Models — Backend (Laravel) _(Quick Scan)_

This is a **quick-scan** inventory based on obvious Laravel conventions and migration filenames. Full field-level extraction requires Deep Scan. _(To be generated)_

## Observed Entities

- **User**
  - Extended profile attributes suggested by migrations (e.g. bio, gym name, avatar URL)
  - Role / permissions concepts present
- **Role**
  - Role catalog (admin/staff/user implied by client logic)
- **Gym**
  - Gyms list and nearby gyms features imply geo/location data
- **ChatMessage**
  - Direct messaging with conversations and "seen" tracking
- **Post** (implied)
  - Posts CRUD exists in API routes (post migration may exist elsewhere)

## Schema Sources

- `backend/laravel/database/migrations/2026_04_16_000001_add_bio_gym_name_to_users_table.php`
- `backend/laravel/database/migrations/2026_04_16_000004_add_avatar_url_to_users_table.php`
- `backend/laravel/database/migrations/2026_04_16_000002_create_chat_messages_table.php`
- `backend/laravel/database/migrations/2026_04_16_000003_create_gyms_table.php`
- `backend/laravel/database/migrations/2026_04_16_000005_create_roles_table.php`

