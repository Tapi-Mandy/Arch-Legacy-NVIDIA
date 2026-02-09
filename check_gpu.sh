#!/bin/bash
set -euo pipefail

main() {
# NVIDIA Color Palette
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

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

# --- Dependency Check ---
# (Ensures tools exist before running checks)
deps=("mesa-utils" "vulkan-tools" "pciutils")
for dep in "${deps[@]}"; do
    if ! pacman -Qs "$dep" > /dev/null; then
        echo -e "${YELLOW}>>> Installing $dep for diagnostics...${NC}"
        sudo pacman -S --needed --noconfirm "$dep" > /dev/null
    fi
done

echo -e "${GREEN}>>> NVIDIA Legacy Driver Diagnostic Tool${NC}"
echo "---------------------------------------------------------------------"

# 1. Driver Identification (The core request)
echo -ne "${GREEN}[*] Driver in Use:   ${NC}"
if lsmod | grep -q "^nvidia"; then
    # Identify if it's the correct 580xx version
    CUR_VER=$(modinfo -F version nvidia 2>/dev/null || echo "Unknown")
    if [[ "$CUR_VER" == 580* ]]; then
        echo -e "${GREEN}NVIDIA $CUR_VER (Legacy 580xx Active)${NC}"
    else
        echo -e "${YELLOW}NVIDIA $CUR_VER (Mismatched Version)${NC}"
    fi
elif lsmod | grep -q "^nouveau"; then
    echo -e "${BLUE}NOUVEAU (Open Source)${NC}"
    echo -e "    ${YELLOW}Note: High-performance 3D is limited.${NC}"
else
    echo -e "${RED}NONE / UNKNOWN${NC}"
    echo -e "    ${RED}Warning: No driver is controlling the GPU!${NC}"
fi

# 2. Hardware / PCI Status
echo -ne "${GREEN}[*] GPU Hardware:    ${NC}"
LSPCI_INFO=$(lspci -k | grep -A 2 -i "VGA" | grep "NVIDIA" || echo "No NVIDIA Hardware Detected")
echo -e "$LSPCI_INFO"

# 3. Package Integrity
echo -ne "${GREEN}[*] Suite Installed: ${NC}"
if pacman -Qs nvidia-580xx-utils > /dev/null; then
    echo -e "YES (580xx suite present)"
else
    echo -e "${RED}NO (Drivers not found in pacman)${NC}"
fi

# 4. 32-Bit (Multilib) Check
echo -ne "${GREEN}[*] 32-Bit Support:  ${NC}"
if pacman -Qs lib32-nvidia-580xx-utils > /dev/null; then
    echo -e "Ready (Steam/Wine supported)"
else
    echo -e "${YELLOW}Missing (Steam/Wine will fail)${NC}"
fi

# 5. Rendering Engine
echo -ne "${GREEN}[*] OpenGL Vendor:   ${NC}"
VENDOR=$(glxinfo | grep "OpenGL vendor string" | cut -d: -f2 | xargs || echo "Error")
if [[ "$VENDOR" == *"NVIDIA"* ]]; then
    echo -e "$VENDOR"
else
    echo -e "${RED}$VENDOR (Hardware acceleration might be disabled)${NC}"
fi

echo -ne "${GREEN}[*] Vulkan Device:   ${NC}"
V_DEV=$(vulkaninfo --summary | grep "deviceName" | head -n 1 | cut -d: -f2 | xargs || echo "Not Found")
echo -e "$V_DEV"

echo "---------------------------------------------------------------------"
echo -e "${GREEN}>>> Diagnostic complete.${NC}"
}

main "$@"
