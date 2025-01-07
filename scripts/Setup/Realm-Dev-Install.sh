#!/bin/bash

### TRINITYCORE INSTALL SCRIPT
### TESTED WITH UBUNTU ONLY

. /Skyfire-Auto-Installer/configs/root-config
. /Skyfire-Auto-Installer/configs/auth-config
. /Skyfire-Auto-Installer/configs/realm-dev-config

if [ $USER != "$SETUP_REALM_USER" ]; then

echo "You must run this script under the $SETUP_REALM_USER user!"

else

## LETS START
echo ""
echo "##########################################################"
echo "## DEV REALM INSTALL SCRIPT STARTING...."
echo "##########################################################"
echo ""
NUM=0
export DEBIAN_FRONTEND=noninteractive

if [ "$1" = "" ]; then
echo ""
echo "## No option selected, see list below"
echo ""
echo "- [all] : Run Full Script"
echo ""
((NUM++)); echo "- [$NUM] : Close Worldserver"
((NUM++)); echo "- [$NUM] : Setup MySQL Database & Users"
((NUM++)); echo "- [$NUM] : Pull and Setup Source"
((NUM++)); echo "- [$NUM] : Setup Worldserver Config"
((NUM++)); echo "- [$NUM] : Pull and Setup Database"
((NUM++)); echo "- [$NUM] : Download 5.4.8 Client"
((NUM++)); echo "- [$NUM] : Setup Client Tools"
((NUM++)); echo "- [$NUM] : Run Map/DBC Extractor"
((NUM++)); echo "- [$NUM] : Run VMap Extractor"
((NUM++)); echo "- [$NUM] : Run Mmaps Extractor"
((NUM++)); echo "- [$NUM] : Setup Realmlist"
((NUM++)); echo "- [$NUM] : Setup Linux Service"
((NUM++)); echo "- [$NUM] : Setup Misc Scripts"
((NUM++)); echo "- [$NUM] : Setup Script Alias"
((NUM++)); echo "- [$NUM] : Start Worldserver"
echo ""

else


