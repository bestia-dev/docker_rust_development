#!/usr/bin/env bash

echo " "
echo "\033[0;33m    Bash script to install personal keys and setting into the Rust development container. \033[0m"

# store_personal_keys_and_settings.sh
# repository: https://github.com/bestia-dev/docker_rust_development

# Copy the file personal_keys_and_settings_template.sh into ~/.ssh/personal_keys_and_settings.sh
# There replace the words: 
# 'info@your.mail', 'your_name', 'githubssh1' and 'webserverssh1'
# Call this script with 4 parameters.

# mandatory arguments
if [ ! "$1" ] || [ ! "$2" ] || [ ! "$3" ] || [ ! "$4" ]; then
  echo "\033[0;31m Error: All 4 arguments must be provided !\033[0m"
  echo "Usage:"
  echo "sh store_personal_keys_and_settings.sh info@your.mail your_name githubssh_filename webserverssh_filename"
  echo "Example:"
  echo "sh store_personal_keys_and_settings.sh info@bestia.dev bestia.dev lucianobestia_mac luciano_googlecloud"
  exit 1
fi

echo "info@your.mail: $1";
echo "your_name: $2";
echo "githubssh_filename: $3";
echo "webserverssh_filename: $4";

cp personal_keys_and_settings_template.sh ~/.ssh/personal_keys_and_settings.sh
cp sshadd_template.sh ~/.ssh/sshadd.sh

sed -i.bak "s/info@your.mail/$1/g" ~/.ssh/personal_keys_and_settings.sh
sed -i.bak "s/your_name/$2/g" ~/.ssh/personal_keys_and_settings.sh
sed -i.bak "s/githubssh1/$3/g" ~/.ssh/personal_keys_and_settings.sh
sed -i.bak "s/webserverssh1/$4/g" ~/.ssh/personal_keys_and_settings.sh

sed -i.bak "s/githubssh1/$3/g" ~/.ssh/sshadd.sh
sed -i.bak "s/webserverssh1/$4/g" ~/.ssh/sshadd.sh

