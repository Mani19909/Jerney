#!/bin/bash
# ============================================
# Jerney Blog Platform - EC2 Setup Script
# Ubuntu EC2 Deployment
# ============================================

set -e

echo "🛤️ Setting up Jerney Blog Platform..."
echo "==========================================="

# --------------------------------------------
# Update system
# --------------------------------------------
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y


# --------------------------------------------
# Install Node.js 20.x + npm
# --------------------------------------------
echo "📦 Installing Node.js 20.x..."

sudo apt remove -y nodejs npm || true

sudo apt install -y curl ca-certificates gnupg

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

sudo apt install -y nodejs

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"


# --------------------------------------------
# Install PostgreSQL
# --------------------------------------------
echo "📦 Installing PostgreSQL..."

sudo apt install -y postgresql postgresql-contrib

sudo systemctl enable postgresql
sudo systemctl start postgresql


# --------------------------------------------
# Install Nginx
# --------------------------------------------
echo "📦 Installing Nginx..."

sudo apt install -y nginx

sudo systemctl enable nginx


# --------------------------------------------
# Install PM2
# --------------------------------------------
echo "📦 Installing PM2..."

sudo npm install -g pm2

echo "PM2 version: $(pm2 -v)"


# --------------------------------------------
# Configure PostgreSQL
# --------------------------------------------
echo "🗄️ Configuring PostgreSQL..."

sudo -u postgres psql <<EOF

DO
\$\$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'jerney_user'
   ) THEN
      CREATE USER jerney_user WITH PASSWORD 'jerney_pass_2026';
   END IF;
END
\$\$;


SELECT 'CREATE DATABASE jerney_db OWNER jerney_user'
WHERE NOT EXISTS (
    SELECT FROM pg_database WHERE datname='jerney_db'
)\gexec


GRANT ALL PRIVILEGES ON DATABASE jerney_db TO jerney_user;

\c jerney_db

GRANT ALL ON SCHEMA public TO jerney_user;

EOF


echo "✅ PostgreSQL configured"


# --------------------------------------------
# Setup project directory
# --------------------------------------------
echo "📁 Setting up project..."

sudo mkdir -p /var/www/Jerney

sudo chown -R $USER:$USER /var/www/Jerney


if [ -d "$HOME/Jerney" ]; then
    rsync -av --exclude node_modules \
    $HOME/Jerney/ /var/www/Jerney/
else
    echo "❌ Project folder ~/Jerney not found"
    exit 1
fi


# --------------------------------------------
# Backend install
# --------------------------------------------
echo "📦 Installing backend dependencies..."

cd /var/www/Jerney/backend

npm install


# --------------------------------------------
# Frontend build
# --------------------------------------------
echo "🔨 Building frontend..."

cd /var/www/Jerney/frontend

npm install

npm run build


# --------------------------------------------
# Configure Nginx
# --------------------------------------------
echo "🌐 Configuring Nginx..."

if [ -f "/var/www/Jerney/deploy/Jerney-nginx.conf" ]; then

sudo cp /var/www/Jerney/deploy/Jerney-nginx.conf \
/etc/nginx/sites-available/Jerney

sudo ln -sf \
/etc/nginx/sites-available/Jerney \
/etc/nginx/sites-enabled/Jerney

sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t

sudo systemctl restart nginx

else

echo "⚠️ nginx config missing, skipping"

fi


# --------------------------------------------
# Start backend using PM2
# --------------------------------------------
echo "🚀 Starting backend..."

cd /var/www/Jerney/backend


pm2 delete Jerney-backend || true


pm2 start src/index.js \
--name Jerney-backend


pm2 save


pm2 startup systemd -u $USER --hp /home/$USER


echo ""
echo "==========================================="
echo "🎉 Deployment Completed Successfully"
echo "==========================================="
echo ""

PUBLIC_IP=$(curl -s \
http://169.254.169.254/latest/meta-data/public-ipv4 || true)

echo "Access:"
echo "http://${PUBLIC_IP}"
echo ""

echo "Useful Commands:"
echo "pm2 status"
echo "pm2 logs Jerney-backend"
echo "pm2 restart Jerney-backend"
echo "sudo systemctl restart nginx"