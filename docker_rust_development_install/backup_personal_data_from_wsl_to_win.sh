#!/bin/sh

echo " "
echo "\033[0;33m    Bash script to backup personal data from WSL2 to windows \033[0m"

# backup_personal_data_from_wsl_to_win.sh
# repository: https://github.com/bestia-dev/docker_rust_development

# This backup of personal data can then survive the reset of the WSL2 virtual machine.

win_userprofile="$(cmd.exe /c "<nul set /p=%UserProfile%" 2>/dev/null)"
WSLWINUSERPROFILE="$(wslpath $win_userprofile)"
echo $WSLWINUSERPROFILE/.ssh

# TODO: compress is more user friendly
cp -v ~/.ssh/ $WSLWINUSERPROFILE/.ssh/

echo " "
