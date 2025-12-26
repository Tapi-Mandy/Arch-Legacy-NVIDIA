# 👁️ 🟢 Arch Legacy NVIDIA Installer (580xx)

An automated deployment script for Arch Linux users with NVIDIA GPUs that are no longer supported by the latest (590+) driver branch. This script specifically targets the **580xx legacy branch** to restore performance and compatibility for Pascal, Maxwell, and Volta cards in late 2025, and for the future.

---

### 🛠️ What this script does
- **Pre-flight Checks:** Detects your AUR helper (`yay`, `paru`, etc.) and ensures the `[multilib]` repository is enabled.
- **Conflict Resolution:** Automatically identifies and removes the incompatible standard `nvidia-utils` to prevent installation failures.
- **Safety Cleanup:** Removes or backups old `xorg.conf` files that cause "Black Screen on Boot" issues.
- **Installation:** Installs `linux-headers`, the `580xx-dkms` driver suite, and 32-bit libraries for Steam/gaming.
- **Optimization:** Configures Early Kernel Mode Setting (KMS) and injects `nvidia_drm.modeset=1` into your bootloader (GRUB or systemd-boot).

#### Included Tools
- **`install_nvidia.sh`**: The main script.
- **`check_gpu.sh`**: Universal verification utility to ensure your GPU is actually being used for 3D rendering and that 32-bit support is active.

---

### 📟 Supported Hardware
> This script is for users with the following architectures:

* **Pascal:** GTX 1080 Ti, 1080, 1070, 1060, 1050, GT 1030, etc.
* **Maxwell:** GTX 980 Ti, 980, 970, 960, 950, 750 Ti, 750.
* **Volta:** TITAN V.
* **Quadro:** P-series and M-series workstation cards.

---

### 📥 Drivers Installer

> Run this command to download and execute the installer:
```bash
curl -s [https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/install_nvidia.sh](https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/install_nvidia.sh) | bash
```

>[!IMPORTANT]
>This script modifies critical system files, including /etc/pacman.conf, /etc/mkinitcpio.conf, and your bootloader configuration. While it includes safety backups, use this at your own risk. Always ensure you have a fallback (like a Live USB) to chroot into your system if something goes wrong.

---

### 🔍 `check_gpu.sh`

#### Once you have rebooted, it is highly recommended to run the GPU checker designed with this script in mind.
#### This tool performs a deep check of your graphics stack to ensure the legacy cards are actually doing the work.

### What it checks:
* **Kernel Status:** Confirms the `580xx` modules are loaded into the Linux kernel.
* **Hardware ID:** Pulls the specific model and driver version from the hardware.
* **OpenGL Provider:** Ensures the OS isn't accidentally falling back to integrated graphics (Mesa).
* **Vulkan Health:** Confirms that the Vulkan API is active (required for modern gaming).
* **32-Bit Check:** Verifies that the `lib32` libraries are installed so Steam and Wine work correctly.

### How to run it:
> Run this command to download and execute the GPU checker:
```bash
curl -s [https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/check_gpu.sh](https://raw.githubusercontent.com/Tapi-Mandy/Arch-Legacy-NVIDIA/main/check_gpu.sh) | bash
```

---

### 🔧 Troubleshooting

**Q: I get a black screen after rebooting!**

**A:** Use `Ctrl + Alt + F2` to switch to a TTY terminal. Login and run check_gpu.sh. Usually, this is caused by a custom X11 config the script couldn't find. Ensure /etc/X11/xorg.conf does not exist.

**Q: Steam won't open!**

**A:** Ensure the `check_gpu.sh` report shows 32-Bit Support: INSTALLED. If it is missing, your `[multilib]` repo was not synced correctly.

**Q: Will this break when the kernel updates?**

**A:** No. Because this script installs the `DKMS` version of the driver, the modules will automatically recompile themselves every time your kernel updates.
