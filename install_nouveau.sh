#!/bin/bash
set -euo pipefail
main() {

# # NVIDIA Color Palette
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "                      @@@@        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "                @@@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "            @@@@@@@@      @@@@@@@@         @@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "         @@@@@@@          @@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@"
echo "      @@@@@@@         @@@@       @@@@@@@@       @@@@@@@@@@@@@@@@@@@@@"
echo "   @@@@@@@       @@@@@@@@@          @@@@@@@       @@@@@@@@@@@@@@@@@@@"
echo " @@@@@@@       @@@@@@     @@@          @@@@@@       @@@@@@@@@@@@@@@@@"
echo "@@@@@@@     @@@@@@@       @@@@@       @@@@@@@       @@@@@@@@@@@@@@@@@"
echo " @@@@@@@     @@@@@        @@@@@@    @@@@@@@       @@@@@@@@@@@@@@@@@@@"
echo "  @@@@@@@     @@@@@       @@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@"
echo "   @@@@@@@     @@@@@      @@@@@@@@@@@@@       @@@@@@@@    @@@@@@@@@@@"
echo "     @@@@@@     @@@@@@    @@@@@@@@@@@      @@@@@@@@@          @@@@@@@"
echo "      @@@@@@@     @@@@@@@ @@@@@@@       @@@@@@@@@              @@@@@@"
echo "        @@@@@@@      @@@@@           @@@@@@@@@              @@@@@@@@@"
echo "          @@@@@@@         @@@@@@@@@@@@@@@@@              @@@@@@@@@@@@"
echo "            @@@@@@@@      @@@@@@@@@@@@              @@@@@@@@@@@@@@@@@"
echo "               @@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@"
echo "                    @@@@@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "                          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "${NC}"
echo -e "${GREEN}>>> Nouveau Open-Source Driver Installer...${NC}"

# 1. Detect Running Kernel & Headers
echo -e "${GREEN}>>> Detecting kernel type...${NC}"
K_RUNNING=$(uname -r)
K_HEADERS="linux-headers"
if [[ "$K_RUNNING" == *"-lts"* ]]; then K_HEADERS="linux-lts-headers"
elif [[ "$K_RUNNING" == *"-zen"* ]]; then K_HEADERS="linux-zen-headers"
elif [[ "$K_RUNNING" == *"-hardened"* ]]; then K_HEADERS="linux-hardened-headers"; fi

# 2. The Purge Phase (Universal NVIDIA Removal)
echo -e "${GREEN}>>> Purging all proprietary NVIDIA packages...${NC}"
PROPRIETARY_PKGS=$(pacman -Qs nvidia | grep '^local/' | cut -d'/' -f2 | cut -d' ' -f1 | grep -v "nouveau" || true)
if [ -n "$PROPRIETARY_PKGS" ]; then
    sudo pacman -Rdd --noconfirm $PROPRIETARY_PKGS &> /dev/null || true
fi

# 3. Install Open-Source Stack
echo -e "${GREEN}>>> Installing Nouveau & Mesa for $K_RUNNING...${NC}"
INSTALL_LIST="xf86-video-nouveau mesa $K_HEADERS base-devel"
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    INSTALL_LIST="$INSTALL_LIST lib32-mesa"
fi
sudo pacman -Syu --needed --noconfirm $INSTALL_LIST

# 4. Cleanup Configuration Files & Blacklists
echo -e "${GREEN}>>> Restoring configuration defaults...${NC}"
sudo rm -f /etc/modprobe.d/nouveau-blacklist.conf
sudo rm -f /etc/modprobe.d/nvidia.conf
sudo rm -f /etc/X11/xorg.conf.d/*nvidia*
# Restore Xorg backup if it exists
[ -f /etc/X11/xorg.conf.bak ] && sudo mv /etc/X11/xorg.conf.bak /etc/X11/xorg.conf

# 5. Early KMS Setup
echo -e "${GREEN}>>> Configuring mkinitcpio for Nouveau...${NC}"
sudo sed -i 's/nvidia nvidia_modeset nvidia_uvm nvidia_drm //' /etc/mkinitcpio.conf
if ! grep -q "nouveau" /etc/mkinitcpio.conf; then
    sudo sed -i 's/^MODULES=(/MODULES=(nouveau /' /etc/mkinitcpio.conf
fi
sudo mkinitcpio -P

# 6. --- BOOTLOADER PARAMETER SCRUBBING ---
echo -e "${GREEN}>>> Scrubbing proprietary parameters from bootloader...${NC}"
clean_cmd="s/nvidia_drm.modeset=1 //g; s/nvidia_drm.fbdev=1 //g; s/ibt=off //g"

# 6.1. GRUB
if [ -f /etc/default/grub ]; then
    echo -e "${GREEN}>>> Cleaning GRUB...${NC}"
    sudo sed -i "$clean_cmd" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg

# 6.2. Systemd-boot
elif [ -d /boot/loader/entries ]; then
    echo -e "${GREEN}>>> Cleaning systemd-boot...${NC}"
    for entry in /boot/loader/entries/*.conf; do sudo sed -i "$clean_cmd" "$entry"; done

# 6.3. Limine
elif [ -f /boot/limine.cfg ] || [ -f /boot/limine/limine.cfg ]; then
    echo -e "${GREEN}>>> Cleaning Limine...${NC}"
    LIMINE_CONF=$([ -f /boot/limine.cfg ] && echo "/boot/limine.cfg" || echo "/boot/limine/limine.cfg")
    sudo sed -i "$clean_cmd" "$LIMINE_CONF"

# 6.4. Syslinux
elif [ -f /boot/syslinux/syslinux.cfg ]; then
    echo -e "${GREEN}>>> Cleaning Syslinux...${NC}"
    sudo sed -i "$clean_cmd" /boot/syslinux/syslinux.cfg
fi

# 7. Cleanup Power Management & Env Vars
echo -e "${GREEN}>>> Cleaning system services and environment...${NC}"
if pidof systemd >/dev/null; then
    # Disable proprietary power services if they exist
    sudo systemctl disable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service &> /dev/null || true
fi

VAR_FILE="/etc/environment"
for var in "GBM_BACKEND=nvidia-drm" "__GLX_VENDOR_LIBRARY_NAME=nvidia" "LIBVA_DRIVER_NAME=nvidia" "WLR_NO_HARDWARE_CURSORS=1"; do
    sudo sed -i "/$var/d" "$VAR_FILE"
done

# 8. Init-Agnostic Reboot
echo -e
echo -e "${GREEN}>>> Nouveau installation complete!${NC}"
read -p "Would you like to reboot now? (y/n) " -n 1 -r </dev/tty
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}>>> Initializing reboot sequence...${NC}"
    if pidof systemd >/dev/null; then
        echo -e "${GREEN}>>> Systemd detected... Rebooting...${NC}"
        systemctl reboot -i
    elif [ -x /sbin/openrc-shutdown ]; then
        echo -e "${GREEN}>>> OpenRC detected... Rebooting...${NC}"
        openrc-shutdown --reboot now
    elif [ -x /usr/bin/66 ] || [ -x /usr/bin/runit ]; then
        echo -e "${GREEN}>>> Runit/66 detected... Rebooting...${NC}"
        reboot
    else
        echo -e "${GREEN}>>> Rebooting...${NC}"
        reboot -f
    fi
else
    echo -e "${GREEN}>>> Installation finished. Please reboot manually when ready.${NC}"
fi

exit 0
}

# Execute the script
main "$@"
