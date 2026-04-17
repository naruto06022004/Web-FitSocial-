# Web-FitSocial (Fitnet) — Project Overview

## Executive Summary

Web-FitSocial (Fitnet) is a gym / fitness social network app composed of:

- **Backend**: Laravel API (PHP) with **Sanctum** authentication and MySQL (XAMPP in local dev).
- **Frontend**: Flutter app (Dart) for user and admin experiences (admin dashboard, posts/users management, plus social features like friends, chat, nearby gyms).

## Repository Structure (High-level)

- `backend/laravel/`: Laravel API (routes, controllers, models, migrations)
- `frontend/`: Flutter app (UI screens, API client, token storage)
- `_bmad/`, `_bmad-output/`: Local BMAD framework folders (gitignored)

## Key Business Domains (Observed)

- **Authentication & Profiles**
  - Login / register
  - Current user (`/me`) read/update
  - Roles (admin/staff/user)
- **Social Feed / Posts**
  - CRUD posts via API resource
- **Friends**
  - Friends list
- **Chat**
  - Conversations, directory, messages, mark seen
- **Gyms**
  - Gym listing (public)
  - Nearby gyms UI on client
- **Training Space**
  - Peer discovery endpoint
- **Admin Operations**
  - Admin users CRUD
  - Roles CRUD

## Current UX Split (Observed)

The Flutter app routes users by role:

- **Admin / Staff** → Admin dashboard screens
- **Regular users** → User application shell (social / gyms / profile / friends / chat)

## Where to Look Next

- **Backend API endpoints**: `docs/api-contracts-backend.md` (and `backend/laravel/routes/api.php`)
- **Backend data models/migrations**: `docs/data-models-backend.md`
- **Source tree**: `docs/source-tree-analysis.md`

