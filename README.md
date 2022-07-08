# Automating bash script

You can use this script to create and manage a systemd-based service to automate running a bash script based on systemd timers.
```
# Project tree
/ automating-bash-script
  |__ create-service.sh (create and start systemd-based service)
  |__ delete-service.sh (stop and delete systemd-based service)
  |__ memchecker.service.stub (systemd-based service stub)
  |__ memchecker.timer (systemd-based timer)
  |__ memory-checker.sh (the example bash script to be automated)
```
## The example bashscript (`memory-checker.sh`)
The `memory-checker.sh` reads memory status from `/proc/meminfo`, calculates the allocated memory and if
the allocated memory exceeded `mem_exceed_limit` value in `/etc/default/memchecker` env file, it logs a message to `/var/log/memchecker/usage.log` 
### Env file (/etc/default/memchecker)
The below variable means that the `memory-checker.sh` will log any memory usage above 50% To the `/var/log/memchecker/usage.log`
```env
mem_exceed_limit=50 # 50%
```
See, quite uncomplicated example for a bash script!

## Create and run
The `create-service.sh` tries to :
1. register a user named `sysbot`
2. create a memchecker.service and memchecker.timer inside `/lib/systemd/system`
3. create env file for `memory-checker.sh` in `/etc/default/memchecker`
4. reload systemctl daemon
5. enable and start `memchecker.service` and `memchecker.timer`
```terminal
# to create and run the service
./create-service.sh
```
