#!/bin/bash
set -euo pipefail
main() {

# Aesthetic Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
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

# --- Dependencies ---
# Check for glxinfo (mesa-utils) and vulkaninfo (vulkan-tools)
DEPENDENCIES=("mesa-utils" "vulkan-tools")
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
    if ! pacman -Qs "$dep" > /dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${GREEN}>>> Installing missing tools: ${MISSING_DEPS[*]}${NC}"
    # Redirect only standard output, allowing the sudo prompt (stderr) to show
    sudo pacman -S --needed --noconfirm "${MISSING_DEPS[@]}" > /dev/null
fi

echo -e "${GREEN}>>> NVIDIA Legacy Driver Checker${NC}"
echo "---------------------------------------------------------------------"

# 1. Driver Module Check
echo -ne "${GREEN}[*] Kernel Modules: ${NC}"
if lsmod | grep -q "^nvidia"; then
    echo -e "LOADED"
else
    echo -e "${RED}NOT LOADED${NC}"
fi

# 2. Hardware Identification
echo -ne "${GREEN}[*] GPU Model:      ${NC}"
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || echo "Error querying GPU")
    echo -e "$GPU_INFO"
else
    echo -e "${RED}nvidia-smi not found${NC}"
fi

# 3. OpenGL Rendering Check
echo -ne "${GREEN}[*] OpenGL Vendor:  ${NC}"
# Since we auto-installed, glxinfo should definitely exist now
if command -v glxinfo &> /dev/null; then
    VENDOR=$(glxinfo | grep "OpenGL vendor string" | cut -d: -f2 | xargs)
    if [[ "$VENDOR" == *"NVIDIA"* ]]; then
        echo -e "$VENDOR"
    else
        echo -e "${RED}$VENDOR (Warning: Not using NVIDIA!)${NC}"
    fi
else
    echo -e "${RED}ERROR: glxinfo failed to install.${NC}"
fi

# 4. Vulkan Capability
echo -ne "${GREEN}[*] Vulkan Device:  ${NC}"
if command -v vulkaninfo &> /dev/null; then
    # Head -n 2 handles cases where multiple GPUs exist
    V_DEV=$(vulkaninfo --summary | grep "deviceName" | head -n 1 | cut -d: -f2 | xargs)
    echo -e "$V_DEV"
else
    echo -e "${RED}ERROR: vulkaninfo failed to install.${NC}"
fi

# 5. 32-Bit (Multilib) Check
echo -ne "${GREEN}[*] 32-Bit Support: ${NC}"
if pacman -Qs lib32-nvidia-580xx-utils &> /dev/null; then
    echo -e "INSTALLED (Ready for Steam/Wine)"
else
    echo -e "${RED}MISSING (Steam/Wine will not work)${NC}"
fi

echo "---------------------------------------------------------------------"
echo -e "${GREEN}>>> Checking complete.${NC}"
}

# Execute the script
main "$@"
