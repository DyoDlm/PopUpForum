#	MISE EN PLACE
sudo apt update
sudo apt upgrade -y
sudo apt install -y nginx ufw

#	DEMARAGE SERVEUR
sudo systemctl enable --now nginx
sudo systemctl status nginx    # pour vérifier qu'il tourne
# tester avec : curl -I http://localhost


#	ENABLE SSH
sudo raspi-config nonint do_ssh 0   # 0 = enable
# ou : sudo raspi-config  -> Interfacing Options -> SSH -> Enable
#

sudo apt install -y openssh-server
sudo systemctl enable --now ssh
sudo systemctl status ssh


#	ENABLE FIREWALL
sudo ufw allow OpenSSH
# vérifier les profils disponibles (utile pour nginx)
sudo ufw app list



#	AUTORISATIONS
sudo ufw allow 'Nginx HTTP'    # ouvre le port 80
sudo ufw allow 'Nginx HTTPS'   # ouvre le port 443 (optionnel si tu veux HTTPS)
# ou : sudo ufw allow 'Nginx Full'  # ouvre 80 et 443
sudo ufw enable
sudo ufw status verbose


#	PERMISSIONS --> A VERIFIER
sudo chown -R www-data:www-data /var/www/monsite
sudo chmod -R 755 /var/www/monsite/html
sudo chmod -R 700 /var/www/monsite/logs /var/www/monsite/ssl
sudo chmod +x /var/www/monsite/html/cgi/*.cgi


#	CGI ? 
sudo apt install -y fcgiwrap
# sur certaines distros il faut aussi spawn-fcgi, ou activer la socket systemd fcgiwrap.socket
sudo systemctl enable --now fcgiwrap.socket
sudo systemctl status fcgiwrap.socket


#	RECHARGER

sudo ln -s /etc/nginx/sites-available/monsite.conf /etc/nginx/sites-enabled/monsite.conf
sudo nginx -t
sudo systemctl reload nginx




#	ARBORESSENCE DE FICHIERS
/var/www/monsite/
├── html/
│   ├── index.html
│   ├── Localisation.html
│   ├── News.html
│   ├── Forum.html
│   ├── FormulaireEvent.html
│   ├── FormulaireStand.html
│   ├── IdeasBox.html
│   ├── Agenda.js
│   ├── assets/
│   │   ├── css/
│   │   │   └── style.css
│   │   ├── js/
│   │   │   ├── main.js
│   │   │   └── map.js
│   │   └── images/
│   │       ├── logo.png
│   │       └── background.jpg
│   ├── includes/
│   │   ├── header.html
│   │   ├── footer.html
│   │   └── menu.html
│   ├── errors/
│   │   ├── 404.html
│   │   └── 50x.html
│   └── cgi/
│       ├── submit_event.cgi
│       ├── submit_stand.cgi
│       ├── contact.cgi
│       └── mail_handler.cgi
├── logs/
│   ├── access.log
│   └── error.log
└── ssl/
    ├── cert.pem
    └── privkey.pem

/etc/nginx/
├── nginx.conf
├── fastcgi_params
├── sites-available/
│   └── monsite.conf
└── sites-enabled/
    └── monsite.conf -> ../sites-available/monsite.conf
/var/log/nginx/
├── monsite.access.log
└── monsite.error.log

#	Conseils de sécurité & bonnes pratiques rapides

-Toujours autoriser OpenSSH dans UFW avant ufw enable.


-Tester la configuration sudo nginx -t à chaque modification pour éviter erreurs et coupures. 
DigitalOcean
+1

Pour scripts CGI, privilégier fcgiwrap ou déporter le travail dynamique à un backend (PHP-FPM, uWSGI, Node.js, etc.) plutôt que de lancer des scripts shell non contrôlés. 
Debian Manpages
+1

Pour mise en production et accès public : passer en HTTPS (Certbot / Let’s Encrypt) et rediriger HTTP → HTTPS. nginx.org a une section “Building TLS/SSL” et des exemples (voir docs et exemples). 
Nginx
+1
