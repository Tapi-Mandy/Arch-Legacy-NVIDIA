# 👁️ 🟢 Arch Legacy NVIDIA Installer

#### An automated deployment script for Arch Linux users with NVIDIA GPUs that are no longer supported by the latest (590+) driver branch. This script specifically targets the **580xx legacy branch** to restore performance and compatibility for Pascal, Maxwell, and Volta cards in late 2025, and for the future.

---

### ➥ Drivers Installer

> Run this command to execute the installer:
```bash
curl -s "https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/install_nvidia.sh" | bash
```

### Note on "Missing Firmware" Warnings
>During installation, you may see a warning: `Possibly missing firmware for module: 'nvidia'`.

>**This is normal.** The 580xx driver looks for GSP firmware used by newer RTX cards. Since Pascal (10-series) and Maxwell (900-series) do not use this firmware, the warning can be safely ignored.

>[!IMPORTANT]
>This script modifies critical system files, including /etc/pacman.conf, /etc/mkinitcpio.conf, and your bootloader configuration. Always ensure you have a fallback (like a Live USB) to chroot into your system if something goes wrong.

---

### ➥ `check_gpu.sh`
#### After rebooting, run the GPU checker made for this.
> Run this command to execute the GPU checker:
```bash
curl -s "https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/check_gpu.sh" | bash
```

#### This tool checks your GPU and the legacy drivers to ensure that it's actually doing the work:
* **Kernel Status:** Confirms the `580xx` modules are loaded into the Linux kernel.
* **Hardware ID:** Pulls the specific model and driver version from the hardware.
* **OpenGL Provider:** Ensures the OS isn't accidentally falling back to integrated graphics.
* **Vulkan Health:** Confirms that the Vulkan API is active.
* **32-Bit Check:** Verifies that the `lib32` libraries are installed so Steam and Wine work correctly.

---

### ✔ Supported Hardware
> This script is for users with the following architectures:

* **Pascal:** GTX 1080 Ti, 1080, 1070, 1060, 1050, GT 1030, etc.
* **Maxwell:** GTX 980 Ti, 980, 970, 960, 950, 750 Ti, 750.
* **Volta:** TITAN V.
* **Quadro:** P-series and M-series workstation cards.
