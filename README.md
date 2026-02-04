# 👁️ 🟢 Arch Legacy NVIDIA Installer

#### An automated deployment script for Arch Linux users with NVIDIA GPUs that are no longer supported by the latest (590+) driver branch. This script specifically targets the **580xx legacy branch** to restore performance and compatibility for Pascal, Maxwell, and Volta cards in late 2025, and for the future.

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
* **Kernel Status:** Confirms the `580xx` modules are loaded into the Linux kernel.
* **Hardware ID:** Pulls the specific model and driver version from the hardware.
* **OpenGL Provider:** Ensures the OS isn't accidentally falling back to integrated graphics.
* **Vulkan Health:** Confirms that the Vulkan API is active.
* **32-Bit Check:** Verifies that the `lib32` libraries are installed so Steam and Wine work correctly.
