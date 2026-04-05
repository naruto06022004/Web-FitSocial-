# Backend (Laravel API) – Setup với XAMPP

## Mục tiêu

Backend là **Laravel REST API** dùng:

- **Laravel Sanctum**: đăng nhập + token
- **MySQL (XAMPP)**: lưu users/posts
- **Role**: `admin` có quyền quản lý users; user thường chỉ CRUD posts của mình

## 1) Cài PHP + Composer để tạo Laravel

Máy bạn hiện chưa nhận lệnh `php`/`composer`. Cách nhanh nhất:

### Option A (khuyến nghị): dùng PHP của XAMPP + thêm PATH

1. Cài XAMPP
2. Thêm PATH:
   - Ví dụ: `C:\xampp\php`
3. Mở PowerShell mới và kiểm tra:

```powershell
php -v
```

### Cài Composer

Sau khi có PHP, cài Composer và kiểm tra:

```powershell
composer --version
```

## 2) Tạo Laravel project trong thư mục `backend/laravel`

Từ thư mục gốc dự án:

```powershell
composer create-project laravel/laravel backend/laravel
cd backend/laravel
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\\Sanctum\\SanctumServiceProvider"
```

## 2.1) Chép code API mẫu (stubs) vào Laravel

Trong repo mình đã chuẩn bị sẵn code mẫu tại `backend/laravel-stubs/`.

Sau khi tạo Laravel xong, bạn chép các file trong `backend/laravel-stubs/` vào `backend/laravel/` theo đúng đường dẫn tương ứng:

- `routes/api.php`
- `app/Models/Post.php`
- `app/Http/Controllers/Api/*`
- `app/Http/Middleware/EnsureAdmin.php`
- `database/migrations/*`
- `database/seeders/DatabaseSeeder.php`

Sau đó đăng ký middleware trong `app/Http/Kernel.php`:

- Thêm vào `$routeMiddleware`:
  - `'ensure.admin' => \App\Http\Middleware\EnsureAdmin::class,`

## 3) Cấu hình database (XAMPP MySQL)

Sửa `backend/laravel/.env`:

- `DB_CONNECTION=mysql`
- `DB_HOST=127.0.0.1`
- `DB_PORT=3306`
- `DB_DATABASE=fitnet`
- `DB_USERNAME=root`
- `DB_PASSWORD=` (mặc định XAMPP thường để trống)

## 4) Chạy migrate + seed admin

```powershell
php artisan migrate
php artisan db:seed
```

Seed sẽ tạo admin mặc định (mình sẽ cung cấp trong code):

- Email: `admin@fitnet.local`
- Password: `Password123!`

## 5) Run API

```powershell
php artisan serve --host=127.0.0.1 --port=8000
```

## API endpoints (contract để Flutter dùng)

- `POST /api/auth/login` → `{token, user}`
- `POST /api/auth/logout`
- `GET /api/me`

Posts (yêu cầu auth):
- `GET /api/posts`
- `POST /api/posts`
- `GET /api/posts/{id}`
- `PUT /api/posts/{id}`
- `DELETE /api/posts/{id}`

Users (admin-only):
- `GET /api/admin/users`
- `POST /api/admin/users`
- `PUT /api/admin/users/{id}`
- `DELETE /api/admin/users/{id}`

