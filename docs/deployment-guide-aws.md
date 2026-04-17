# Deployment Guide (AWS) — Fitnet / Web-FitSocial

This guide deploys:

- **Laravel API** (`backend/laravel`) to AWS so others can use the app.
- **Flutter app** (`frontend/`) configured to call the deployed API.

---

## 0) Architecture (recommended)

- **EC2 (Ubuntu)**: runs Nginx + PHP-FPM + Laravel app
- **RDS (MySQL)**: production database
- **S3**: user-uploaded assets (avatars, etc.) if/when needed
- **Route 53 + HTTPS**: custom domain + TLS

If you want a simpler start, you can deploy DB on the same EC2 (not recommended long-term).

---

## 1) AWS Setup

### 1.1 Create RDS MySQL

- Create **RDS MySQL** instance
- Note:
  - DB host, port, database name (e.g. `fitnet`)
  - username/password
- Security group: allow inbound **3306** only from your **EC2 security group**

### 1.2 Create EC2 instance

- Ubuntu LTS
- Security group inbound:
  - **22** (SSH) from your IP
  - **80** (HTTP) from anywhere
  - **443** (HTTPS) from anywhere

### 1.3 (Optional) Create S3 bucket

Create an S3 bucket for uploads (e.g. `fitnet-prod-assets`).

---

## 2) Server provisioning (EC2 Ubuntu)

SSH into the instance, then install dependencies:

```bash
sudo apt update -y
sudo apt install -y nginx git unzip
sudo apt install -y php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip php8.2-bcmath
```

Install Composer:

```bash
cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
composer --version
```

---

## 3) Deploy Laravel API

### 3.1 Get code onto server

```bash
cd /var/www
sudo mkdir -p fitnet
sudo chown -R $USER:$USER /var/www/fitnet
git clone <YOUR_GITHUB_REPO_URL> /var/www/fitnet
cd /var/www/fitnet/backend/laravel
```

### 3.2 Environment config

```bash
cp .env.example .env
php artisan key:generate
```

Edit `.env` (production values):

- `APP_ENV=production`
- `APP_DEBUG=false`
- `APP_URL=https://api.your-domain.com`
- `DB_CONNECTION=mysql`
- `DB_HOST=<RDS_HOST>`
- `DB_PORT=3306`
- `DB_DATABASE=fitnet`
- `DB_USERNAME=<RDS_USER>`
- `DB_PASSWORD=<RDS_PASSWORD>`

Sanctum (mobile token mode) uses Bearer tokens, so you typically don’t need SPA stateful settings.

### 3.3 Install dependencies

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

> If you keep the default admin seed user (example in `backend/README.md`), change the password immediately in production.

### 3.5 Permissions

```bash
sudo chown -R www-data:www-data /var/www/fitnet/backend/laravel/storage /var/www/fitnet/backend/laravel/bootstrap/cache
sudo chmod -R 775 /var/www/fitnet/backend/laravel/storage /var/www/fitnet/backend/laravel/bootstrap/cache
```

---

## 4) Nginx + PHP-FPM configuration

Create an Nginx site (example domain: `api.your-domain.com`):

```bash
sudo nano /etc/nginx/sites-available/fitnet-api
```

Use this config (adjust domain + paths):

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

## 6) Queue + Scheduler (recommended)

If you add reminders, streak jobs, notifications, etc., you’ll want:

### 6.1 Scheduler cron

```bash
crontab -e
```

Add:

```bash
* * * * * cd /var/www/fitnet/backend/laravel && php artisan schedule:run >> /dev/null 2>&1
```

### 6.2 Queue worker (systemd)

Create service:

```bash
sudo nano /etc/systemd/system/fitnet-queue.service
```

Example:

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

## 7) S3 storage (optional)

If you store avatars/uploads, configure Laravel filesystem:

- Set `.env`:
  - `FILESYSTEM_DISK=s3`
  - `AWS_ACCESS_KEY_ID=...`
  - `AWS_SECRET_ACCESS_KEY=...`
  - `AWS_DEFAULT_REGION=...`
  - `AWS_BUCKET=...`

---

## 8) Flutter app: point to production API

### 8.1 Configure API base URL

Find where the Flutter app defines API base URL (likely in `frontend/lib/src/api/api_client.dart`) and set it to:

- `https://api.your-domain.com/api`

### 8.2 Build for release

Android (APK/AAB):

```bash
cd frontend
flutter pub get
flutter build apk --release
```

iOS: build and publish via TestFlight/App Store (requires macOS + Xcode).

---

## 9) Smoke test checklist

- `POST /api/auth/login` returns `{token, user}`
- `GET /api/me` with `Authorization: Bearer <token>` works
- Admin endpoints are protected (ensure admin middleware)
- Flutter app can login and load the correct home (admin vs user)

