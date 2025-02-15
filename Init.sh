#!/bin/bash

### SCRIPT INSTALL SCRIPT
### TESTED WITH DEBIAN ONLY

. /Skyfire-Auto-Installer/configs/root-config

if [ ! -f ./configs/root-config ]; then
    echo "Config file not found! Add configs!"
    exit;
fi

if [ -z "$INSTALL_PATH" ]; then
    echo "Install path config option missing?!"
    exit;
fi

if [ "$1" = "" ]; then
echo ""
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo ""
((NUM++)); echo "- [$NUM] : Install Prerequisites" 
((NUM++)); echo "- [$NUM] : Update Script permissions"
((NUM++)); echo "- [$NUM] : Update Script permissions"
((NUM++)); echo "- [$NUM] : Install Mysql Apt"
((NUM++)); echo "- [$NUM] : Randomize Passwords"
((NUM++)); echo "- [$NUM] : Setup Commands"
echo ""

else

### LETS START
echo ""
echo "##########################################################"
echo "## INIT SCRIPT STARTING...."
echo "##########################################################"
echo ""
export DEBIAN_FRONTEND=noninteractive


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Install Prerequisites"
echo "##########################################################"
echo ""
sudo apt install curl p7zip-full dos2unix gnupg --assume-yes
sudo apt autoremove --assume-yes
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Update permissions"
echo "##########################################################"
echo ""
sudo find /Skyfire-Auto-Installer/ -type d -name ".git" -prune -o -type f -exec dos2unix {} \;
sudo chmod -R 777 /Skyfire-Auto-Installer/
cd /Skyfire-Auto-Installer/scripts/Setup/
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Install MySQL Apt"
echo "##########################################################"
echo ""

# Define the path for the MySQL APT configuration file
MYSQL_APT_CONFIG="/root/mysql-apt-config_all.deb"

# Check if the file already exists
if [ ! -f "$MYSQL_APT_CONFIG" ]; then
    echo "Downloading MySQL APT Config..."
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.14-1_all.deb -O "$MYSQL_APT_CONFIG"
    
    # Install the downloaded package
    DEBIAN_FRONTEND=noninteractive dpkg -i "$MYSQL_APT_CONFIG"
    
    # Update package list
    sudo apt update -y
else
    echo "MySQL APT Config already downloaded at $MYSQL_APT_CONFIG. Skipping download."
fi
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Randomize Passwords"
echo "##########################################################"
echo ""
replace_randomizepass() 
{
    local files="$1"         # File pattern to search for (e.g., *.txt)
    local min_length="${2:-12}"     # Minimum length of the password; default is 12
    local max_length="${3:-16}"     # Maximum length of the password; default is 16

    # Loop through the files matching the pattern
    for file in $files; do
        if [[ -f "$file" ]]; then   # Check if it's a file
            while IFS= read -r line; do
                # Replace "RANDOMIZEPASS" with a new random password
                echo "${line//password123/$(generate_random_password $min_length $max_length)}"
            done < "$file" > "$file.tmp"  # Write the output to a temp file
            mv "$file.tmp" "$file"        # Overwrite the original file
            echo "Processed: $file"
        fi
    done
}
generate_random_password() 
{
    local length=$((RANDOM % (max_length - min_length + 1) + min_length))
    # Use /dev/urandom for generating a random password
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
}
if [ "$RANDOMIZE_PASSWORDS" = "true" ]; then
    replace_randomizepass "/Skyfire-Auto-Installer/configs/*"  # Example: replace in all .txt files
else
    echo "Password randomiztion disabled, the default password is password123"
    echo ""
    if [ "$REMOTE_DB_SETUP" = "true" ]; then
        echo "Its highly recommended to change the remote MYSQL user password as it will be public."
        echo "YOU HAVE BEEN WARNED!"
        echo ""
        while true; do
            read -p "Do you want to change the password? (y/n): " yn
            if [[ "$yn" =~ ^[Yy]$ ]]; then
                read -sp "Enter the new password: " NEW_PASSWORD
                echo ""  # New line after password input
                CONFIG_FILE="/Skyfire-Auto-Installer/configs/root-config"  # Define the config file path
                
                if [[ -f "$CONFIG_FILE" ]]; then
                    sed -i "s|REMOTE_DB_PASS=\"password123\"|REMOTE_DB_PASS=\"$NEW_PASSWORD\"|" "$CONFIG_FILE" && echo "Password updated successfully in $CONFIG_FILE."
                    remote_db_update="true"
                else
                    echo "Error: Configuration file does not exist."
                fi
                break  # Exit the loop after successful update
            elif [[ "$yn" =~ ^[Nn]$ ]]; then
                echo "Operation cancelled."
                break  # Exit the loop if the operation is cancelled
            else
                echo "Invalid input. Please enter 'y' for yes or 'n' for no."
            fi
        done
    fi
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Commands"
echo "##########################################################"
echo ""
echo "All passwords are stored in - /Skyfire-Auto-Installer/configs/"
if [ "$RANDOMIZE_PASSWORDS" = "true" ]; then
    echo "The default passwords setup is : password123"
fi
if [ "$remote_db_update" = "true" ]; then
    echo "The REMOTE_DB_PASS has been updated to the users inputted password."
fi
echo ""
echo -e "\e[32m↓↓↓ Next - Run the following ↓↓↓\e[0m"
echo ""
echo "cd /Skyfire-Auto-Installer/scripts/Setup/ && ./Root-Install.sh all"
echo ""
echo "##########################################################"
echo ""
fi

echo ""
echo "##########################################################"
echo "INIT FINISHED"
echo "##########################################################"
echo ""

fi