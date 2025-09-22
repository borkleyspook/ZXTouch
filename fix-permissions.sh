#!/bin/sh

# Detect rootless environment
if [ -d "/private/preboot" ] && [ -n "$(find /private/preboot -name procursus -type d 2>/dev/null)" ]; then
    # Dopamine-style rootless
    PATH_PREFIX="$(find /private/preboot -name procursus -type d 2>/dev/null | head -1)"
    TYPE_PREFIX="Dopamine-style rootless"
    echo "Dopamine-style rootless environment detected"
elif [ -d "/var/jb" ]; then
    # Simple rootless (palera1n, etc)
    PATH_PREFIX="/var/jb"
    TYPE_PREFIX="simple rootless (palera1n, etc)"
    echo "Simple rootless (palera1n, etc) environment detected"
else
    # Rootful
    PATH_PREFIX=""
    TYPE_PREFIX="rootfull"
    echo "Traditional rootful environment"
fi

# Use dynamic paths
ZXTOUCH_PATH="${PATH_PREFIX}/var/mobile/Library/ZXTouch"
echo "Using ZXTouch path: $ZXTOUCH_PATH"

# Handle ZXTouch directory
echo "Fixing permissions for: $ZXTOUCH_PATH"

if [ -d "$ZXTOUCH_PATH" ]; then
    chown -R mobile:mobile "$ZXTOUCH_PATH"
    chmod -R 755 "$ZXTOUCH_PATH"
    echo "✅ Permissions fixed"
else
    echo "❌ ZXTouch directory not found: $ZXTOUCH_PATH"
    exit 1
fi

# Restart SpringBoard
killall -9 SpringBoard 2>/dev/null || true