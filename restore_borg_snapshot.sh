#!/bin/bash

# Get backup device path
while true; do
    read -r -p "Give device containing backup path : " backup_device_path
    if [ -e "$backup_device_path" ]; then
        echo "Path $backup_device_path ok"
        break
    else
        echo "Path $backup_device_path does not exist. Please try again"
    fi
done

# Mount backup device path to default path
mkdir -p /mnt/usb
mount "$backup_device_path" "/mnt/usb"

# Set BORG_REPO
while true; do
    read -r -p "Backup path in mounted device: " backup_path
    if [ -e "$backup_path" ]; then
        echo "Path $backup_path ok"
        break
    else
        echo "Path $backup_path does not exist. Please try again"
    fi
done
borg_repo_var="/mnt/usb/$backup_path"
export BORG_REPO="$borg_repo_var"
echo "BORG_REPO variable is set to $BORG_REPO"

# Get destination device path
while true; do
    read -r -p "Give destination device path : " destination_device_path
    if [ -e "$destination_device_path" ]; then
        echo "Path $destination_device_path ok"
        break
    else
        echo "Path $destination_device_path does not exist. Please try again"
    fi
done

# Mount destination device path to default path
mkdir -p /mnt/destination
mount "$destination_device_path" /mnt/destination

# Display backups in repo
borg list

# Get backup repo name
read -r -p "Give backup name : " backup_name

# Extract backup to destination
cd /mnt/destination || 1
borg extract --progress "$borg_repo_var::$backup_name"

# Get gpt partition path
while true; do
    read -r -p "Give GPT partition path : " gpt_path
    if [ -e "$gpt_path" ]; then
        echo "Path $gpt_path ok"
        break
    else
        echo "Path $gpt_path does not exist. Please try again"
    fi
done

# Mount gpt partition to efi path
mount "$gpt_path" /mnt/destination/boot/efi

# Proceed special mounts
mount --bind /dev /mnt/destination/dev
mount --bind /run /mnt/destination/run
mount -t sysfs /sys /mnt/destination/sys
mount -t proc /proc /mnt/destination/proc

chroot /mnt/destination
grub-install
update-grub
umount -R -l /mnt/destination
