#!/bin/bash

### TRINITYCORE AUTH INSTALL SCRIPT
### TESTED WITH UBUNTU ONLY

. /Skyfire-Auto-Installer/configs/root-config
. /Skyfire-Auto-Installer/configs/auth-config
. /Skyfire-Auto-Installer/configs/realm-dev-config


if [ $USER != "$SETUP_AUTH_USER" ]; then

echo "You must run this script under the $SETUP_AUTH_USER user!"

else

## LETS START
echo ""
echo "##########################################################"
echo "## AUTH SERVER INSTALL SCRIPT STARTING...."
echo "##########################################################"
echo ""
NUM=0
export DEBIAN_FRONTEND=noninteractive


if [ "$1" = "" ]; then
## Option List
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo "- [update] : Update Source and DB"
echo ""
((NUM++)); echo "- [$NUM] : Close Authserver"
((NUM++)); echo "- [$NUM] : Setup MySQL Database & Users"
((NUM++)); echo "- [$NUM] : Pull and Setup Source"
((NUM++)); echo "- [$NUM] : Setup Authserver Config"
((NUM++)); echo "- [$NUM] : Setup Database Data"
((NUM++)); echo "- [$NUM] : Setup Restarter"
((NUM++)); echo "- [$NUM] : Setup Crontab"
((NUM++)); echo "- [$NUM] : Setup Alias"
((NUM++)); echo "- [$NUM] : Start Authserver"
echo ""

else


