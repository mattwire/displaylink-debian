#!/bin/sh
xrandr --output eDP1 --primary --auto
sudo /bin/systemctl stop displaylink.service
