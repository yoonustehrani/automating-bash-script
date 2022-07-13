#!/bin/bash
# This file creates a systemd service to run a custom shell script
# periodically in background based on the rich power of systemd

read -n 20 -rp "Enter a name for the service: (e.g. myService) " service
read -p "Enter path to the script you want the service to run : " target_path

target_path=$(sed "s_\~_${HOME}_" <<< $target_path)
script=$(realpath $target_path)
script_name=$(basename $script)

# checking if $script is a real file
if [ ! -f $script ]
then
    echo -e "\tError ====>  $script_name is not a file"
    exit 1
# checking if $script is a shell script
elif [ $(file --mime-type -b $script) != "text/x-shellscript" ]
then
    echo -e "\tError ====>  $script_name is not a shell script file"
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
        sudo adduser --no-create-home --disabled-login --gecos ""  $1
        if id $1 > /dev/null 2>&1;
        then 
            echo " - User $1 created"
        else
            echo " - Error User $1 couldn't be created"
            exit 2
        fi
    fi
}

user="sysbot"
check_user_or_create $user

# create custom environment configuration
# if [ ! -f /etc/default/$service ]; then
#   echo "mem_exceed_limit=50" | sudo tee /etc/default/$service
# fi
# sudo chmod 600 /etc/default/$service
# echo "Created Env file : /etc/default/$service"

# service systemd path
shared_service_dir=/lib/systemd/system
serviced_path=$shared_service_dir/$service.service

create_service_file() {
    sed "s_\${scriptpath}_${script}_" ./service.service.stub \
    | sed "s_\${workdir}_$(realpath .)_" \
    | sed "s#\${username}#${user}#g" \
    | sed "s_\${usergroup}_${user}_" \
    | sed "s_\${logdir}_/var/log/memchecker_" \
    | sed "s_\${service}_${service}_" \
    | sudo tee $serviced_path > /dev/null
}
# making service file from stub
echo "+ Creating service file ..."
create_service_file

echo "++ Giving desired permissions to the $service.service file ..."
sudo chmod 655 $serviced_path

echo "+++ Done! service file created: $serviced_path"

# copiying timer file for the very service
ask_user_to_input_seconds() {
    echo -e "How often do you want the timer to run ?"
    while true;
    do
        echo "(enter the number in seconds e.g. 60)" 
        read -p "_ " seconds
        if [ -n "$seconds" ] && [[ "$seconds" =~ ^[0-9]+$ ]]
        then
            echo "The script will be running every $seconds seconds." 
            break
        fi
    done
    timer_value="$seconds"
}

echo "--- Making timer file"

# determining timer mode
echo -e "Which kind of timer do you tend to use for $service.timer ?\n\t1.Unit active Seconds\t2.Timer active Seconds\n\t3.Boot seconds\t4.Calendar time (Currently not available)"
read -p "_ " mode_for_timer
case $mode_for_timer in
    1)
        timer_mode="OnUnitActiveSec"
        ask_user_to_input_seconds
        ;;
    2)
        timer_mode="OnActiveSec"
        ask_user_to_input_seconds
        ;;
    3)
        timer_mode="OnBootSec"
        ask_user_to_input_seconds
        ;;
    4)
        echo "Sorry, Calendar mode currently not available."
        # timer_mode="OnCalendar"
        exit 0
        ;;
    *)
        echo "Active Seconds mode will be used by default."
        timer_mode="OnUnitActiveSec"
        ask_user_to_input_seconds
        ;;
esac

# creating timer file
create_timer_file() {
    sed "s_\${service}_${service}_" ./service.timer.stub \
    | sed "s#\${timer_mode}#${timer_mode}#g" \
    | sed "s#\${timer_value}#${timer_value}#g" \
    | sudo tee $shared_service_dir/$service.timer > /dev/null
}

echo "--- Creating timer file"
create_timer_file

echo "-- Giving desired permissions to the $service.timer file ..."
sudo chmod 655 $shared_service_dir/$service.timer

echo "- Timer file created"

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