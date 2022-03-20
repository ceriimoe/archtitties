# ArchTitties Rewrite - started March 8th 2022
# Phase 1 script

# Pre-installation preparation work
echo -e "\e[1;34m[ArchTitties] - Preparation work\e[0m"

mkdir /tmp/ArchTitties-Settings # This holds the settings for installation.
mkdir /tmp/ArchTitties-Temp # This holds any temporary files we need.

echo -e "Installing dependencies..."
pacman -Syy > /dev/null && pacman -S --needed --noconfirm reflector archlinux-keyring > /dev/null

clear

# Mirror generation
echo -e "\e[1;34m[ArchTitties] - Mirrors\e[0m"

# Setting up mirrors closer to the user.
loc=$(curl -4 ifconfig.co/country-iso)
locN=$(curl -4 ifconfig.co/country)
echo -e "Country: $locN (ISO code: $loc)" # Example -- "Country: United Kingdom (ISO code: GB)"
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo -e "Running reflector (setting up mirrors that are closer to you)..."
reflector -c $loc -f 12 -l 10 -n12 --save /etc/pacman.d/mirrorlist
echo -e "Mirror setup completed."
sleep 3 && clear

# Setting up the disks
echo -e "\e[1;34m[ArchTitties] - Disk Setup\e[0m"
fdisk -l
read -r -p "Select a disk from the list above: " Disk
read -r -p "This disk will be wiped! Do you wish to continue? (y/n)" FormatConf
case $FormatConf in
    y|Y|yes|YES)
        echo -e "Wiping the disk..."
        sgdisk -Z $Disk
        sgdisk -a 2048 -o $Disk
        if [ -d "/sys/firmware/efi" ]; then
            sgdisk -n 1::+100M --typecode=1:ef00 $Disk
            sgdisk -n 2::-0 --typecode=2:8300 $Disk
            if [[ $disk =~ "nvme" ]]; then
                mkfs.fat -F32 ${Disk}p1 && mkfs.ext4 ${Disk}p2 && mount ${Disk}p2 /mnt
            elif [[ $disk =~ "mmcblk" ]]; then
                mkfs.fat -F32 ${Disk}p1 && mkfs.ext4 ${Disk}p2 && mount ${Disk}p2 /mnt
            else
                mkfs.fat -F32 ${Disk}1 && mkfs.ext4 ${Disk}2 && mount ${Disk}2 /mnt
            fi
        else
            touch /tmp/ArchTitties-Settings/BIOSMode
            sgdisk -n 1::+1M --typecode=1:ef02 $Disk
            sgdisk -n 2::-0 --typecode=2:8300 $Disk
            if [[ $Disk =~ "nvme" ]]; then
                mkfs.ext4 ${Disk}p2 && mount ${Disk}p2 /mnt
            elif [[ $Disk =~ "mmcblk" ]]; then
                mkfs.ext4 ${Disk}p2 && mount ${Disk}p2 /mnt
            else
                mkfs.ext4 ${Disk}2 && mount ${Disk}2 /mnt
            fi
        fi
        echo -e "Process complete."
        ;;
    *)
        clear && echo -e "\e[1;31mArchTitties install has been cancelled (disk format confirmation declined).\e[0m"
        read -r -p "Restart? (y/n) " RestartConf
        case $RestartConf in
            y|Y|yes|YES)
                reboot now
                ;;
            *)
                exit
        esac
esac
clear

# Phase 1 installation process
echo -e "\e[1;34m[ArchTitties] - Phase 1 Installation\e[0m"
if [ -d "/sys/firmware/efi" ]; then
    pacstrap /mnt base sudo linux linux-firmware vim nano grub efibootmgr archlinux-keyring --noconfirm --needed
    mkdir /mnt/boot/efi
    if [[ $Disk =~ "nvme" ]]; then mount ${Disk}p1 /mnt/boot/efi
    elif [[ $Disk =~ "mmcblk" ]]; then mount ${Disk}p1 /mnt/boot/efi
    else mount ${Disk}1 /mnt/boot/efi
    fi
else
    pacstrap /mnt base base-devel linux linux-firmware vim nano grub --noconfirm --needed
fi
cp -r /tmp/ArchTitties-Settings /mnt/tmp && echo $Disk > /mnt/tmp/ArchTitties-Settings/BIOSMode
genfstab -U /mnt >> /mnt/etc/fstab
echo -e "Phase 1 completed, starting phase 2 in 3 seconds." && sleep 3 && clear
