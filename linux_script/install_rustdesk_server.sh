#!/bin/bash

[[ `id -u` != 0 ]] && echo "请使用root用户执行此脚本" && exit 1
docker-compose version &>/dev/null
[[ $? != 0 ]] && echo "请先安装docker-compose" && exit 1

[[ -e /opt/rustdesk ]] && rm -rf /opt/rustdesk
mkdir -p /opt/rustdesk
chmod 755 -R /opt/rustdesk
cd /opt/rustdesk
read -p "请输入服务器域名或ip:" server_ip

cat >> compose.yaml << EOF
version: '3'

networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r ${server_ip}:21117
    volumes:
      - /opt/rustdesk:/root
    networks:
      - rustdesk-net
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    ports:
      - 21117:21117
      - 21119:21119
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    volumes:
      - /opt/rustdesk:/root
    networks:
      - rustdesk-net
    restart: unless-stopped
EOF
docker-compose up -d

echo "
查看rustdesk key
docker exec -it hbbr bash
cat id_ed25519.pub
"
