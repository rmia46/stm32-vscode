#!/usr/bin/env bash
set -e

# Target directory: either pass a project folder as argument, or use the current directory
TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR/build/Debug" ]; then
    echo "Error: Cannot find build/Debug in '$TARGET_DIR'."
    echo "Usage: ./flash.sh [path/to/project]"
    echo "   Or: cd into your project folder and run /home/roman/RLab/STM/flash.sh"
    exit 1
fi

echo "==> Building project in '$TARGET_DIR'..."
ninja -C "$TARGET_DIR/build/Debug"

# Find the generated .elf binary
ELF_FILE=$(find "$TARGET_DIR/build/Debug" -maxdepth 1 -name "*.elf" | head -n 1)

if [ -z "$ELF_FILE" ]; then
    echo "Error: No .elf file found in '$TARGET_DIR/build/Debug'."
    exit 1
fi

echo "==> Flashing $(basename "$ELF_FILE") to STM32..."
openocd -f interface/stlink.cfg -c "reset_config none" -f target/stm32f1x.cfg -c "init; halt; program $ELF_FILE verify reset exit"

echo "==> Done!"
