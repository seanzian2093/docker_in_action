#! /bin/bash

touch ./ch4_bind_mnt/example.log
cat > ./ch4_bind_mnt/example.conf << EOF
server {
    listen 80;
    server_name localhost;
    access_log /var/log/nginx/custom.host.access.log main;
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
EOF

CONF_SRC=/ch4_bind_mnt/example.conf
CONF_DST=/etc/nginx/conf.d/default.conf
LOG_SRC=/ch4_bind_mnt/example.log
LOG_DST=/var/log/nginx/custom.host.access.log
docker run -d --name diaweb \
    --mount type=bind,src="$(pwd)/${CONF_SRC}",dst=${CONF_DST}, readonly=true \
    --mount type=bind,src="$(pwd)/${LOG_SRC}",dst=${LOG_DST} \
    -p 80:80 \
    nginx:latest
