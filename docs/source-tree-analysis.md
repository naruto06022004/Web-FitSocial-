# Source Tree Analysis (Annotated)

## Top-level

```
./
├── backend/                  # Backend services
│   └── laravel/              # Laravel 12 API (PHP 8.2)
├── frontend/                 # Flutter application (Dart)
├── docs/                     # Generated + curated project documentation
├── _bmad/                    # Local BMAD installation (gitignored)
├── _bmad-output/             # Local BMAD outputs (gitignored)
└── .cursor/                  # Cursor local files (gitignored)
```

## Backend (`backend/laravel/`)

Typical Laravel layout:

- `app/Http/Controllers/Api/`: API controllers (auth/admin/chat/friends/gyms/space)
- `app/Models/`: Eloquent models (`User`, `Role`, `Gym`, `ChatMessage`, …)
- `database/migrations/`: schema changes (users profile fields, chat messages, gyms, roles)
- `routes/api.php`: API surface and middleware groupings

## Frontend (`frontend/`)

Flutter app layout (selected):

- `lib/src/app.dart`: app bootstrap + role-based routing (admin vs user shell)
- `lib/src/screens/`: screens for admin + user features (chat, friends, gyms, profile, etc.)
- `lib/src/storage/`: token storage

