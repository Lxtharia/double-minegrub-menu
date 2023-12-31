# The REAL minecraft experience when booting your system!

This is a guide on how you can have two grub menus after one another, each in a different theme!

I made this so I can use my minegrub theme that looks like the Minecraft main menu to enter my _second_ minegrub theme that looks like the minecraft world selection menu _just like in the real game_

Yea, its possible, and its fun

<video src='https://github.com/Lxtharia/double-minegrub-menu/assets/87075045/3b317b16-482c-44cf-9faa-75a3f437e7b5' width=180 > </video>


# Installation
- Install your two themes, in this case:
    ```bash
    git clone https://github.com/Lxtharia/minegrub-world-sel-theme.git && cd minegrub-world-sel-theme
    sudo cp -ruv minegrub-world-selection /boot/grub/themes/
    
    cd ..
    ### And the other one
    git clone https://github.com/Lxtharia/minegrub-theme.git && cd minegrub-theme
    sudo cp -ruv minegrub /boot/grub/themes/
    ```
    - Check them out here for more instructions: [minegrub-theme](https://github.com/Lxtharia/minegrub-theme) and [minegrub-world-sel-theme](https://github.com/Lxtharia/minegrub-world-sel-theme)

- Set the **world-selection** theme in `/etc/default/grub` and other trivial stuff
    ```
    GRUB_TIMEOUT_STYLE=menu
    ...
    GRUB_THEME=/boot/grub/themes/minegrub-world-selection/theme.txt
    ...
    GRUB_GFXMODE=...
    ```
- clone this repo or download the files (it's only two)
    ```bash
    git clone https://github.com/Lxtharia/minegrub-double-menu.git && cd minegrub-double-menu
    ```
- copy the files, generate the .cfg and set the env variable
    ```bash
    sudo cp ./mainmenu.cfg /boot/grub/
    sudo cp ./05_twomenus /etc/grub.d/
    chmod +x /etc/grub.d/05_twomenus

    sudo grub-mkconfig -o /boot/grub/grub.cfg
    sudo grub-editenv - set config_file=mainmenu.cfg
    ```
- Done!
- If you want to disable it all you need to do is
    ```bash
    sudo grub-editenv - unset config_file
    ```

# Explanation
When grub starts, it by default reads the file `grub.cfg` usally located in `/boot/grub/grub.cfg` to set all the options (like timeout, default boot option, theme) and add all the boot options.
This file is usually generated by `grub-mkconfig` which uses variables set in `/etc/default/grub` and scripts in `/etc/grub.d/*` to create the full config file.

**NOW:** what do we want? (the results to be)
We want to be greeted with the minecraft looking main menu with options like "Singleplayer" "Multiplayer" "Minecraft Realms" (but with cool different nerd terms, see below) and if we select Singleplayer we want to see the world selection menu with all the boot options. If we press escape we return to the main menu.

**NOW:** what do we want? (in funcional terms)
We want grub to read a .cfg file that sets the theme to the main menu theme (`./mainmenu.cfg`) and that includes boot options like "Singlebooter" "Onlinebooter" or "UEFI Realms" (so cool). 
And if we select "Singlebooter" we want to load "the real config file" that sets the world-selection theme and that includes all of your personal boot options.

- We need some code to auto-load another config file
- To get following code in `grub.cfg` we write it in a file (`05_twomenus`) and put it in `/etc/grub.d/` so it gets included when generating the grub.cfg 
- To automatically load another configfile we can just call `configfile $prefix/mainmenu.cfg` in grub.cfg
    - `$prefix` contains the disk/partition absolute path to your `/boot/grub` folder
- We put this line in an if clause that will check if the enviromental variable `config_file=` is set 
- if yes, we load that file (`configfile $prefix/$config_file`)
- the normally generated grub.cfg automatically loads variables from the file /boot/grub/grubenv, so all we have to do is set it there 
- with `grub-editenv - set config_file=mainmenu.cfg`

- now mainmenu.cfg gets loaded.
- the first boot item will load our grub.cfg again.

- to prevent grub.cfg to load the other config file again, we put that code into another if clause
- when we select an item, grub sets the variable `chosen`, so we can only load the config file if this variable has not been set yet
- and that's it!
So all we need is:
- A manual config file for the main menu
- A few extra lines of code in the grub.cfg file
- the enviromental variable `config_file`

TLDR:
- grub.cfg loads enviromental variables from /boot/grub/grubenv automatically
- we want grub.cfg to load our main theme .cfg automatically (by reading the env variable `config_file`)
- we now have our main menu and if we select "Singlebooter" it loads the grub.cfg again.
- but now the "chosen" variable is set (because we have chosen an option)
- If this variable is set, we prevent the grub.cfg to load mainmenu.cfg and we see our normal boot options

# Notes
- the fun zone
- i write unnessesarily long READMEs
- you don't have to READ IT, but you did read (until) this line, so: Hello :D
- if you generate or copy your grub.cfg to /boot/grub/custom.cfg your grub will be stuck in an infinite loop! (Luckily I learned that in a VM)
- This took more energy from me than it should've
- I'm happy how it turned out, can't wait for all the merge requests ha ha
- USE THIS ON YOUR OWN RISK, if your grub is broken i take no responsibilty, better have that live boot stick ready
- Also check out this minecraft plymouth theme by nikp123 for a minecraft loading screen during boot: https://github.com/nikp123/minecraft-plymouth-theme
