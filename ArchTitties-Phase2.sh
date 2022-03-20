# ArchTitties Rewrite - started March 8th 2022
# Phase 2 script

# Installing GRUB
echo -e "\e[1;34m[ArchTitties] - Bootloader\e[0m"
if [ -d "/sys/firmware/efi" ]; then
    grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/boot/efi && grub-mkconfig -o /boot/grub/grub.cfg
else
    Disk = $(cat /tmp/ArchTitties-Settings/BIOSMode)
    grub-install $Disk && grub-mkconfig -o /boot/grub/grub.cfg
fi
clear

# Timezone setup
echo -e "\e[1;34m[ArchTitties] - Timezone\e[0m"
echo -e "Installing dependency for JSON parsing..."
pacman -S jq --noconfirm --needed
timedatectl set-timezone $(curl -4 ifconfig.co/json | jq -r ".time_zone")
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf && export LANG=en_US.UTF-8
pacman -Rns jq --noconfirm > /dev/null
clear

# Hostname/user setup
echo -e "\e[1;34m[ArchTitties] - User and Hostname\e[0m"
read -r -p "Set a hostname for this install: " Hostname && echo $Hostname > /etc/hostname
echo -e "Set a root password." && passwd root
read -r -p "Set a username for the user that will be created: " Username && useradd -m -G wheel -s /bin/bash $Username && passwd $Username
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
touch /etc/hosts && echo "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$hostname" > /etc/hosts && clear

# Desktop environment setup
echo -e "\e[1;34m[ArchTitties] - Desktop Environment\e[0m"
read -r -p "ArchTitties can automate the installation for KDE Plasma and Xfce4. Which one would you like to install? " Desktop

case $Desktop in
    kde|KDE|plasma|Plasma|PLASMA)
        pacman -S --needed --noconfirm xorg plasma konsole networkmanager
        if lspci | grep -E "NVIDIA|GeForce"; then
            pacman -S nvidia --noconfirm --needed && nvidia-xconfig
        fi
        systemctl enable sddm.service && systemctl enable NetworkManager.service
        ;;
    xfce|XFCE|Xfce|xfce4|XFCE4|Xfce4)
        pacman -S --needed --noconfirm xorg lightdm lightdm-gtk-greeter xfce4 xfce4-goodies networkmanager pulseaudio pulseaudio-alsa
        if lspci | grep -E "NVIDIA|GeForce"; then
            pacman -S nvidia --noconfirm --needed && nvidia-xconfig
        fi
        systemctl enable lightdm && systemctl enable NetworkManager.service
        ;;
    *)
        echo -e "\e[1;31mNot installing a desktop environment. Sometimes this may lead to no network.\e[0m"
        sleep 3
esac
clear

echo -e "\e[1;34m[ArchTitties] - Completed\e[0m"
echo -e "\e[1;32mThe setup is complete! Rebooting in 5 seconds." && sleep 5