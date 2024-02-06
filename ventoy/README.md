# Ventoy Support

You can make ventoy use both themes like the minecraft menu.

## Installation

- Copy the ventoy folder to the Ventoy partition where you put all your ISOs
- create a `theme` folder in that ventoy folder
- copy both theme folders there
```bash
# Cloning all repos
git clone https://github.com/Lxtharia/double-minegrub-menu.git
git clone https://github.com/Lxtharia/minegrub-theme.git
git clone https://github.com/Lxtharia/minegrub-world-sel-theme.git

# switch to the ventoy branch
cd double-minegrub-menu
git switch ventoy-dev

# Let's say you mounted the Ventoy ISO partition to /mnt/usb
# copy the ventoy folder
sudo cp -ruv ./ventoy /mnt/usb/
mkdir /mnt/usb/ventoy/theme

# copy the themes
cd ..
cp -ruv minegrub-theme/minegrub /mnt/usb/ventoy/theme/
cp -ruv minegrub-world-sel-theme/minegrub-world-selection /mnt/usb/ventoy/theme/

```

You could now load the main-menu with F6 while in ventoy.
To load it automatically, we can just call that function in ventoys grub.cfg (a bit hacky)
Mount Ventoys EFI partition now.

```
# Let's say you mounted the Ventoy EFI partition to /mnt/usb2
# edit the grub.cfg
sudo vim /mnt/usb2/grub/grub.cfg
```
- Add this line at the very end:
```
ventoy_ext_menu
```
- Now Ventoy automatically loads our custom menu (ventoy_grub.cfg, which is our main menu)
- Pressing Esc or choosing Singlebooter should show the ISO selection menu

