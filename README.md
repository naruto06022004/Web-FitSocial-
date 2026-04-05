# Fitnet (Gym Social Network) – Flutter + Laravel + XAMPP

Dự án gồm 2 phần:

- `frontend/`: Flutter app (đăng nhập + dashboard quản lý bài post & người dùng)
- `backend/`: Laravel API (Sanctum auth + CRUD posts/users) chạy với MySQL (XAMPP)

## Yêu cầu cài đặt (Windows)

### 1) XAMPP (MySQL + Apache + PHP)

- Cài XAMPP, mở **XAMPP Control Panel**
- Start **Apache** và **MySQL**
- Tạo database: `fitnet`

> Lưu ý: máy bạn hiện chưa có `php` trong PATH, nên Laravel chưa thể scaffold tự động. Xem hướng dẫn trong `backend/README.md`.

### 2) Composer

- Cài Composer cho Windows (để dùng `composer create-project ...`)

### 3) Flutter

Bạn đã có Flutter (mình kiểm tra được `flutter --version` chạy OK).

## Chạy nhanh

### Backend (Laravel API)

Xem `backend/README.md`.

### Frontend (Flutter)

```powershell
cd frontend
flutter pub get
flutter run
```

## Kiến trúc tính năng

- Auth: đăng nhập lấy token (Sanctum), lưu token trong app
- Dashboard:
  - Quản lý Posts: list / create / update / delete
  - Quản lý Users (admin): list / create / update / delete

