---
title: Hướng dẫn Deploy AWS (miễn phí trước) — Fitnet / Web-FitSocial
---

# Hướng dẫn Deploy AWS (miễn phí trước) — Fitnet / Web-FitSocial

Tài liệu này hướng dẫn bạn deploy **toàn bộ hệ thống** theo hướng **“Free Tier-first”**:

- **Laravel API**: `backend/laravel`
- **Flutter app** (Android/iOS/Web): `frontend/`

Mục tiêu: **làm được nhanh, chi phí thấp nhất**, sau này có thể nâng cấp lên kiến trúc “chuẩn” (RDS/S3/ALB/ECS) khi cần.

---

## 0) Bạn cần “đăng ký” gì trên AWS?

Chỉ cần **1 tài khoản AWS**. Sau đó bạn sẽ “dùng” các dịch vụ sau (bản tối thiểu):

- **EC2**: 1 máy Ubuntu để chạy Nginx + PHP-FPM + Laravel (+ DB nếu muốn rẻ nhất)
- **VPC + Security Group**: network + firewall (miễn phí)
- **IAM**: quản lý quyền (miễn phí)
- **CloudWatch**: theo dõi/log cơ bản (có free tier giới hạn)

Tuỳ chọn (dùng sau):

- **S3**: lưu ảnh/file upload (nên dùng khi bắt đầu có upload)
- **RDS**: database managed (dễ vận hành hơn DB trên EC2)
- **Route 53 / Domain**: domain (domain không miễn phí)

> Khuyến nghị: vào **Billing → Budgets** để đặt cảnh báo chi phí ngay từ đầu.

---

## 1) Loạt ảnh minh hoạ (bạn chỉ cần thả screenshot vào đúng đường dẫn)

Tạo thư mục: `docs/assets/aws/` rồi lưu ảnh theo tên dưới đây (hoặc đổi tên tuỳ bạn). Khi có ảnh, tài liệu sẽ tự hiển thị.

1) AWS Console → **EC2** tạo instance  
![AWS EC2 create](./assets/aws/01-ec2-create.png)

2) EC2 → **Security Group** mở port 22/80/443  
![AWS Security Group inbound rules](./assets/aws/02-security-group.png)

3) EC2 → **Elastic IP / Public IPv4** (tuỳ chọn)  
![AWS EC2 public ip](./assets/aws/03-public-ip.png)

4) Trỏ domain (nếu có) về IP (Route 53 hoặc DNS nhà cung cấp domain)  
![DNS A record](./assets/aws/04-dns-a-record.png)

5) SSH vào server Ubuntu  
![SSH connect](./assets/aws/05-ssh-connect.png)

6) Nginx site + test API  
![Nginx site](./assets/aws/06-nginx-site.png)

7) Certbot (HTTPS)  
![Certbot](./assets/aws/07-certbot.png)

8) Flutter config base URL + build APK  
![Flutter build](./assets/aws/08-flutter-build.png)

---

## 2) Kiến trúc “miễn phí trước” (khuyến nghị cho giai đoạn đầu)

### 2.1 Bản tối thiểu (rẻ nhất)
- **1 EC2 Ubuntu** chạy:
  - Nginx
  - PHP-FPM
  - Laravel API
  - **DB cài trên EC2** (MySQL/MariaDB) — rẻ nhất, đổi sang RDS sau

### 2.2 Khi nào nên nâng cấp?
- **Có upload ảnh nhiều** → chuyển ảnh sang **S3**
- **Muốn DB ổn định/backup dễ** → chuyển DB sang **RDS**
- **Muốn scale** → thêm **ALB / ECS**, v.v.

---

## 3) Chuẩn bị trên AWS (EC2 + Security Group)

### 3.1 Tạo EC2 (Ubuntu LTS)

- AMI: **Ubuntu 22.04 LTS** (hoặc LTS mới hơn)
- Instance type: ưu tiên **Free Tier eligible** (tuỳ tài khoản/region)
- Storage: đủ dùng (ví dụ 20–30GB)

