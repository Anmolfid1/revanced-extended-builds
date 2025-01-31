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

CFG=config.toml

if [ ! -f ~/.rvmm_"$(date '+%Y%m')" ]; then
	pr "Setting up environment..."
	yes "" | pkg update -y && pkg install -y openssl git wget jq openjdk-17 zip
	: >~/.rvmm_"$(date '+%Y%m')"
fi

if [ -f build.sh ]; then cd ..; fi
if [ -d revanced-extended-builds ]; then
	pr "Checking for revanced-extended-builds updates"
	git -C revanced-extended-builds fetch
	if git -C revanced-extended-builds status | grep -q 'is behind'; then
		pr "revanced-extended-builds already is not synced with upstream."
		pr "Cloning revanced-extended-builds. config.toml will be preserved."
		cp -f revanced-extended-builds/config*toml .
		rm -rf revanced-extended-builds
		git clone https://github.com/E85Addict/revanced-extended-builds --recurse --depth 1
		mv -f config*toml revanced-extended-builds/
	fi
else
	pr "Cloning revanced-extended-builds."
	git clone https://github.com/E85Addict/revanced-extended-builds --recurse --depth 1
	sed -i '/^enabled.*/d; /^\[.*\]/a enabled = false' revanced-extended-builds/config*toml
fi
cd revanced-extended-builds
chmod +x build.sh build-termux.sh

if ! ask "Select config (y=revanced n=revanced extended)"; then
	CFG=config-rv-ex.toml
fi
if ask "Do you want to open the config for customizations? [y/n]"; then
	nano $CFG
fi
if ! ask "Setup is done. Do you want to start building? [y/n]"; then
	exit 0
fi
./build.sh $CFG

cd build
pr "Ask for storage permission"
until
	yes | termux-setup-storage >/dev/null 2>&1
	ls /sdcard >/dev/null 2>&1
do
	sleep 1
done

PWD=$(pwd)
mkdir -p ~/storage/downloads/revanced-extended-builds
for op in *; do
	[ "$op" = "*" ] && continue
	mv -f "${PWD}/${op}" ~/storage/downloads/revanced-extended-builds/"${op}"
done

pr "Outputs are available in /sdcard/Download/revanced-extended-builds folder"
am start -a android.intent.action.VIEW -d file:///sdcard/Download/revanced-extended-builds -t resource/folder
sleep 2
am start -a android.intent.action.VIEW -d file:///sdcard/Download/revanced-extended-builds -t resource/folder
