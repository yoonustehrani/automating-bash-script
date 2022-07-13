#!/bin/bash

user="sysbot"
read -n 20 -p "Enter the name of service: " service

if ! systemctl status $service.service > /dev/null 2>&1;
then
    echo "No such service in systemd unit"
fi

# deleting the user
if id $user > /dev/null 2>&1;
then
    echo "deleting user $user"
    sudo userdel -r $user > /dev/null 2>&1
fi

shared_service_dir=/lib/systemd/system

echo "+ Stopping service $service"
sudo systemctl stop $service.timer
sudo systemctl stop $service.service
sudo systemctl disable $service.service $service.timer
echo "++ Stopped and disabled systemd services: $service"

sudo rm $shared_service_dir/$service.service
sudo rm $shared_service_dir/$service.timer
echo "+++ Deleted files for $service in /lib/systemd/system"

echo "*** Restarting systemd daemon ***"
sudo systemctl daemon-reload

echo "==========================="
echo "list of $service services still available..."
sudo systemctl --no-pager | grep $service

echo "==========================="
echo "list of timers for $service still available..."
sudo systemctl list-timers --no-pager | grep $service