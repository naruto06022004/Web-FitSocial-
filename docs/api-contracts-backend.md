# API Contracts — Backend (Laravel) _(Quick Scan)_

> Source of truth: `backend/laravel/routes/api.php`.  
> This document is **quick-scan** and may be expanded in a Deep Scan. _(To be generated)_

## Authentication

- `POST /auth/login`
- `POST /auth/register`
- `POST /auth/logout` *(auth:sanctum)*
- `GET /me` *(auth:sanctum)*
- `PUT /me` *(auth:sanctum)*

## Public

- `GET /gyms`

## Posts *(auth:sanctum)*

- `GET /posts`
- `POST /posts`
- `GET /posts/{id}`
- `PUT/PATCH /posts/{id}`
- `DELETE /posts/{id}`

## Friends *(auth:sanctum)*

- `GET /friends`

## Training Space *(auth:sanctum)*

- `GET /training-space/peers`

## Chat *(auth:sanctum)*

- `GET /chat/conversations`
- `GET /chat/directory`
- `GET /chat/messages`
- `POST /chat/messages`
- `PUT /chat/seen/{user}`

## Admin *(auth:sanctum + ensure.admin)*

### Users

- `GET /admin/users`
- `GET /admin/users/{user}`
- `POST /admin/users`
- `PUT /admin/users/{user}`
- `DELETE /admin/users/{user}`

### Roles

- `GET /admin/roles`
- `POST /admin/roles`
- `PUT /admin/roles/{role}`
- `DELETE /admin/roles/{role}`

