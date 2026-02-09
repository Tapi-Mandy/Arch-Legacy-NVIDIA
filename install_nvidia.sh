#!/bin/bash
set -euo pipefail
main() {

# =================================================================
# REPO: Arch-Legacy-NVIDIA
# DESCRIPTION: Automated installer for NVIDIA 580xx Legacy Drivers
# =================================================================

# NVIDIA Color Palette
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
echo -e "${GREEN}>>> Legacy NVIDIA Drivers Installer...${NC}"

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

# 2. Handle Conflicts
echo -e "${GREEN}>>> Checking for conflicting NVIDIA drivers...${NC}"

# Pre-authenticate sudo so it doesn't timeout or fail silently in the loop
sudo -v

CONFLICTS=(
    "nvidia" 
    "nvidia-utils" 
    "lib32-nvidia-utils" 
    "nvidia-open" 
    "nvidia-open-dkms" 
    "nvidia-dkms"
)

for pkg in "${CONFLICTS[@]}"; do
    # Check if package is installed
    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "${GREEN}>>> Removing: $pkg${NC}"
        # '|| true' so that if removal fails, the script doesn't crash
        sudo pacman -Rdd "$pkg" --noconfirm &> /dev/null || true
    fi
done

# 2.5 X11 Safety Cleanup
echo -e "${GREEN}>>> Cleaning up legacy X11 configurations to prevent conflicts...${NC}"

# Backup and remove the main xorg.conf if it exists
if [ -f /etc/X11/xorg.conf ]; then
    echo -e "${GREEN}>>> Backing up /etc/X11/xorg.conf to /etc/X11/xorg.conf.bak${NC}"
    sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.bak
fi

# Remove any NVIDIA-specific snippets in xorg.conf.d safely
# Using a nullglob-style check to prevent 'ls' from erroring out under set -e
shopt -s nullglob
NVIDIA_CONFIGS=(/etc/X11/xorg.conf.d/*nvidia*)
shopt -u nullglob

if [ ${#NVIDIA_CONFIGS[@]} -gt 0 ]; then
    echo -e "${GREEN}>>> Removing old NVIDIA snippets from xorg.conf.d...${NC}"
    sudo rm "${NVIDIA_CONFIGS[@]}"
fi

# 3. Update System and Install Correct Kernel Headers
echo -e "${GREEN}>>> Detecting running kernel and installing matching headers...${NC}"

# Detect kernel type
K_RUNNING=$(uname -r)
K_PKG="linux"
K_HEADERS="linux-headers"

if [[ "$K_RUNNING" == *"-lts"* ]]; then
    K_PKG="linux-lts"
    K_HEADERS="linux-lts-headers"
elif [[ "$K_RUNNING" == *"-zen"* ]]; then
    K_PKG="linux-zen"
    K_HEADERS="linux-zen-headers"
elif [[ "$K_RUNNING" == *"-hardened"* ]]; then
    K_PKG="linux-hardened"
    K_HEADERS="linux-hardened-headers"
fi

echo -e "${GREEN}>>> Running kernel: $K_RUNNING${NC}"
echo -e "${GREEN}>>> Installing: base-devel and $K_HEADERS${NC}"

# Update system and install headers
sudo pacman -Syu --needed --noconfirm base-devel "$K_HEADERS"

# Check if a kernel update was just downloaded (Pending Reboot)
# We compare the version of the installed kernel package with the running kernel
K_INSTALLED=$(pacman -Q "$K_PKG" | awk '{print $2}')

if [[ "$K_RUNNING" != *"$K_INSTALLED"* ]]; then
    echo -e "${GREEN}>>> NOTICE: A kernel update ($K_INSTALLED) was installed.${NC}"
    echo -e "${GREEN}>>> Your running kernel is still $K_RUNNING.${NC}"
    echo -e "${GREEN}>>> DKMS will finish building the driver automatically after you reboot.${NC}"
else
    if command -v dkms &> /dev/null; then
        echo -e "${GREEN}>>> Triggering DKMS build...${NC}"
        # Use '|| true' so a minor build warning doesn't trigger 'set -e' and kill the script
        sudo dkms autoinstall || echo -e "${GREEN}>>> DKMS build had a notice, but continuing...${NC}"
    fi
fi

# 4. Install the 580xx Legacy Suite
echo -e "${GREEN}>>> Installing 580xx driver suite via $AUR_HELPER...${NC}"
$AUR_HELPER -S --noconfirm nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils nvidia-580xx-settings

# 5. Configure Early KMS
echo -e "${GREEN}>>> Configuring mkinitcpio for early module loading...${NC}"
# Checks specifically for "nvidia" as a whole word inside the MODULES line
if grep -qE '^MODULES=.*\bnvidia\b' /etc/mkinitcpio.conf; then
    echo -e "${GREEN}>>> Modules already present. Regenerating...${NC}"
else
    sudo sed -i 's/^MODULES=(/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
fi
sudo mkinitcpio -P

# 6. Set Kernel Parameter for Modesetting, fbdev, and IBT
echo -e "${GREEN}>>> Determining optimal kernel parameters...${NC}"

# Base parameters for NVIDIA Wayland
K_PARAMS="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"

# Auto-detect Intel 11th Gen or newer for IBT fix
if grep -q "GenuineIntel" /proc/cpuinfo; then
    if grep -qiE "i[3-9]-1[1-9]" /proc/cpuinfo || grep -qiE "Intel.* [1-9][1-9]th Gen" /proc/cpuinfo; then
        echo -e "${GREEN}>>> Modern Intel CPU detected (11th Gen+). Adding ibt=off...${NC}"
        K_PARAMS="$K_PARAMS ibt=off"
    fi
fi

echo -e "${GREEN}>>> Applying parameters: $K_PARAMS${NC}"

# --- BOOTLOADER DETECTION & CONFIGURATION ---

# Helper function to add parameters safely
add_param() {
    local file=$1
    local sed_cmd=$2
    # Only add if nvidia_drm.modeset=1 isn't already there and file exists
    if [ -f "$file" ] && ! grep -q "nvidia_drm.modeset=1" "$file"; then
        sudo sed -i "$sed_cmd" "$file"
        return 0
    fi
    return 1
}

# 6.1. GRUB
if [ -f /etc/default/grub ]; then
    echo -e "${GREEN}>>> Detected GRUB...${NC}"
    if add_param "/etc/default/grub" "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$K_PARAMS /"; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

# 6.2. Systemd-boot (or sd-boot on Artix)
elif [ -d /boot/loader/entries ]; then
    echo -e "${GREEN}>>> Detected systemd-boot/sd-boot...${NC}"
    for entry in /boot/loader/entries/*.conf; do
        add_param "$entry" "/^options / s/$/ $K_PARAMS/"
    done

# 6.3. Limine
elif [ -f /boot/limine.cfg ] || [ -f /boot/limine/limine.cfg ]; then
    echo -e "${GREEN}>>> Detected Limine...${NC}"
    LIMINE_CONF=$([ -f /boot/limine.cfg ] && echo "/boot/limine.cfg" || echo "/boot/limine/limine.cfg")
    add_param "$LIMINE_CONF" "s/\(cmdline:.*\)/\1 $K_PARAMS/"

# 6.4. Syslinux
elif [ -f /boot/syslinux/syslinux.cfg ]; then
    echo -e "${GREEN}>>> Detected Syslinux...${NC}"
    add_param "/boot/syslinux/syslinux.cfg" "/APPEND / s/$/ $K_PARAMS/"
fi

# 6.5 Enable NVIDIA Power Management (Crucial for Wayland Sleep/Resume)
echo -e "${GREEN}>>> Configuring NVIDIA Power Management for Suspend/Resume...${NC}"
if pidof systemd >/dev/null; then
    echo -e "${GREEN}>>> Systemd detected: Enabling nvidia-suspend/resume services...${NC}"
    sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
elif command -v loginctl >/dev/null; then
    echo -e "${GREEN}>>> elogind detected: Ensure your init scripts handle NVIDIA sleep hooks.${NC}"
fi

# 6.6 Setup Wayland Environment Variables
echo -e "${GREEN}>>> Configuring environment for Wayland...${NC}"
VAR_FILE="/etc/environment"
ENV_VARS=(
    "GBM_BACKEND=nvidia-drm"
    "__GLX_VENDOR_LIBRARY_NAME=nvidia"
    "LIBVA_DRIVER_NAME=nvidia"
    "WLR_NO_HARDWARE_CURSORS=1"
)

for var in "${ENV_VARS[@]}"; do
    if ! grep -q "$var" "$VAR_FILE"; then
        echo "$var" | sudo tee -a "$VAR_FILE" > /dev/null
    fi
done

# 7. Finalize & Exit
echo -e
echo -e "${GREEN}>>> Driver installation complete!${NC}"
echo -e "${GREEN}>>> A reboot is required to load the new drivers and kernel parameters.${NC}"
read -p "Would you like to reboot now? (y/n) " -n 1 -r </dev/tty
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}>>> Initializing reboot sequence...${NC}"

    # Check for systemd
    if pidof systemd >/dev/null; then
        echo -e "${GREEN}>>> Systemd detected... Rebooting...${NC}"
        systemctl reboot -i
    
    # Check for OpenRC
    elif [ -x /sbin/openrc-shutdown ]; then
        echo -e "${GREEN}>>> OpenRC detected... Rebooting...${NC}"
        openrc-shutdown --reboot now
    
    # Check for runit/66
    elif [ -x /usr/bin/66 ] || [ -x /usr/bin/runit ]; then
        echo -e "${GREEN}>>> Runit/66 detected... Rebooting...${NC}"
        reboot
    
    # Universal Fallback
    else
        echo -e "${GREEN}>>> Rebooting...${NC}"
        reboot -f
    fi
else
    echo -e "${GREEN}>>> Installation finished. Please reboot manually when ready.${NC}"
fi

# Ensures the script ends successfully even if no reboot was triggered
exit 0
}

# Execute the script
main "$@"
