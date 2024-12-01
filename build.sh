#!/bin/bash

# Exit on error
set -e

# Variables
THREADS=$(nproc)                # Number of threads for compilation
DEVICE=whyred                   # Device codename
BUILD_TYPE=userdebug            # Build type
TARGET_PACKAGE=aosp              # OTA package prefix (e.g., `aosp_whyred`)

# Step 1: Initialize Repo in the current directory
echo "Initializing AOSP source in the current directory..."
if [ ! -d ".repo" ]; then
    repo init -u https://android.googlesource.com/platform/manifest -b main
else
    echo "Repo already initialized."
fi

# Step 2: Sync AOSP source
echo "Syncing AOSP source..."
repo sync -j$THREADS

# Step 3: Clone Device-Specific Trees (adjust URLs for whyred)
echo "Cloning device-specific repositories for whyred..."
git clone https://github.com/SuperiorOS-Devices/device_xiaomi_whyred.git device/xiaomi/whyred -b fourteen
git clone https://github.com/SuperiorOS-Devices/vendor_xiaomi_whyred.git vendor/xiaomi/whyred -b fourteen
git clone https://github.com/Pzqqt/android_kernel_xiaomi_whyred-4.19.git kernel/xiaomi/whyred -b panda

# Step 4: Set Up Build Environment
echo "Setting up build environment..."
source build/envsetup.sh

# Step 5: Lunch Command
echo "Configuring build for $DEVICE..."
lunch $TARGET_PACKAGE_$DEVICE-$BUILD_TYPE

# Step 6: Build the ROM
echo "Starting the build process..."
m -j$THREADS

# Step 7: Create OTA Package
echo "Creating OTA package..."
OUT_DIR=out/target/product/$DEVICE
OTA_PACKAGE=$OUT_DIR/$TARGET_PACKAGE-ota-$(date +%Y%m%d).zip
make otapackage -j$THREADS

# Step 8: Output OTA Package Location
if [ -f "$OUT_DIR/obj/PACKAGING/target_files_intermediates/$TARGET_PACKAGE-target_files-*.zip" ]; then
    echo "OTA package created successfully: $OTA_PACKAGE"
else
    echo "Failed to create OTA package."
    exit 1
fi