NUM=0
((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Closing Worldserver"
echo "##########################################################"
echo ""
systemctl stop worldserverd
killall screen
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup MySQL Database & Users"
echo "##########################################################"
echo ""

# World Database Setup
echo "Checking if the database '${REALM_DB_USER}_world' exists..."
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW DATABASES LIKE '${REALM_DB_USER}_world';" | grep -q "${REALM_DB_USER}_world"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE ${REALM_DB_USER}_world DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    if [[ $? -eq 0 ]]; then
        echo "Database '${REALM_DB_USER}_world' created."
    else
        echo "Failed to create database '${REALM_DB_USER}_world'."
        exit 1
    fi
else
    echo "Database '${REALM_DB_USER}_world' already exists."
fi

echo "Checking if the database '${REALM_DB_USER}_character' exists..."
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW DATABASES LIKE '${REALM_DB_USER}_character';" | grep -q "${REALM_DB_USER}_character"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE DATABASE ${REALM_DB_USER}_character DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
    if [[ $? -eq 0 ]]; then
        echo "Database '${REALM_DB_USER}_character' created."
    else
        echo "Failed to create database '${REALM_DB_USER}_character'."
        exit 1
    fi
else
    echo "Database '${REALM_DB_USER}_character' already exists."
fi

# Create the realm user if it does not already exist
echo "Checking if the realm user '${REALM_DB_USER}' exists..."
if ! mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SELECT User FROM mysql.user WHERE User = '${REALM_DB_USER}' AND Host = 'localhost';" | grep -q "${REALM_DB_USER}"; then
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "CREATE USER '${REALM_DB_USER}'@'localhost' IDENTIFIED BY '$REALM_DB_PASS';"
    if [[ $? -eq 0 ]]; then
        echo "Realm DB user '${REALM_DB_USER}' created."
    else
        echo "Failed to create realm DB user '${REALM_DB_USER}'."
        exit 1
    fi
else
    echo "Realm DB user '${REALM_DB_USER}' already exists."
fi

# Grant privileges
echo "Granting privileges on '${REALM_DB_USER}_world' to '${REALM_DB_USER}'..."
if mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON ${REALM_DB_USER}_world.* TO '${REALM_DB_USER}'@'localhost';"; then
    echo "Granted all privileges on '${REALM_DB_USER}_world' to '${REALM_DB_USER}'."
else
    echo "Failed to grant privileges on '${REALM_DB_USER}_world' to '${REALM_DB_USER}'."
    exit 1
fi

echo "Granting privileges on '${REALM_DB_USER}_character' to '${REALM_DB_USER}'..."
if mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "GRANT ALL PRIVILEGES ON ${REALM_DB_USER}_character.* TO '${REALM_DB_USER}'@'localhost';"; then
    echo "Granted all privileges on '${REALM_DB_USER}_character' to '${REALM_DB_USER}'."
else
    echo "Failed to grant privileges on '${REALM_DB_USER}_character' to '${REALM_DB_USER}'."
    exit 1
fi

# Flush privileges
mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "FLUSH PRIVILEGES;"
echo "Flushed privileges."
echo "Setup World DB Account completed."
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Pulling Source"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/
mkdir /home/$SETUP_REALM_USER/server/
mkdir /home/$SETUP_REALM_USER/server/logs/
mkdir /home/$SETUP_REALM_USER/server/logs/crashes/
mkdir /home/$SETUP_REALM_USER/server/data/
## Source install
git clone --single-branch --branch $CORE_BRANCH "$CORE_REPO_URL" Skyfire
# Fix build path
find /home/$SETUP_REALM_USER/Skyfire -type f -exec sed -i 's|/usr/local/skyfire-server|/home/'$SETUP_REALM_USER'/server|g' {} +
## Build source
echo "Building Source"
cd /home/$SETUP_REALM_USER/Skyfire/
mkdir /home/$SETUP_REALM_USER/Skyfire/build
cd /home/$SETUP_REALM_USER/Skyfire/build
cmake /home/$SETUP_REALM_USER/Skyfire/ -DCMAKE_INSTALL_PREFIX=/home/$SETUP_REALM_USER/server -DSCRIPTS_EASTERNKINGDOMS="disabled" -DSCRIPTS_EVENTS="disabled" -DSCRIPTS_KALIMDOR="disabled" -DSCRIPTS_NORTHREND="disabled" -DSCRIPTS_OUTDOORPVP="disabled" -DSCRIPTS_OUTLAND="disabled" -DWITH_DYNAMIC_LINKING=ON -DSCRIPTS="dynamic" -DSCRIPTS_CUSTOM="dynamic" -DUSE_COREPCH=1 -DUSE_SCRIPTPCH=1 -DSERVERS=1 -DTOOLS=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_COREDEBUG=0 -DWITH_WARNINGS=0
make -j $(( $(nproc) - 1 ))
make install
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Config"
echo "##########################################################"
echo ""
cd /home/$SETUP_REALM_USER/server/etc/
mv worldserver.conf.dist worldserver.conf
## Changing Config values
echo "Changing Config values"
## Misc Edits
sed -i 's/RealmID = 1/RealmID = '${REALM_ID}'/g' worldserver.conf
sed -i 's/WorldServerPort = 8085/WorldServerPort = '${SETUP_REALM_PORT}'/g' worldserver.conf
sed -i 's/RealmZone = 1/RealmZone = '${REALM_ZONE}'/g' worldserver.conf
sed -i 's/mmap.enablePathFinding = 0/mmap.enablePathFinding = 1/g' worldserver.conf
## Folders
sed -i 's^LogsDir = ""^LogsDir = "/home/'${SETUP_REALM_USER}'/server/logs"^g' worldserver.conf
sed -i 's^DataDir = "."^DataDir = "/home/'${SETUP_REALM_USER}'/server/data"^g' worldserver.conf
#sed -i 's^BuildDirectory  = ""^BuildDirectory  = "/home/'${SETUP_REALM_USER}'/Skyfire/build"^g' worldserver.conf
#sed -i 's^SourceDirectory  = ""^SourceDirectory  = "/home/'${SETUP_REALM_USER}'/Skyfire/"^g' worldserver.conf
sed -i 's/Welcome to a SkyFire server./Welcome to the '${REALM_NAME}'/g' worldserver.conf
sed -i 's/PlayerLimit = 100/PlayerLimit = 10000/g' worldserver.conf
## LoginDatabaseInfo
sed -i "s/127.0.0.1;3306;skyfire;skyfire;auth/${AUTH_DB_HOST};3306;${AUTH_DB_USER};${AUTH_DB_PASS};${AUTH_DB_USER};/g" worldserver.conf
## WorldDatabaseInfo
sed -i "s/127.0.0.1;3306;skyfire;skyfire;world/${REALM_DB_HOST};3306;${REALM_DB_USER};${REALM_DB_PASS};${REALM_DB_USER}_world/g" worldserver.conf
## CharacterDatabaseInfo
sed -i "s/127.0.0.1;3306;skyfire;skyfire;characters/${REALM_DB_HOST};3306;${REALM_DB_USER};${REALM_DB_PASS};${REALM_DB_USER}_character/g" worldserver.conf
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "update" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM. Downloading Database"
echo "##########################################################"
echo ""

FILENAME="${DB_REPO_URL##*/}"           # Get the filename from the URL
FOLDERNAME="${FILENAME%.zip}"  # Removes .zip from the filename
TARGET_DIR="/home/$SETUP_REALM_USER/server"
cd "$TARGET_DIR" || { echo "Directory does not exist: $TARGET_DIR"; exit 1; }
if [ -d "$TARGET_DIR/$FOLDERNAME" ]; then
	while true; do
		read -p "$FOLDERNAME already exists. Redownload? (y/n): " file_choice
		if [[ "$file_choice" =~ ^[Yy]$ ]]; then
			rm -rf $TARGET_DIR/$FOLDERNAME
			wget "$DB_REPO_URL"
			break
		elif [[ "$file_choice" =~ ^[Nn]$ ]]; then
			echo "Skipping download." && break
		else
			echo "Please answer y (yes) or n (no)."
		fi
	done
else
	wget "$DB_REPO_URL"
fi

# Ensure the file exists before extracting
if [ -f "$FILENAME" ]; then
	unzip -o "$TARGET_DIR/$FILENAME"
	rm "$TARGET_DIR/$FILENAME"
fi

# Applying SQL World base
WORLD_1_SQL_FILE="/home/$SETUP_REALM_USER/server/$FOLDERNAME/main_db/procs/stored_procs.sql"
WORLD_2_SQL_FILE="/home/$SETUP_REALM_USER/server/$FOLDERNAME/main_db/world/$FOLDERNAME.sql"
# Check if 'creature_template' table exists in the 'world' database
TABLE_CHECK=$(mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW TABLES LIKE 'creature_template';" ${SETUP_REALM_USER}_world | grep -c "creature_template")
if [ "$TABLE_CHECK" -gt 0 ]; then
    echo "'creature_template' table exists. Skipping SQL execution."
else
    echo "'creature_template' table does not exist. Proceeding to execute SQL file..."
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" ${SETUP_REALM_USER}_world < "$WORLD_1_SQL_FILE"
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" ${SETUP_REALM_USER}_world < "$WORLD_2_SQL_FILE"
fi
fi

# Applying SQL Character base
SQL_FILE="/home/$SETUP_REALM_USER/Skyfire/sql/base/character/character.sql"
# Check if 'worldstates' table exists in the 'characters' database
TABLE_CHECK=$(mysql -u "$ROOT_USER" -p"$ROOT_PASS" -e "SHOW TABLES LIKE 'worldstates';" ${SETUP_REALM_USER}_characters | grep -c "worldstates")
if [ "$TABLE_CHECK" -gt 0 ]; then
    echo "'worldstates' table exists. Skipping SQL execution."
else
    echo "'worldstates' table does not exist. Proceeding to execute SQL file..."
    mysql -u "$ROOT_USER" -p"$ROOT_PASS" ${SETUP_REALM_USER}_characters < "$SQL_FILE"
fi
fi

fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Download 5.4.8 Client"
echo "##########################################################"
echo ""
FILENAME="${CLIENT_URL##*/}"
cd /home/
if [ -f "$FILENAME" ]; then
    while true; do
        read -p "$FILENAME already exists. Redownload? (y/n): " file_choice
        if [[ "$file_choice" =~ ^[Yy]$ ]]; then
            rm "$FILENAME" && sudo wget $CLIENT_URL && break
        elif [[ "$file_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping download." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	sudo wget $CLIENT_URL
fi
if [ -d "/home/WoW548" ]; then
    while true; do
        read -p "WoW548 Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            sudo unzip "$FILENAME" && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	sudo unzip "$FILENAME"
fi
if [ -d "/home/MOP-5.4.8.18414-enUS-Repack" ]; then
	sudo mv -f /home/MOP-5.4.8.18414-enUS-Repack /home/WoW548
fi
if [ -d "/home/WoW548" ]; then
	sudo chmod -R 777 /home/WoW548
fi
if [ -f "/home/$FILENAME" ]; then
    while true; do
        read -p "Would you like to delete the 5.4.8 client zip folder to save folder space? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            sudo rm $FILENAME && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping deletion." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Client Tools"
echo "##########################################################"
echo ""
cp /home/$SETUP_REALM_USER/server/bin/mapextractor /home/WoW548/
cp /home/$SETUP_REALM_USER/server/bin/vmap4extractor /home/WoW548/
cp /home/$SETUP_REALM_USER/server/bin/mmaps_generator /home/WoW548/
cp /home/$SETUP_REALM_USER/server/bin/vmap4assembler /home/WoW548/
echo "Client tools copied over to /home/WoW548"
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run Map/DBC Extractor"
echo "##########################################################"
echo ""
cd /home/WoW548/
if [ -d "/home/WoW548/maps" ]; then
    while true; do
        read -p "maps Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            ./mapextractor && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	./mapextractor
fi
while true; do
	read -p "Would you like to copy the maps/dbc data folders? (y/n): " folder_choice
	if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
		echo "Copying dbc folder"
		cp -r /home/WoW548/dbc /home/$SETUP_REALM_USER/server/data/
		echo "Copying Cameras folder"
		cp -r /home/WoW548/Cameras /home/$SETUP_REALM_USER/server/data/
		echo "Copying maps folder"
		cp -r /home/WoW548/maps /home/$SETUP_REALM_USER/server/data/
		break
	elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
		echo "Skipping data copy." && break
	else
		echo "Please answer y (yes) or n (no)."
	fi
done

fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run VMap Extractor"
echo "##########################################################"
echo ""
cd /home/WoW548/
if [ -d "/home/WoW548/vmaps" ]; then
    while true; do
        read -p "vmaps Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            ./vmap4extractor && ./vmap4assembler && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	./vmap4extractor && ./vmap4assembler
fi
while true; do
	read -p "Would you like to copy the vmap data folders? (y/n): " folder_choice
	if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
		echo "Copying Buildings folder"
		cp -r /home/WoW548/Buildings /home/$SETUP_REALM_USER/server/data/
		echo "Copying vmaps folder"
		cp -r /home/WoW548/vmaps /home/$SETUP_REALM_USER/server/data/
		break
	elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
		echo "Skipping data copy." && break
	else
		echo "Please answer y (yes) or n (no)."
	fi
done
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Run Mmaps Extractor"
echo "##########################################################"
echo ""
cd /home/WoW548/
if [ -d "/home/WoW548/mmaps" ]; then
    while true; do
        read -p "mmaps Folder already exists. Reextract? (y/n): " folder_choice
        if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
            ./mmaps_generator && break
        elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
            echo "Skipping extraction." && break
        else
            echo "Please answer y (yes) or n (no)."
        fi
    done
else
	./mmaps_generator
fi
while true; do
	read -p "Would you like to copy the mmaps data folders? (y/n): " folder_choice
	if [[ "$folder_choice" =~ ^[Yy]$ ]]; then
		echo "Copying mmaps folder"
		cp -r /home/WoW548/mmaps /home/$SETUP_REALM_USER/server/data/
		break
	elif [[ "$folder_choice" =~ ^[Nn]$ ]]; then
		echo "Skipping data copy." && break
	else
		echo "Please answer y (yes) or n (no)."
	fi
done
fi

((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Update Realmlist"
echo "##########################################################"
echo ""
if [ $SETUP_REALMLIST == "true" ]; then
# Get the external IP address
EXTERNAL_IP=$(curl -s http://ifconfig.me)
mysql --host=$REALM_DB_HOST -h $AUTH_DB_HOST -u $AUTH_DB_USER -p$AUTH_DB_PASS << EOF
use auth
DELETE from realmlist where id = $REALM_ID;
REPLACE INTO realmlist VALUES ('$REALM_ID', '$REALM_NAME', '$EXTERNAL_IP', '$EXTERNAL_IP', '255.255.255.0', '$SETUP_REALM_PORT', '0', '0', '$REALM_ZONE', '$REALM_SECURITY', '0', '12340');
quit
EOF
fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Linux Service"
echo "##########################################################"
echo ""
if [ "$SETUP_SERVICE" == "daemon" ]; then
sudo mv /home/$SETUP_REALM_USER/server/etc/worldserverd.service.dist /etc/systemd/system/worldserverd.service
sudo chmod 644 /etc/systemd/system/worldserverd.service
sudo chmod +x //etc/systemd/system/worldserverd.service
sudo systemctl daemon-reload
sudo systemctl enable worldserverd
elif [ "$SETUP_SERVICE" == "screen" ]; then
# Make Folders
mkdir /home/$SETUP_REALM_USER/server/scripts/
mkdir /home/$SETUP_REALM_USER/server/scripts/Restarter/
mkdir /home/$SETUP_REALM_USER/server/scripts/Restarter/World/
sudo cp -r -u /Skyfire-Auto-Installer/scripts/Restarter/World/* /home/$SETUP_REALM_USER/server/scripts/Restarter/World/
# Fix Permissions
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/restarter_world_gdb.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/gdbcommands
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
sudo chmod +x /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/restarter_world.sh
# Update script names
sudo sed -i "s/realmname/$SETUP_REALM_USER/g" /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
sudo sed -i "s/realmname/$SETUP_REALM_USER/g" /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
# Setup Crontab
crontab -r
if [ $SETUP_TYPE == "GDB" ]; then
	echo "Setup Restarter in GDB mode...."
	crontab -l | { cat; echo "############## START WORLD ##############"; } | crontab -
	crontab -l | { cat; echo "#### GDB WORLD"; } | crontab -
	crontab -l | { cat; echo "@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh"; } | crontab -
	crontab -l | { cat; echo "#### NORMAL WORLD"; } | crontab -
	crontab -l | { cat; echo "#@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh"; } | crontab -
fi
if [ $SETUP_TYPE == "Normal" ]; then
	echo "Setup Restarter in Normal mode...."
	crontab -l | { cat; echo "############## START WORLD ##############"; } | crontab -
	crontab -l | { cat; echo "#### GDB WORLD"; } | crontab -
	crontab -l | { cat; echo "#@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh"; } | crontab -
	crontab -l | { cat; echo "#### NORMAL WORLD"; } | crontab -
	crontab -l | { cat; echo "@reboot /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh"; } | crontab -
fi

fi
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Setup Misc Scripts"
echo "##########################################################"
echo ""
cp -r -u /Skyfire-Auto-Installer/scripts/Setup/Clean-Logs.sh /home/$SETUP_REALM_USER/server/scripts/
chmod +x  /home/$SETUP_REALM_USER/server/scripts/Clean-Logs.sh
cd /home/$SETUP_REALM_USER/server/scripts/
sudo sed -i "s^USER^${SETUP_REALM_USER}^g" Clean-Logs.sh
# Setup Crontab
crontab -l | { cat; echo "############## MISC SCRIPTS ##############"; } | crontab -
crontab -l | { cat; echo "* */1* * * * /home/$SETUP_REALM_USER/server/scripts/Clean-Logs.sh"; } | crontab -
echo "$SETUP_REALM_USER Realm Crontab setup"
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
echo "alias commands='cd /Skyfire-Auto-Installer/scripts/Setup/ && ./Realm-Dev-Install.sh && cd -'" >> ~/.bashrc

echo -e "\n## UPDATE" >> ~/.bashrc
echo "alias update='cd /Skyfire-Auto-Installer/scripts/Setup/ && ./Realm-Dev-Install.sh update && cd -'" >> ~/.bashrc

echo "Added script alias to bashrc"

if ! grep -Fxq "$FOOTER" ~/.bashrc; then
    echo -e "\n$FOOTER\n" >> ~/.bashrc
    echo "footer added"
fi

# Source .bashrc to apply changes
. ~/.bashrc
fi


((NUM++))
if [ "$1" = "all" ] || [ "$1" = "$NUM" ]; then
echo ""
echo "##########################################################"
echo "## $NUM.Start Server"
echo "##########################################################"
echo ""
if [ "$SETUP_SERVICE" == "deamon" ]; then
sudo systemctl start worldserverd
elif [ "$SETUP_SERVICE" == "screen" ]; then
    if [ $SETUP_TYPE == "GDB" ]; then
        echo "REALM STARTED IN GDB MODE!"
        /home/$SETUP_REALM_USER/server/scripts/Restarter/World/GDB/start_gdb.sh
    fi
    if [ $SETUP_TYPE == "Normal" ]; then
        echo "REALM STARTED IN NORMAL MODE!"
        /home/$SETUP_REALM_USER/server/scripts/Restarter/World/Normal/start.sh
    fi
fi
fi


echo ""
echo "##########################################################"
echo "## DEV REALM INSTALLED AND FINISHED!"
echo "##########################################################"
echo ""
if [ "$SETUP_SERVICE" == "deamon" ]; then
echo "The Worldserver should now be online!! <3"
echo ""
echo -e "\e[32m↓↓↓ To manage the worldserver - You can use the following ↓↓↓\e[0m"
echo ""
echo "systemctl status worldserverd"
echo ""
echo "systemctl start worldserverd"
echo ""
echo "systemctl stop worldserverd"
echo ""
elif [ "$SETUP_SERVICE" == "screen" ]; then
echo -e "\e[32m↓↓↓ To access the worldserver - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_REALM_USER -c 'screen -r $SETUP_REALM_USER'"
echo ""
echo "TIP - To exit the screen press ALT + A + D"
echo ""
echo -e "\e[32m↓↓↓ To access the authserver - Run the following ↓↓↓\e[0m"
echo ""
echo "su - $SETUP_AUTH_USER -c 'screen -r $SETUP_AUTH_USER'"
echo ""
echo "TIP - To exit the screen press ALT + A + D"
echo ""
fi

fi
fi
fi
fi
