# Architecture — Frontend (Flutter App) _(Quick Scan)_

## Executive Summary

The frontend is a Flutter app consuming the Laravel API. It includes a role-based split between:

- **Admin/Staff**: Admin dashboard screens
- **Regular users**: User application shell (social / gyms / profile / friends / chat)

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart (SDK `^3.11.1`)
- **HTTP**: `package:http`
- **Storage**: `flutter_secure_storage`, `shared_preferences`
- **Typography**: `google_fonts`

## App Bootstrap & Routing

- Entry: `frontend/lib/src/app.dart`
- Loads token → calls `/me` → routes based on role

## UI Surface (Observed)

- Admin screens: users, posts, roles, portfolio
- User screens: home, profile, friends, gyms, chat, training space

Full component inventory is deferred to a Deep Scan. _(To be generated)_

