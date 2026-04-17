# Development Guide (Local)

## Overview

This repository is a multi-part project:

- **Backend**: Laravel API (PHP) intended to run locally with XAMPP + MySQL.
- **Frontend**: Flutter app that consumes the API.

## Backend (Laravel)

### Prerequisites

- PHP 8.2+
- Composer
- MySQL (XAMPP)

### Setup (typical)

- Create MySQL database: `fitnet`
- Configure `backend/laravel/.env` (DB credentials, app key, etc.)
- Run migrations and start the server (commands may vary by your environment)

> See repository docs: `backend/README.md` and `backend/laravel/README.md`.

## Frontend (Flutter)

### Prerequisites

- Flutter SDK

### Run

From `frontend/`:

```powershell
flutter pub get
flutter run
```

