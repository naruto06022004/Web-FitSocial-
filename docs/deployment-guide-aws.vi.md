# Hướng dẫn Deploy (AWS) — Fitnet / Web-FitSocial

Tài liệu này giúp bạn deploy:

- **Laravel API** (`backend/laravel`) lên AWS để mọi người có thể dùng app.
- **Flutter app** (`frontend/`) và cấu hình để gọi đúng API production.

---

## 0) Kiến trúc khuyến nghị

- **EC2 (Ubuntu)**: chạy Nginx + PHP-FPM + Laravel
- **RDS (MySQL)**: database production
- **S3**: lưu file người dùng upload (avatar, …) nếu cần
- **Route 53 + HTTPS**: domain + TLS

Nếu muốn làm nhanh để demo, bạn có thể cài MySQL cùng EC2 (không khuyến nghị lâu dài).

---

## 1) Chuẩn bị trên AWS

### 1.1 Tạo RDS MySQL

- Tạo instance **RDS MySQL**
- Ghi lại:
  - DB host, port, tên database (ví dụ `fitnet`)
  - username/password
- Security group: chỉ mở inbound **3306** từ **security group của EC2**

### 1.2 Tạo EC2

- Ubuntu LTS
- Security group inbound:
  - **22** (SSH) từ IP của bạn
  - **80** (HTTP) từ mọi nơi
  - **443** (HTTPS) từ mọi nơi

### 1.3 (Tuỳ chọn) Tạo S3 bucket

Tạo S3 bucket cho uploads (ví dụ `fitnet-prod-assets`).

---

## 2) Cài đặt trên server (EC2 Ubuntu)

SSH vào EC2, rồi cài dependencies:

```bash
sudo apt update -y
sudo apt install -y nginx git unzip
sudo apt install -y php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip php8.2-bcmath
```

Cài Composer:

```bash
cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
composer --version
```

---

## 3) Deploy Laravel API

### 3.1 Lấy source code lên server

```bash
cd /var/www
sudo mkdir -p fitnet
sudo chown -R $USER:$USER /var/www/fitnet
git clone <YOUR_GITHUB_REPO_URL> /var/www/fitnet
cd /var/www/fitnet/backend/laravel
```

### 3.2 Cấu hình môi trường (.env)

```bash
cp .env.example .env
php artisan key:generate
```

Sửa `.env` (giá trị production):

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://api.your-domain.com`
- `DB_CONNECTION=mysql`
- `DB_HOST=<RDS_HOST>`
- `DB_PORT=3306`
- `DB_DATABASE=fitnet`
- `DB_USERNAME=<RDS_USER>`
- `DB_PASSWORD=<RDS_PASSWORD>`

Sanctum (mobile token) dùng Bearer token, thường không cần cấu hình `stateful` như SPA.

### 3.3 Cài dependencies + cache

```bash
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### 3.4 Migrate + seed

```bash
php artisan migrate --force
php artisan db:seed --force
```

> Nếu bạn giữ user admin seed mặc định (ví dụ trong `backend/README.md`) thì **đổi password ngay** khi lên production.

### 3.5 Phân quyền thư mục

```bash
sudo chown -R www-data:www-data /var/www/fitnet/backend/laravel/storage /var/www/fitnet/backend/laravel/bootstrap/cache
sudo chmod -R 775 /var/www/fitnet/backend/laravel/storage /var/www/fitnet/backend/laravel/bootstrap/cache
```

---

## 4) Cấu hình Nginx + PHP-FPM

Tạo Nginx site (ví dụ domain: `api.your-domain.com`):

```bash
sudo nano /etc/nginx/sites-available/fitnet-api
```

Nội dung (chỉnh domain + path cho đúng):

```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    root /var/www/fitnet/backend/laravel/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }

    location ~* \.(jpg|jpeg|png|gif|css|js|ico|svg)$ {
        expires 7d;
        access_log off;
    }
}
```

Enable site + reload:

```bash
sudo ln -s /etc/nginx/sites-available/fitnet-api /etc/nginx/sites-enabled/fitnet-api
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl enable nginx
sudo systemctl enable php8.2-fpm
```

---

## 5) HTTPS (Let’s Encrypt)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.your-domain.com
```

---

## 6) Queue + Scheduler (khuyến nghị)

Nếu bạn có reminders, streak jobs, notifications… thì nên bật:

### 6.1 Scheduler cron

```bash
crontab -e
```

Thêm:

```bash
* * * * * cd /var/www/fitnet/backend/laravel && php artisan schedule:run >> /dev/null 2>&1
```

### 6.2 Queue worker (systemd)

Tạo service:

```bash
sudo nano /etc/systemd/system/fitnet-queue.service
```

Ví dụ:

```ini
[Unit]
Description=Fitnet Laravel Queue Worker
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/fitnet/backend/laravel
ExecStart=/usr/bin/php artisan queue:work --sleep=3 --tries=3 --timeout=90
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now fitnet-queue
sudo systemctl status fitnet-queue
```

---

## 7) Lưu file lên S3 (tuỳ chọn)

Nếu bạn lưu avatar/uploads, cấu hình filesystem của Laravel:

- set `.env`:
  - `FILESYSTEM_DISK=s3`
  - `AWS_ACCESS_KEY_ID=...`
  - `AWS_SECRET_ACCESS_KEY=...`
  - `AWS_DEFAULT_REGION=...`
  - `AWS_BUCKET=...`

---

## 8) Flutter: trỏ về API production

### 8.1 Cấu hình API base URL

Tìm chỗ app Flutter set base URL (thường là `frontend/lib/src/api/api_client.dart`) và đổi thành:

- `https://api.your-domain.com/api`

### 8.2 Build release

Android (APK/AAB):

```bash
cd frontend
flutter pub get
flutter build apk --release
```

iOS: build và publish qua TestFlight/App Store (cần macOS + Xcode).

---

## 9) Checklist test nhanh (Smoke test)

- `POST /api/auth/login` trả `{token, user}`
- `GET /api/me` với header `Authorization: Bearer <token>` chạy OK
- Admin endpoints có bảo vệ (ensure admin middleware)
- Flutter login được và vào đúng màn (admin vs user)