### 3.2 Security Group inbound rules

Mở tối thiểu:

- **22 (SSH)**: chỉ cho IP của bạn
- **80 (HTTP)**: `0.0.0.0/0`
- **443 (HTTPS)**: `0.0.0.0/0`

> Không mở 3306 ra Internet. Nếu DB nằm trên EC2, chỉ truy cập local. Nếu dùng RDS, chỉ allow từ SG của EC2.

---

## 4) Cài đặt trên server (EC2 Ubuntu)

### 4.1 SSH vào server

Ví dụ:

```bash
ssh -i <your-key>.pem ubuntu@<EC2_PUBLIC_IP>
```

### 4.2 Cài Nginx + PHP + Composer

```bash
sudo apt update -y
sudo apt install -y nginx git unzip
sudo apt install -y php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip php8.2-bcmath
```

Composer:

```bash
cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
composer --version
```

---

## 5) Deploy Laravel API

### 5.1 Lấy source code lên server

```bash
cd /var/www
sudo mkdir -p fitnet
sudo chown -R $USER:$USER /var/www/fitnet
git clone <YOUR_GITHUB_REPO_URL> /var/www/fitnet
cd /var/www/fitnet/backend/laravel
```

### 5.2 Cấu hình môi trường (.env)

```bash
cp .env.example .env
php artisan key:generate
```

Sửa `.env` (gợi ý):

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.your-domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=fitnet
DB_USERNAME=fitnet
DB_PASSWORD=<strong-password>
```

> Nếu bạn dùng RDS thì đổi `DB_HOST/DB_USERNAME/DB_PASSWORD` theo RDS.

### 5.3 Cài dependencies + cache

```bash
composer install --no-dev --optimize-autoloader
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### 5.4 Migrate + seed

```bash
php artisan migrate --force
php artisan db:seed --force
```

> Nếu bạn seed sẵn admin mặc định thì **đổi password ngay** khi lên production.

### 5.5 Phân quyền thư mục

```bash
sudo chown -R www-data:www-data storage bootstrap/cache
sudo chmod -R 775 storage bootstrap/cache
```

---

## 6) Cấu hình Nginx + PHP-FPM

Tạo Nginx site (ví dụ domain: `api.your-domain.com`):

```bash
sudo nano /etc/nginx/sites-available/fitnet-api
```

Nội dung:

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
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/fitnet-api /etc/nginx/sites-enabled/fitnet-api
sudo nginx -t
sudo systemctl reload nginx
sudo systemctl enable nginx
sudo systemctl enable php8.2-fpm
```

---

## 7) HTTPS (Let’s Encrypt — miễn phí)

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.your-domain.com
```

---

## 8) Queue + Scheduler (khuyến nghị)

### 8.1 Scheduler cron

```bash
crontab -e
```

Thêm:

```bash
* * * * * cd /var/www/fitnet/backend/laravel && php artisan schedule:run >> /dev/null 2>&1
```

### 8.2 Queue worker (systemd)

```bash
sudo nano /etc/systemd/system/fitnet-queue.service
```

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

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now fitnet-queue
sudo systemctl status fitnet-queue
```

---

## 9) (Tuỳ chọn) Lưu file lên S3

Nếu app có upload avatar/ảnh, chuyển sang S3 để bền hơn:

```env
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_DEFAULT_REGION=...
AWS_BUCKET=...
```

---

## 10) Flutter: trỏ về API production + build release

### 10.1 Cấu hình API base URL

Mở `frontend/lib/src/api/api_client.dart` và đổi base URL sang production (ví dụ):

- `https://api.your-domain.com/api`

### 10.2 Build release

```bash
cd frontend
flutter pub get
flutter build apk --release
```

---

## 11) Smoke test nhanh

- `POST /api/auth/login` trả `{token, user}`
- `GET /api/me` với header `Authorization: Bearer <token>` chạy OK
- Admin endpoints được bảo vệ (ensure admin middleware)
- Flutter login được và vào đúng màn (admin vs user)

