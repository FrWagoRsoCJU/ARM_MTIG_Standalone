#!/bin/bash

echo "Déplacement des fichiers de config vers /root"
mv ./config /root
sleep 5

echo "Installation Docker"
opkg install -V3 ./ipk/docker_20.10.5_armhf.ipk
sleep 5

echo "Arrêt Docker"
/etc/init.d/dockerd stop
sleep 5

echo "Déplacement docker vers la carte SD"
cp -r /home/docker /media/sd
rm -r /home/docker
cp /root/config/daemon.json /etc/docker/daemon.json

echo "Démarrage Docker"
/etc/init.d/dockerd start
sleep 5

echo "Chargement de l'image Mosquitto"
docker load < ./images/i_mosquitto

echo "Création des volumes pour Mosquitto"	
docker volume create v_mosquitto_data
docker volume create v_mosquitto_log

echo "Démarrage Mosquitto"
docker run -d \
	--name c_mosquitto \
	--restart=unless-stopped \
	--net=host \
	-v /root/config/mosquitto.conf:/mosquitto/config/mosquitto.conf \
	-v v_mosquitto_data:/mosquitto/data \
	-v v_mosquitto_log:/v_mosquitto_data \
	eclipse-mosquitto:latest

echo "Chargement de l'image InfluxDB"
docker load < ./images/i_influxdb

echo "Création du volume pour InfluxDB"
docker volume create v_influxdb

echo "Démarrage InfluxDB"
docker run -d \
	--name c_influxdb \
	--restart unless-stopped \
	--net=host \
	-v v_influxdb:/var/lib/influxdb \
	influxdb:1.8.10

echo "Chargement de l'image Grafana"
docker load < ./images/i_grafana

echo "Création du volume pour Grafana"
docker volume create v_grafana

echo "Démarrage Grafana"
docker run -d \
	--name c_grafana \
	--restart unless-stopped \
	--net=host \
	-v v_grafana:/var/lib/grafana \
	-e GF_PANELS_DISABLE_SANITIZE_HTML=true \
	grafana/grafana:latest

echo "Chargement de l'image Telegraf"
docker load < ./images/i_telegraf

echo "Démarrage Telegraf"
docker run -d \
	--restart=unless-stopped \
	--net=host \
	--name=c_telegraf \
	-v /root/config/telegraf.conf:/etc/telegraf/telegraf.conf:ro \
	telegraf:latest