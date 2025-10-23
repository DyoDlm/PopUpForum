#!/bin/bash
# ===============================================
# Script d'installation Nginx + SSH + UFW + CGI
# pour Raspberry Pi (Raspberry Pi OS / Debian)
# Référence : nginx.org + doc Raspberry Pi + fcgiwrap
# ===============================================

set -e  # stop si erreur

echo "=== 🔧 Mise à jour du système ==="
sudo apt update && sudo apt upgrade -y

echo "=== 🌐 Installation des paquets nécessaires ==="
sudo apt install -y nginx ufw openssh-server fcgiwrap

echo "=== 🚀 Activation des services nginx, ssh et fcgiwrap ==="
sudo systemctl enable --now nginx
sudo systemctl enable --now ssh
sudo systemctl enable --now fcgiwrap.socket

echo "=== 🔒 Configuration du pare-feu UFW ==="
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'   # ouvre 80 et 443
sudo ufw --force enable
sudo ufw status verbose

echo "=== 📂 Création de la structure de répertoires du site ==="
sudo mkdir -p /var/www/monsite/{html/errors,cgi-bin,logs,ssl}
sudo chown -R www-data:www-data /var/www/monsite
sudo chmod -R 755 /var/www/monsite

echo "=== 🧱 Création de la page d’accueil et des pages d’erreur ==="
sudo tee /var/www/monsite/html/index.html > /dev/null <<'EOF'
<!DOCTYPE html>
<html>
<head><title>Bienvenue sur mon Raspberry Pi !</title></head>
<body>
<h1>Page d'accueil Nginx sur Raspberry Pi</h1>
<p>Tout fonctionne correctement 🎉</p>
<a href="/cgi-bin/hello.cgi">Test CGI</a>
</body>
</html>
EOF

sudo tee /var/www/monsite/html/errors/404.html > /dev/null <<'EOF'
<h1>Erreur 404 - Page non trouvée</h1>
<p>Oups, le fichier demandé n'existe pas.</p>
EOF

sudo tee /var/www/monsite/html/errors/50x.html > /dev/null <<'EOF'
<h1>Erreur serveur (5xx)</h1>
<p>Une erreur interne est survenue.</p>
EOF

echo "=== ⚙️ Création d’un script CGI d’exemple ==="
sudo tee /var/www/monsite/cgi-bin/hello.cgi > /dev/null <<'EOF'
#!/usr/bin/env bash
echo "Content-type: text/html"
echo ""
echo "<html><body><h2>Bonjour depuis CGI sur Raspberry Pi 🎯</h2></body></html>"
EOF
sudo chmod +x /var/www/monsite/cgi-bin/hello.cgi

echo "=== 📝 Configuration de Nginx (site monsite.conf) ==="
sudo tee /etc/nginx/sites-available/monsite.conf > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;

    root /var/www/monsite/html;
    index index.html index.htm index.cgi;

    access_log /var/log/nginx/monsite.access.log;
    error_log /var/log/nginx/monsite.error.log warn;

    error_page 404 /errors/404.html;
    error_page 500 502 503 504 /errors/50x.html;
    location = /errors/404.html { internal; }
    location = /errors/50x.html { internal; }

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.cgi$ {
        gzip off;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass unix:/run/fcgiwrap.socket;
        fastcgi_intercept_errors on;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }
}
EOF

echo "=== 🔗 Activation du site et rechargement de Nginx ==="
sudo ln -sf /etc/nginx/sites-available/monsite.conf /etc/nginx/sites-enabled/monsite.conf
sudo nginx -t && sudo systemctl reload nginx

echo "=== ✅ Installation terminée avec succès ! ==="
echo "Vous pouvez tester depuis un autre appareil :"
hostname -I | awk '{print "➡️  http://"$1"/"}'
echo "Et le script CGI : /cgi-bin/hello.cgi"

