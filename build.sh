#!/bin/bash
set -e

echo "=== Building BioLock (rootless) ==="

# Source theos environment
export THEOS="$HOME/theos"
export PATH="$THEOS/bin:$PATH"

# Clean previous builds
make clean 2>/dev/null || true

# Build for rootless (Dopamine)
echo "Compiling..."
make package THEOS_PACKAGE_SCHEME=rootless

echo ""
echo "=== Build Complete ==="
echo "Package location:"
ls -la packages/*.deb 2>/dev/null || echo "No .deb found"
echo ""
echo "To install on device:"
echo " 1. Copy the .deb file to your device (via AirDrop, scp, etc.)"
echo " 2. Open Sileo > Files > navigate to the .deb"
echo " 3. Tap Install"
echo " 4. Respring"
