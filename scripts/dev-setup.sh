#!/bin/bash
#
# scripts/dev-setup.sh — set up development environment
#
# Installs dependencies needed to test NexoraDE Python scripts on the host
# (without building the ISO).
#
set -euo pipefail

if command -v apt >/dev/null; then
  echo "==> Installing Debian/Ubuntu packages..."
  sudo apt update
  sudo apt install -y \
    python3 python3-gi python3-psutil python3-requests python3-yaml \
    python3-dbus python3-pil python3-pillow \
    gir1.2-gtk-3.0 gir1.2-appindicator3-0.1 \
    openbox lightdm lightdm-gtk-greeter \
    pcmanfm lxterminal feh picom arandr volumeicon-alsa network-manager-gnome \
    papirus-icon-theme xorg dbus pipewire pipewire-pulse wireplumber \
    network-manager
elif command -v pacman >/dev/null; then
  echo "==> Installing Arch packages..."
  sudo pacman -S --needed \
    python python-gobject gtk3 python-psutil python-requests python-yaml \
    python-pillow python-dbus openbox lightdm lightdm-gtk-greeter \
    pcmanfm lxterminal feh picom arandr volumeicon nm-applet \
    papirus-icon-theme xorg-server dbus pipewire pipewire-pulse wireplumber \
    networkmanager
else
  echo "Unsupported distro. Install Python 3.10+, GTK3, Openbox, LightDM manually."
fi

echo "==> Testing Python imports..."
python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk; print('GTK3 OK')"
python3 -c "import psutil; print('psutil OK')"

echo "==> Dev setup complete. Test the panel with:"
echo "    ./nexora-de/bin/nexora-panel"
echo "    ./nexora-de/bin/nexora-launcher"
