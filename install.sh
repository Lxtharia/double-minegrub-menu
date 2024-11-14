#!/bin/bash

trap 'echo "[x] Failed to set up, failed at command \"${BASH_COMMAND}\""; exit 1' ERR

# find grub

export GRUB_PREFIX="grub"

if [ ! -d /boot/$GRUB_PREFIX ]; then
	export GRUB_PREFIX="grub2"
fi

if [ ! -d /boot/$GRUB_PREFIX ]; then
	echo "[x] No grub found!?"
	exit 1
fi

echo "[*] Using grub path: ${GRUB_PREFIX}"

# clone project

if [ ! -d ./minegrub-world-sel-theme ]; then
	git clone https://github.com/Lxtharia/minegrub-world-sel-theme.git
fi

if [ ! -d ./minegrub-theme ]; then
	git clone https://github.com/Lxtharia/minegrub-theme.git
fi

if [ ! -d ./minegrub-double-menu ]; then
	git clone https://github.com/Lxtharia/minegrub-double-menu.git
fi

# copy theme files

if [ ! -d /boot/$GRUB_PREFIX/themes/minegrub-world-selection ]; then
	sudo cp -ruv minegrub-world-sel-theme/minegrub-world-selection /boot/$GRUB_PREFIX/themes/
fi

if [ ! -d /boot/$GRUB_PREFIX/themes/minegrub ]; then
	sudo cp -ruv minegrub-theme/minegrub /boot/$GRUB_PREFIX/themes/
fi

if [ ! -f /boot/$GRUB_PREFIX/mainmenu.cfg ]; then
	sudo cp minegrub-double-menu/mainmenu.cfg /boot/$GRUB_PREFIX/
fi

if [ ! -f /etc/grub.d/05_twomenus ]; then
	sudo cp minegrub-double-menu/05_twomenus /etc/grub.d/
	sudo chmod +x /etc/grub.d/05_twomenus
fi

# change grub configuration

sudo sed -i "/^GRUB_THEME=/cGRUB_THEME=\/boot\/${GRUB_PREFIX}\/themes\/minegrub-world-selection\/theme.txt" /etc/default/grub
sudo sed -i "/^GRUB_TIMEOUT_STYLE=/d" /etc/default/grub
echo -e "GRUB_TIMEOUT_STYLE=menu" | sudo tee -a /etc/default/grub > /dev/null
sudo $GRUB_PREFIX-mkconfig -o /boot/$GRUB_PREFIX/grub.cfg
sudo $GRUB_PREFIX-editenv - set config_file=mainmenu.cfg
