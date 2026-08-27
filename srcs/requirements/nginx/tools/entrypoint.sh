#!/bin/sh
#creation du dossier ssl si pas present (runtime, pas dans l'image)
mkdir -p /etc/nginx/ssl

#generer la certif ici pas au build comme ca si domaine_name change cest pris en charge
if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=FR/ST=IDF/O=42/CN=${DOMAIN_NAME}"
fi
#envoyer domaine name a la conf nginx
envsubst '${DOMAIN_NAME}' < /etc/nginx/nginx.conf.template > /etc/nginx/http.d/default.conf
#lancer en exec et en deamon off pour reprendre le pid 1 
exec nginx -g "daemon off;"
