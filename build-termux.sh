#!/usr/bin/env bash

set -e

pr() { echo -e "\033[0;32m[+] ${1}\033[0m"; }
ask() {
	local y
	for ((n = 0; n < 3; n++)); do
		pr "$1"
		if read -r y; then
			if [ "$y" = y ]; then
				return 0
			elif [ "$y" = n ]; then
				return 1
			fi
		fi
		pr "Asking again..."
	done
	return 1
}

pr "Setting up environment..."
yes "" | pkg update -y && pkg install -y git wget openssl jq openjdk-17 zip

pr "Cloning revanced-extended-builds repository..."
if [ -d revanced-extended-builds ]; then
	if ask "Directory revanced-extended-builds already exists. Do you want to clone the repo again and overwrite your config? [y/n]"; then
		rm -rf revanced-extended-builds
		git clone https://github.com/E85Addict/revanced-extended-builds --recurse --depth 1
		sed -i '/^enabled.*/d; /^\[.*\]/a enabled = false' revanced-extended-builds/config.toml
	fi
else
	git clone https://github.com/E85Addict/revanced-extended-builds --recurse --depth 1
	sed -i '/^enabled.*/d; /^\[.*\]/a enabled = false' revanced-extended-builds/config.toml
fi

if [ ! -f build.sh ]; then
	cd revanced-extended-builds
fi

if ask "Do you want to open the config.toml for customizations? [y/n]"; then
	nano config.toml
else
	pr "No app is selected for patching!"
fi
if ! ask "Setup is done. Do you want to start building? [y/n]"; then
	exit 0
fi
./build.sh

cd build
pr "Ask for storage permission"
until
	yes | termux-setup-storage >/dev/null 2>&1
	ls /sdcard >/dev/null 2>&1
do
	sleep 1
done

PWD=$(pwd)
mkdir ~/storage/downloads/revanced-extended-builds 2>/dev/null || :
for op in *; do
	[ "$op" = "*" ] && continue
	cp -f "${PWD}/${op}" ~/storage/downloads/revanced-extended-builds/"${op}"
done

pr "Outputs are available in /sdcard/Download/revanced-extended-builds folder"
am start -a android.intent.action.VIEW -d file:///sdcard/Download/revanced-extended-builds -t resource/folder
sleep 2
am start -a android.intent.action.VIEW -d file:///sdcard/Download/revanced-extended-builds -t resource/folder
