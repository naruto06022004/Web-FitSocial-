# Architecture — Backend (Laravel API) _(Quick Scan)_

## Executive Summary

The backend is a Laravel 12 REST API secured by **Laravel Sanctum** and structured with typical Laravel boundaries:

- Routes defined in `routes/api.php`
- Controllers under `app/Http/Controllers/Api/`
- Models under `app/Models/`
- Database changes under `database/migrations/`

## Tech Stack

- **Language**: PHP `^8.2`
- **Framework**: Laravel `^12.0`
- **Auth**: Laravel Sanctum
- **DB**: MySQL (local dev via XAMPP per root README)

## API Surface

See `docs/api-contracts-backend.md` for the quick catalog.

## Authorization Model (Observed)

- User session: `auth:sanctum`
- Admin area: `ensure.admin` middleware for `/admin/*`

## Data Layer

Eloquent models and migrations define the schema.

- See `docs/data-models-backend.md` _(To be generated)_ for a full, field-level schema.