NUM=0
((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Closing Authserver"
echo "##########################################################"
echo ""
sudo killall screen
systemctl stop authserverd
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup MySQL Database & Users"
echo "##########################################################"
echo ""

# Auth Database Setup
echo "Checking if the 'auth' database exists..."
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW DATABASES LIKE 'auth';" | grep -q "auth"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE auth DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    if [[ $? -eq 0 ]]; then
        echo "Auth database created."
    else
        echo "Failed to create Auth database."
        exit 1
    fi
else
    echo "Auth database already exists."
fi

# Create the auth user if it does not already exist
echo "Checking if the auth user '$AUTH_DB_USER' exists..."
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SELECT User FROM mysql.user WHERE User = '$AUTH_DB_USER' AND Host = 'localhost';" | grep -q "$AUTH_DB_USER"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '$AUTH_DB_USER'@'localhost' IDENTIFIED BY '$AUTH_DB_PASS';"
    if [[ $? -eq 0 ]]; then
        echo "Auth DB user '$AUTH_DB_USER' created."
    else
        echo "Failed to create Auth DB user '$AUTH_DB_USER'."
        exit 1
    fi
else
    echo "Auth DB user '$AUTH_DB_USER' already exists."
fi

# Grant privileges to the auth user
echo "Granting privileges to '$AUTH_DB_USER' on the 'auth' database..."
if mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON auth.* TO '$AUTH_DB_USER'@'localhost';"; then
    echo "Granted all privileges on 'auth' database to '$AUTH_DB_USER'."
else
    echo "Failed to grant privileges to '$AUTH_DB_USER'."
    exit 1
fi

# Flush privileges
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "FLUSH PRIVILEGES;"
echo "Flushed privileges."
echo "Setup Auth DB Account completed."

fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Pulling source"
echo "##########################################################"
echo ""



fi






((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Pulling Source"
echo "##########################################################"
echo ""
cd /home/$SETUP_AUTH_USER/
mkdir /home/$SETUP_AUTH_USER/
mkdir /home/$SETUP_AUTH_USER/server/
mkdir /home/$SETUP_AUTH_USER/logs/
if [ -d "/home/$SETUP_AUTH_USER/Skyfire" ]; then
    if [ "$1" = "update" ]; then
        while true; do
            read -p "Skyfire source already exists. Redownload? (y/n): " file_choice
            if [[ "$file_choice" =~ ^[Yy]$ ]]; then
                rm -rf /home/$SETUP_AUTH_USER/Skyfire/
                ## Source install
                git clone --single-branch --branch $AUTH_BRANCH "$CORE_REPO_URL" Skyfire
                # Fix build path
                find /home/$SETUP_AUTH_USER/Skyfire -type f -exec sed -i 's|/usr/local/skyfire-server|/home/'$SETUP_AUTH_USER'/server|g' {} +
                break
            elif [[ "$file_choice" =~ ^[Nn]$ ]]; then
                echo "Skipping download." && break
            else
                echo "Please answer y (yes) or n (no)."
            fi
        done
    fi
else
    ## Source install
    git clone --single-branch --branch $AUTH_BRANCH "$CORE_REPO_URL" Skyfire
    # Fix build path
    find /home/$SETUP_AUTH_USER/Skyfire -type f -exec sed -i 's|/usr/local/skyfire-server|/home/'$SETUP_AUTH_USER'/server|g' {} +
fi
if [ -f "/home/$SETUP_AUTH_USER/server/bin/authserver" ]; then
    if [ "$1" != "update" ]; then
        while true; do
            read -p "Authserver already exists. Recompile source? (y/n): " file_choice
            if [[ "$file_choice" =~ ^[Yy]$ ]]; then
                ## Build source
                echo "Building source...."
                cd /home/$SETUP_AUTH_USER/Skyfire/
                rm -rf /home/$SETUP_AUTH_USER/Skyfire/build
                mkdir /home/$SETUP_AUTH_USER/Skyfire/build
                cd /home/$SETUP_AUTH_USER/Skyfire/build
                cmake /home/$SETUP_AUTH_USER/Skyfire/ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_AUTH_USER/server -DSCRIPTS=0 -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=0 -DCMAKE_BUILD_TYPE=Release -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0
                make -j $(( $(nproc) - 1 ))
                make install
                break
            elif [[ "$file_choice" =~ ^[Nn]$ ]]; then
                echo "Skipping download." && break
            else
                echo "Please answer y (yes) or n (no)."
            fi
        done
    else
        ## Build source
        echo "Building source...."
        cd /home/$SETUP_AUTH_USER/Skyfire/
        mkdir /home/$SETUP_AUTH_USER/Skyfire/build
        cd /home/$SETUP_AUTH_USER/Skyfire/build
        cmake /home/$SETUP_AUTH_USER/Skyfire/ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_AUTH_USER/server -DSCRIPTS=0 -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=0 -DCMAKE_BUILD_TYPE=Release -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0
        make -j $(( $(nproc) - 1 ))
        make install
    fi
else
    ## Build source
    echo "Building source...."
    cd /home/$SETUP_AUTH_USER/Skyfire/
    mkdir /home/$SETUP_AUTH_USER/Skyfire/build
    cd /home/$SETUP_AUTH_USER/Skyfire/build
    cmake /home/$SETUP_AUTH_USER/Skyfire/ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_AUTH_USER/server -DSCRIPTS=0 -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=0 -DCMAKE_BUILD_TYPE=Release -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0
    make -j $(( $(nproc) - 1 ))
    make install
fi
fi



((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Config"
echo "##########################################################"
echo ""
cd /home/$SETUP_AUTH_USER/server/etc/
if [ -f "authserver.conf.dist" ]; then
    mv "authserver.conf.dist" "authserver.conf"
    echo "Moved authserver.conf.dist to authserver.conf."
fi
## Changing Config values
echo "Changing Config values"
sed -i 's^LogsDir = ""^LogsDir = "/home/'${SETUP_AUTH_USER}'/server/logs"^g' authserver.conf
sed -i "s/Updates.EnableDatabases = 0/Updates.EnableDatabases = 1/g" authserver.conf
sed -i "s/127.0.0.1;3306;skyfire;skyfire;auth/${AUTH_DB_HOST};3306;${AUTH_DB_USER};${AUTH_DB_PASS};${AUTH_DB_USER};/g" authserver.conf
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Database Data"
echo "##########################################################"
echo ""
# Applying SQL base
SQL_FILE="/home/$SETUP_AUTH_USER/Skyfire/sql/base/auth_database.sql"
# Check if 'uptime' table exists in the 'auth' database
TABLE_CHECK=$(mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW TABLES LIKE 'uptime';" auth | grep -c "uptime")
if [ "$TABLE_CHECK" -gt 0 ]; then
    echo "'uptime' table exists. Skipping SQL execution."
else
    echo "'uptime' table does not exist. Proceeding to execute SQL file..."
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" auth < "$SQL_FILE"
fi
fi



((NUM++))
if [ "$1" = "all" ] || [ "$1" = "5" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Restarter"
echo "##########################################################"
echo ""
if [ "$SETUP_SERVICE" == "deamon" ]; then
sudo mv /home/$SETUP_AUTH_USER/server/etc/authserverd.service.dist /etc/systemd/system/authserverd.service
sudo chmod 644 /etc/systemd/system/authserverd.service
sudo chmod +x //etc/systemd/system/authserverd.service
sudo systemctl daemon-reload
sudo systemctl enable authserverd
elif [ "$SETUP_SERVICE" == "screen" ]; then
mkdir /home/$SETUP_AUTH_USER/server/scripts/
mkdir /home/$SETUP_AUTH_USER/server/scripts/Restarter/
mkdir /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/
sudo cp -r -u /Skyfire-Auto-Installer/scripts/Restarter/Auth/* /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/
## FIX SCRIPTS PERMISSIONS
sudo chmod +x /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
sed -i "s/realmname/$SETUP_AUTH_USER/g" /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
crontab -r
crontab -l | { cat; echo "############## START AUTHSERVER ##############"; } | crontab -
crontab -l | { cat; echo "@reboot /home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh"; } | crontab -
echo "Auth Crontab setup"
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Setup Script Alias"
echo "##########################################################"
echo ""

HEADER="#### CUSTOM ALIAS"
FOOTER="#### END CUSTOM ALIAS"

# Remove content between the header and footer, including the markers
sed -i "/$HEADER/,/$FOOTER/d" ~/.bashrc

# Add header and footer if they are not present
if ! grep -Fxq "$HEADER" ~/.bashrc; then
    echo -e "\n$HEADER\n" >> ~/.bashrc
    echo "header added"
else
    echo "header present"
fi

# Add new commands between the header and footer
echo -e "\n## COMMANDS" >> ~/.bashrc
echo "alias commands='cd /Skyfire-Auto-Installer/scripts/Setup/ && ./Auth-Install.sh && cd -'" >> ~/.bashrc

echo -e "\n## UPDATE" >> ~/.bashrc
echo "alias update='cd /Skyfire-Auto-Installer/scripts/Setup/ && ./Auth-Install.sh update && cd -'" >> ~/.bashrc

if ! grep -Fxq "$FOOTER" ~/.bashrc; then
    echo -e "\n$FOOTER\n" >> ~/.bashrc
    echo "footer added"
fi

echo "Added script alias to bashrc"

# Source .bashrc to apply changes
. ~/.bashrc
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Starting Authserver"
echo "##########################################################"
echo ""
if [ "$SETUP_SERVICE" == "deamon" ]; then
sudo systemctl start authserverd
elif [ "$SETUP_SERVICE" == "screen" ]; then
/home/$SETUP_AUTH_USER/server/scripts/Restarter/Auth/start.sh
fi
echo "Authserver started"
fi

echo ""
echo "##########################################################"
echo "## AUTH INSTALLED AND FINISHED!"
echo "##########################################################"
echo ""
if [ "$SETUP_SERVICE" == "deamon" ]; then
echo "The Worldserver should now be online!! <3"
echo ""
echo -e "\e[32m↓↓↓ To manage the authserver - You can use the following ↓↓↓\e[0m"
echo ""
echo "systemctl status authserverd"
echo ""
echo "systemctl start authserverd"
echo ""
echo "systemctl stop authserverd"
echo ""
elif [ "$SETUP_SERVICE" == "screen" ]; then
echo -e "\e[32m↓↓↓ To access the authserver - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_AUTH_USER -c 'screen -r auth'"
echo ""
echo "TIP - To exit the screen press ALT + A + D"
echo ""
echo -e "\e[32m↓↓↓ To Install the Dev Realm - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_REALM_USER -c 'cd /Skyfire-Auto-Installer/scripts/Setup/ && ./Realm-Dev-Install.sh all'"
echo ""
fi

fi
fi
