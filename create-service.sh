#!/bin/bash
# This file creates a systemd service which runs ./memory-checker.sh periodicly

service=memchecker
bash_script=memory-checker.sh
stubfile=$service.service.stub
user="sysbot"

# @param $1 script filename
# @returns script path
get_script_path() {
    script_directory=$(realpath .)
    script_path="$script_directory/$1"
    echo $script_path
}

# checking if the bash script exists
script_path=$(get_script_path $bash_script)
if [ ! -f $script_path ]
then
    echo "*- Error $bash_script script does not exist ($script_path)"
    exit 1
fi

# @arg $1 the username to check
# @returns void
check_user_or_create() {
    echo "Checking user $1 ..."
    if id $1 > /dev/null 2>&1;
    then
        echo " - User $1 already exists"
    else
        echo " - Creating user $1 ..."
        sudo adduser --no-create-home --disabled-login $1
        if id $1 > /dev/null 2>&1;
        then 
            echo " - User $1 created"
        else
            echo " - Error User $1 couldn't be created"
            exit 2
        fi
    fi
}

check_user_or_create $user

# create custom environment configuration
if [ ! -f /etc/default/$service ]; then
  echo "mem_exceed_limit=50" | sudo tee /etc/default/$service
fi
sudo chmod 600 /etc/default/$service
echo "Created Env file : /etc/default/$service"

# service systemd path
shared_service_dir=/lib/systemd/system
serviced_path=$shared_service_dir/$service.service
# making service file from stub
echo "+ Creating service file ..."
sed "s_\${scriptpath}_${script_path}_" $stubfile \
| sed "s_\${workdir}_$(realpath .)_" \
| sed "s#\${username}#${user}#g" \
| sed "s_\${usergroup}_${user}_" \
| sed "s_\${logdir}_/var/log/memchecker_" \
| sed "s_\${service}_${service}_" \
| sudo tee $serviced_path > /dev/null

echo "++ Giving desired permissions to the service file ..."
sudo chmod 655 $serviced_path
echo "+++ Done! service file created: $serviced_path"

# copiying timer file for the very service
echo "-- Creating timer"
sudo cp $service.timer $shared_service_dir/
sudo chmod 655 $shared_service_dir/$service.timer
echo "- Timer created"

echo "*** Reloading systemctl daemon ***"
sudo systemctl daemon-reload


echo "+ starting service $service"
sudo systemctl enable $service.service $service.timer
sudo systemctl start $service.service
sudo systemctl start $service.timer

echo "==========================="
echo "list of $service services available..."
sudo systemctl --no-pager | grep $service

echo "==========================="
echo "list of timers for $service available..."
sudo systemctl list-timers --no-pager | grep $service

echo "==========================="
echo "logs for service $service"
sudo journalctl -u $service.service --no-pager