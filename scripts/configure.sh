#!/bin/bash

sudo pacman -Sy nginx --noconfirm

sudo cp nginx/certbot.service /etc/systemd/system/certbot.service
sudo cp nginx/certbot.timer /etc/systemd/system/certbot.timer
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
sudo systemctl list-timers