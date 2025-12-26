#!/bin/bash

# =================================================================
# REPO: Arch-Legacy-NVIDIA
# DESCRIPTION: Automated installer for NVIDIA 580xx Legacy Drivers
# =================================================================

# Aesthetic Colors
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
echo -e "${GREEN}>>> Initializing The Legacy NVIDIA Installer...${NC}"

# 1. Detect AUR Helper
AUR_HELPER=""
for helper in yay paru pikaur trizen aura; do
    if command -v "$helper" &> /dev/null; then
        AUR_HELPER="$helper"
        break
    fi
done

if [ -z "$AUR_HELPER" ]; then
    echo -e "${GREEN}>>> ERROR: No AUR helper detected!${NC}"
    echo -e "${GREEN}>>> This script requires an AUR helper to install the legacy driver suite.${NC}"
    echo -e "${GREEN}>>> Please install one of the following and try again:${NC}"
    echo -e "${GREEN}>>> e.g., 'yay', 'paru', 'pikaur', 'trizen', or 'aura'${NC}"
    echo -e
    echo -e "${GREEN}>>> To install yay: git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si${NC}"
    exit 1
else
    echo -e "${GREEN}>>> Detected AUR Helper: $AUR_HELPER${NC}"
fi

# 1.5 Enable Multilib (Required for 32-bit/Steam support)
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${GREEN}>>> Enabling [multilib] repository...${NC}"
    echo -e "[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
else
    echo -e "${GREEN}>>> [multilib] is already enabled.${NC}"
fi

# 2. Handle Conflicts (The "Cleanup" Phase)
echo -e "${GREEN}>>> Checking for conflicting NVIDIA drivers...${NC}"
CONFLICTS=(
    "nvidia" 
    "nvidia-utils" 
    "lib32-nvidia-utils" 
    "nvidia-open" 
    "nvidia-open-dkms" 
    "nvidia-dkms"
)

for pkg in "${CONFLICTS[@]}"; do
    # Check if package is installed; if yes, remove it quietly
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "${GREEN}>>> Removing: $pkg${NC}"
        sudo pacman -Rdd "$pkg" --noconfirm &> /dev/null
    fi
done

# 2.5 Safety Cleanup (Prevent Black Screen)
echo -e "${GREEN}>>> Cleaning up legacy X11 configurations to prevent conflicts...${NC}"
# Backup and remove the main xorg.conf if it exists
if [ -f /etc/X11/xorg.conf ]; then
    echo -e "${GREEN}>>> Backing up /etc/X11/xorg.conf to /etc/X11/xorg.conf.bak${NC}"
    sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
fi

# Remove any NVIDIA-specific snippets in xorg.conf.d
if ls /etc/X11/xorg.conf.d/*nvidia* 1> /dev/null 2>&1; then
    echo -e "${GREEN}>>> Removing old NVIDIA snippets from xorg.conf.d...${NC}"
    sudo rm /etc/X11/xorg.conf.d/*nvidia*
fi

# 3. Update System and Install Kernel Headers
echo -e "${GREEN}>>> Ensuring kernel headers and build tools are present...${NC}"
sudo pacman -Syu --needed --noconfirm base-devel linux-headers

# 4. Install the 580xx Legacy Suite
echo -e "${GREEN}>>> Installing 580xx driver suite via $AUR_HELPER...${NC}"
$AUR_HELPER -S --noconfirm nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils nvidia-580xx-settings

# 5. Configure Early KMS
echo -e "${GREEN}>>> Configuring mkinitcpio for early module loading...${NC}"
if grep -q "nvidia" /etc/mkinitcpio.conf; then
    echo -e "${GREEN}>>> Modules already present. Regenerating...${NC}"
else
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
fi
sudo mkinitcpio -P

# 6. Set Kernel Parameter for Modesetting
echo -e "${GREEN}>>> Updating bootloader for DRM modesetting...${NC}"
if [ -f /etc/default/grub ]; then
    if ! grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
elif [ -d /boot/loader/entries ]; then
    for entry in /boot/loader/entries/*.conf; do
        if ! grep -q "nvidia_drm.modeset=1" "$entry"; then
            sudo sed -i '/^options / s/$/ nvidia_drm.modeset=1/' "$entry"
        fi
    done
fi

# 7. Finalize & Reboot
echo -e "${GREEN}>>> Driver installation complete!${NC}"
read -p "Would you like to reboot now? (y/n) " -n 1 -r </dev/tty
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}>>> Initializing reboot sequence...${NC}"

    # Check if systemd is running
    if pidof systemd >/dev/null; then
        echo -e "${GREEN}>>> Systemd detected...${NC}"
        echo -e "${GREEN}>>> Rebooting...${NC}"
        systemctl reboot -i
    # Check for OpenRC
    elif [ -x /sbin/openrc-shutdown ]; then
        echo -e "${GREEN}>>> OpenRC detected...${NC}"
        echo -e "${GREEN}>>> Rebooting...${NC}"
        openrc-shutdown --reboot now
    # Check for Runit (Artix way)
    elif [ -x /usr/bin/66 ] || [ -x /usr/bin/runit ]; then
        echo -e "${GREEN}>>> Runit/66 detected...${NC}"
        echo -e "${GREEN}>>> Rebooting...${NC}"
        reboot
    # Universal Fallback (Works on almost everything)
    else
        echo -e "${GREEN}>>> Using universal fallback...${NC}"
        echo -e "${GREEN}>>> Rebooting...${NC}"
        reboot -f
    fi
fi
