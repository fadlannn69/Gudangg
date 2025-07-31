#!/bin/bash

# === Konfigurasi dasar 
IMAGE_NAME="fadlannn69/gudang:latest"      
APP_DIR="/home/ubuntu/backend"                
CONTAINER_NAME="gudang"
DB_NAME="gudkoptell"                          
SERVER_NAME="gudang.koptel.com"              

# ========== Mulai Setup ==========

echo "Update sistem..."
sudo apt update && sudo apt upgrade -y

echo "Install Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo " Install PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib

echo " Install Nginx..."
sudo apt install -y nginx
sudo systemctl enable nginx
sudo ufw allow 'Nginx Full'

echo " Buat direktori aplikasi jika belum ada..."
mkdir -p $APP_DIR

echo " Menarik image Docker: $IMAGE_NAME"
docker pull $IMAGE_NAME

echo " Menghentikan container lama (jika ada)..."
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

echo " Menjalankan container $CONTAINER_NAME..."
docker run -d \
  --name $CONTAINER_NAME \
  -p 8000:8000 \
  -v $APP_DIR/.env:/app/.env \
  -v $APP_DIR/ec_private.pem:/app/ec_private.pem \
  -v $APP_DIR/ec_public.pem:/app/ec_public.pem \
  $IMAGE_NAME

echo " Mengonfigurasi Nginx..."
NGINX_CONF="/etc/nginx/sites-available/fastapi"
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $SERVER_NAME;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

echo " Mengaktifkan konfigurasi Nginx..."
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/fastapi
sudo nginx -t && sudo systemctl reload nginx

echo " Restore database dari barang.sql jika tersedia..."
if [ -f "$APP_DIR/barang.sql" ]; then
    sudo -u postgres createdb $DB_NAME 2>/dev/null
    sudo -u postgres psql $DB_NAME < $APP_DIR/barang.sql && \
    echo "Database berhasil di-restore ke $DB_NAME"
else
    echo " File barang.sql tidak ditemukan, skip restore DB"
fi

echo " DEPLOYMENT SELESAI!"
echo " Akses aplikasi di: https://$SERVER_NAME"
