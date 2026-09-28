#!/bin/bash
# Create boot.img from kernel Image
# Usage: mkbootimg.sh <image_path> <output_path> [kernel_version] [device_model]

set -e

IMAGE_PATH="${1:-}"
OUTPUT_PATH="${2:-boot.img}"
KERNEL_VER="${3:-5.15}"
DEVICE_MODEL="${4:-generic}"

if [ ! -f "$IMAGE_PATH" ]; then
    echo "ERROR: Image file not found: $IMAGE_PATH"
    exit 1
fi

# Install mkbootimg if not available
if ! command -v mkbootimg &>/dev/null; then
    echo "Installing android-tools-mkbootimg..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq android-tools-mkbootimg
fi

# Kernel-version-specific parameters
case "$KERNEL_VER" in
    5.10)
        PAGESIZE=4096
        BASE=0x80000000
        KERNEL_OFFSET=0x8000
        RAMDISK_OFFSET=0x1000000
        TAGS_OFFSET=0x100
        ;;
    5.15)
        PAGESIZE=4096
        BASE=0x80000000
        KERNEL_OFFSET=0x8000
        RAMDISK_OFFSET=0x1000000
        TAGS_OFFSET=0x100
        ;;
    6.1|6.6|6.12)
        PAGESIZE=4096
        BASE=0x80000000
        KERNEL_OFFSET=0x8000
        RAMDISK_OFFSET=0x1000000
        TAGS_OFFSET=0x100
        ;;
    *)
        # Safe defaults for any kernel version
        PAGESIZE=4096
        BASE=0x80000000
        KERNEL_OFFSET=0x8000
        RAMDISK_OFFSET=0x1000000
        TAGS_OFFSET=0x100
        ;;
esac

echo "Building boot.img..."
echo "  Kernel: $IMAGE_PATH ($(du -h "$IMAGE_PATH" | cut -f1))"
echo "  Output: $OUTPUT_PATH"
echo "  Kernel Version: $KERNEL_VER"
echo "  Device: $DEVICE_MODEL"
echo "  Pagesize: $PAGESIZE"
echo "  Base: 0x$(printf '%x' $BASE)"

# Create minimal ramdisk if none exists
RAMDISK="/tmp/minimal-ramdisk.cpio.gz"
if [ ! -f "$RAMDISK" ]; then
    mkdir -p /tmp/ramdisk_tmp
    cd /tmp/ramdisk_tmp
    mkdir -p bin sbin dev proc sys
    echo '#!/bin/sh' > init
    echo 'mount -t proc /proc /proc' >> init
    echo 'mount -t sysfs /sys /sys' >> init
    chmod +x init
    find . -print0 | cpio --null -ov -F "$RAMDISK" 2>/dev/null
    cd - >/dev/null
    rm -rf /tmp/ramdisk_tmp
fi

# Build boot.img
mkbootimg \
    --kernel "$IMAGE_PATH" \
    --ramdisk "$RAMDISK" \
    --pagesize "$PAGESIZE" \
    --base "$BASE" \
    --kernel_offset "$KERNEL_OFFSET" \
    --ramdisk_offset "$RAMDISK_OFFSET" \
    --tags_offset "$TAGS_OFFSET" \
    --cmdline "androidboot.hardware=qcom" \
    -o "$OUTPUT_PATH"

if [ -f "$OUTPUT_PATH" ]; then
    SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
    echo "✓ boot.img created successfully: $SIZE"
    ls -lh "$OUTPUT_PATH"
    exit 0
else
    echo "ERROR: Failed to create boot.img"
    exit 1
fi
