# STM32 VS Code Development Environment Setup

A modern, fast, and lightweight STM32 firmware development environment using **VS Code**, **CMake**, **Ninja**, **OpenOCD**, and **ARM GNU Toolchain (`arm-none-eabi-gcc`)**.

No bloated IDEs required. Works seamlessly on **Linux (Arch, Ubuntu/Debian, Fedora)** and **Windows**.

---

## 📑 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites \& Toolchain Installation](#prerequisites--toolchain-installation)
  - [Arch Linux / Manjaro](#arch-linux--manjaro)
  - [Ubuntu / Debian / Linux Mint](#ubuntu--debian--linux-mint)
  - [Fedora / RHEL](#fedora--rhel)
  - [Windows 10 / 11](#windows-10--11)
- [VS Code Extensions](#vs-code-extensions)
- [Setting Up a New Project (Step-by-Step)](#setting-up-a-new-project-step-by-step)
  - [1. STM32CubeMX Setup](#1-stm32cubemx-setup)
  - [2. Apply the VS Code Template](#2-apply-the-vs-code-template)
  - [3. The Critical Blue Pill 10KB RAM Linker Fix](#3-the-critical-blue-pill-10kb-ram-linker-fix)
- [Daily Development Workflow](#daily-development-workflow)
  - [VS Code Shortcuts](#vs-code-shortcuts)
  - [Terminal Commands & Shell Aliases](#terminal-commands--shell-aliases)
- [Troubleshooting Common Traps](#troubleshooting-common-traps)

---

## 🛠 Architecture Overview

```
                      +-----------------------------+
                      |         VS Code             |
                      |  (Editor / Cortex-Debug)    |
                      +--------------+--------------+
                                     |
              +----------------------+----------------------+
              |                                             |
              v                                             v
       [ Build Stage ]                               [ Debug/Flash Stage ]
  CMake + Ninja + GCC                            OpenOCD + arm-none-eabi-gdb
  Produces .elf binary                                      |
                                                            v
                                                    ST-LINK V2 (SWD)
                                                            |
                                                            v
                                                    STM32 Target Board
```

---

## 📦 Prerequisites & Toolchain Installation

### Arch Linux / Manjaro
```bash
sudo pacman -S arm-none-eabi-gcc arm-none-eabi-newlib arm-none-eabi-binutils \
               cmake ninja openocd clang
```

### Ubuntu / Debian / Linux Mint
```bash
sudo apt update
sudo apt install gcc-arm-none-eabi libnewlib-arm-none-eabi binutils-arm-none-eabi \
                 cmake ninja-build openocd clangd
```

#### Linux USB Udev Rules (Important!)
To allow non-root access to the ST-Link programmer:
```bash
sudo usermod -aG plugdev $USER
# OpenOCD usually provides standard udev rules:
sudo cp /usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d/ 2>/dev/null || true
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### Fedora / RHEL
```bash
sudo dnf install arm-none-eabi-gcc-cs arm-none-eabi-newlib \
                 cmake ninja-build openocd clang-tools-extra
```

### Windows 10 / 11
1. **ARM GNU Toolchain**: Download and install from [Arm Developer GNU Toolchain Downloads](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads) (check "Add to PATH").
2. **OpenOCD**: Download prebuilt binaries from [OpenOCD releases](https://github.com/openocd-org/openocd/releases) or via Scoop / Chocolatey:
   ```powershell
   scoop install openocd cmake ninja
   ```
3. **ST-Link Drivers**: Install the official [ST-SW-LINK009 Driver](https://www.st.com/en/development-tools/st-sw-link009.html) or use [Zadig](https://zadig.akeo.ie/) to assign WinUSB to ST-Link.
4. **LLVM / Clangd**: Download and install LLVM from [GitHub LLVM releases](https://github.com/llvm/llvm-project/releases).

---

## 🧩 VS Code Extensions
Install the following extensions in VS Code:
- **[Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug)** (`marus25.cortex-debug`): Core hardware debugging engine.
- **[clangd](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.vscode-clangd)** (`llvm-vs-code-extensions.vscode-clangd`): Fast C/C++ code intelligence and autocomplete.
- **[CMake Tools](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cmake-tools)** (`ms-vscode.cmake-tools`): CMake project configuration and build automation.

> **Note:** If you have Microsoft's `C/C++` extension installed, set `"C_Cpp.intelliSenseEngine": "disabled"` to avoid conflicts with `clangd`.

---

## 🚀 Setting Up a New Project (Step-by-Step)

### 1. STM32CubeMX Setup
1. Create a new project and select your MCU (e.g. `STM32F103C6Tx` or `STM32F103C8Tx`).
2. **CRITICAL: Enable Serial Wire Debugging**:
   - Go to **System Core** $\to$ **SYS**.
   - Change **Debug** from *No Debug* to **Serial Wire**. *(Pins PA13/PA14 will turn green. If left on No Debug, the chip shuts off its own ST-Link pins upon boot!)*
3. **Project Manager Tab**:
   - Set **Toolchain / IDE** to **CMake**.
   - Click **Generate Code**.

### 2. Apply the VS Code Template
Copy the template files from this repository into your new project root:
```bash
cp -r template/.vscode <your-project-folder>/
cp template/.clangd <your-project-folder>/
```

In `.vscode/launch.json` and `.vscode/tasks.json`, update the executable name from `OLED.elf` to `<YourProjectName>.elf`.

Generate the compilation database for autocomplete:
```bash
cmake -B build/Debug -S . -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/gcc-arm-none-eabi.cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sf build/Debug/compile_commands.json compile_commands.json
```

---

### 3. The Critical Blue Pill 10KB RAM Linker Fix

Most budget STM32 Blue Pill boards available today are labeled `STM32F103C8T6` (which should have 20 KB RAM), but physically contain **binned or remarked 10 KB RAM dies** (equivalent to C6 silicon, device ID `0x10006412`).

If you select C8T6 in CubeMX, it calculates `_estack = 0x20005000`. When the CPU boots and calls the first function, it pushes to an unmapped RAM address, immediately throwing an unrecoverable **`HardFault`**.

**The Fix:**
Open `STM32F103xx_FLASH.ld` and ensure the RAM length is set to `10K`:
```ld
MEMORY
{
  RAM (xrw)      : ORIGIN = 0x20000000, LENGTH = 10K
  FLASH (rx)     : ORIGIN = 0x8000000, LENGTH = 64K
}
```
*(Every time CubeMX regenerates code, verify this line remains 10K).*

---

## ⚡ Daily Development Workflow

### VS Code Shortcuts
- **`Ctrl + Shift + B`**: Builds the firmware using `ninja`.
- **`F5`**: One-click debug session (builds, flashes, halts at `main()`).
- **`Ctrl + Shift + P` $\to$ `Tasks: Run Task` $\to$ `Flash Device (Build & Flash)`**: Direct flash without debugging.

### Terminal Commands & Shell Aliases

#### Bash / Zsh (`~/.bashrc` or `~/.zshrc`)
```bash
stm_bld() { ninja -C build/Debug; }
stm_fls() { openocd -f interface/stlink.cfg -c "reset_config none" -f target/stm32f1x.cfg -c "init; halt; program build/Debug/*.elf verify reset exit"; }
stm_bfs() { stm_bld && stm_fls; }
```

#### Fish Shell (`~/.config/fish/config.fish`)
```fish
function stm_bld -d "Build STM32 project"
    ninja -C build/Debug
end

function stm_fls -d "Flash STM32 project"
    set -l elf (find build/Debug -maxdepth 1 -name "*.elf" | head -n 1)
    openocd -f interface/stlink.cfg -c "reset_config none" -f target/stm32f1x.cfg -c "init; halt; program $elf verify reset exit"
end

function stm_bfs -d "Build & Flash STM32 project"
    stm_bld; and stm_fls
end
```

---

## 🔍 Troubleshooting Common Traps

| Symptom | Cause | Solution |
|---|---|---|
| `init mode failed (unable to connect to target)` | CubeMX generated `No Debug` (`__HAL_AFIO_REMAP_SWJ_DISABLE()`) | Hold physical **Reset** button on board, start flashing, release Reset as soon as OpenOCD connects. Change CubeMX SYS to Serial Wire. |
| `Cannot find bounds of current function (from exec-next)` | Booted into system bootloader ROM | Check physical jumpers: ensure **BOOT0 = 0** and **BOOT1 = 0**. |
| Immediate `HardFault` / LED doesn't run | Linker configured 20KB RAM on a 10KB chip | In `STM32F103xx_FLASH.ld`, set `RAM LENGTH = 10K`. |
| Missing headers / red squiggles in VS Code | `clangd` lacks compile commands or target compiler headers | Symlink `compile_commands.json` to project root and add `--query-driver=/usr/bin/arm-none-eabi*` in settings. |
| OLED displays static noise / QR code pattern | I2C transmission timeout (10ms default) | Set I2C mode to **Fast Mode (400 kHz)** or raise `HAL_I2C_Master_Transmit` timeout to 100ms. |

---

## 📚 Handbook
A comprehensive 15-page PDF reference handbook covering embedded hardware internals, memory mapping, and troubleshooting is available under [`docs/stm32_handbook.pdf`](docs/stm32_handbook.pdf).
