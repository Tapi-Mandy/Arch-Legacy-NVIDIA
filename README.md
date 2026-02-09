# Arch Legacy NVIDIA Installer 👁️ 🟢

#### An automated deployment script for Arch Linux users with NVIDIA GPUs that are no longer supported by the latest (590+) driver branch. This script specifically targets the **580xx legacy branch** to restore performance and compatibility for Pascal, Maxwell, and Volta cards in ~~late 2025~~ 2026, and for the future.

---

### ✔ Supported Hardware
> This script is for users with the following architectures:

* **Pascal:** GTX 1080 Ti, 1080, 1070, 1060, 1050, GT 1030, etc.
* **Maxwell:** GTX 980 Ti, 980, 970, 960, 950, 750 Ti, 750.
* **Volta:** TITAN V.
* **Quadro:** P-series and M-series workstation cards.

---

### ➥ `install_nvidia.sh`
> Run this command to execute the installer:
```bash
curl -fsSL "https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/install_nvidia.sh" | bash
```

#### This script automates the complex configuration required for modern Linux environments on legacy hardware:
* **Init-Agnostic Design:** Works seamlessly on standard Arch and all Artix flavors (OpenRC, Runit, 66, S6).
* **All Kernels Ready:** Automatically detects and installs matching headers for the `linux (mainline)`, `linux-lts`, `linux-zen`, and `linux-hardened` kernels.
* **Intelligent Cleanup:** Purges conflicting drivers and legacy X11 snippets to ensure a clean, "black-screen-free" deployment.
* **Xorg (X11) Optimization:** Enhances traditional desktop performance by enabling DRM modesetting for "tear-free" rendering and better resolution handling in X11.
* **Wayland Optimization:** Automatically configures DRM modesetting, `fbdev`, and environment variables for a flicker-free Wayland experience.
* **Compositor Compatibility:** Includes specific fixes for `wlroots` compositors (like MangoWC, Hyprland, and Sway), including the critical invisible hardware cursor patch.
* **Intel IBT Patch:** Detects 11th Gen+ Intel CPUs and applies the `ibt=off` kernel parameter to prevent boot-time black screens.
* **Universal Bootloader Logic:** Automatically detects and updates configurations for GRUB, systemd-boot, Limine, and Syslinux.

> **Note:** This script is fully "Dual-Session" compatible. It prepares your system so you can switch between Xorg and Wayland without needing to reconfigure your drivers.

### Note on "Missing Firmware" Warnings
>During installation, you may see a warning: `Possibly missing firmware for module: 'nvidia'`.

>**This is normal.** The 580xx driver looks for GSP firmware used by newer RTX cards. Since Pascal (10-series) and Maxwell (900-series) do not use this firmware, the warning can be safely ignored.

> [!IMPORTANT]
> This script **modifies critical system files**, including `/etc/pacman.conf`, `/etc/mkinitcpio.conf`, and your **bootloader configuration** (GRUB, Systemd-boot, Limine, or Syslinux). 
>
> You should always ensure you have a fallback (such as a Live USB) ready to `arch-chroot` into your system if the driver installation results in a "black screen" or boot failure.

---

### ➥ `check_gpu.sh`
#### After rebooting, run the GPU checker made for this.
> Run this command to execute the GPU checker:
```bash
curl -fsSL "https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/check_gpu.sh" | bash
```

#### This tool checks your GPU and the legacy drivers to ensure that it's actually doing the work:
*   **Driver Detection:** Checks if the `580xx` modules are loaded and identifies if you're currently running on the proprietary drivers or Nouveau or with no drivers at all.
*   **Hardware Mapping:** Shows your GPU model and verifies the hardware is actually being controlled by the NVIDIA driver.
*   **OpenGL Check:** Verifies that the NVIDIA vendor string is active so you don't accidentally fall back to software rendering or integrated graphics.
*   **Vulkan Status:** Confirms the Vulkan API is working and correctly detects your GPU.
*   **32-Bit Support:** Scans for the `lib32` libraries required to make Steam and Wine work.

---

#### For users who prefer the open-source Nouveau driver, this script purges all proprietary NVIDIA remnants and optimizes the system for a high-performance, native open-source experience across all kernels, bootloaders, and init systems.

### ➥ `install_nouveau.sh`
> Has not been tested, but.. Should work!
> 
> <sub>If there are any issues, email me at mandytapi@gmail.com or create a <a href="https://github.com/Tapi-Mandy/Arch-Legacy-NVIDIA/issues">GitHub Issue</a>.</sub>

> Run this command to install Nouveau and purge proprietary drivers:
```bash
curl -fsSL "https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/install_nouveau.sh" | bash
```

* **Proprietary Cleanup:** Scans and purges every trace of proprietary NVIDIA packages.
* **Nouveau Optimization:** Deploys the open-source Mesa stack and configures Early KMS for native-resolution rendering from the moment the kernel loads.
* **Configuration Cleanup:** Wipes out NVIDIA-specific blacklists, environment variables, and legacy X11 snippets to restore system defaults.
* **Bootloader Parameter Scrubbing:** Automatically detects and removes proprietary kernel flags from GRUB, systemd-boot, Limine, and Syslinux.
* **Universal Kernel & Init Support:** Full parity with the main installer. Works on Mainline, LTS, Zen, and Hardened kernels across Systemd, OpenRC, Runit, and 66.
