#!/bin/bash
#
# scripts/dev-setup.sh — set up development environment
#
# Installs dependencies needed to test NexoraDE Python scripts on the host.
#
set -euo pipefail

if command -v pacman >/dev/null; then
  echo "==> Installing Arch packages..."
  sudo pacman -S --needed \
    python python-gobject gtk3 python-psutil python-requests python-yaml \
    python-pillow openbox lightdm lightdm-gtk-greeter \
    pcmanfm-gtk3 lxterminal feh picom arandr volumeicon nm-applet \
    papirus-icon-theme arc-gtk-theme xorg-server xorg-xinit \
    dbus pipewire pipewire-pulse wireplumber networkmanager
elif command -v apt >/dev/null; then
  echo "==> Installing Debian packages..."
  sudo apt update
  sudo apt install -y \
    python3 python3-gi python3-psutil python3-requests python3-yaml \
    python3-pil gir1.2-gtk-3.0 openbox lightdm pcmanfm lxterminal feh \
    picom arandr volumeicon-alsa network-manager-gnome papirus-icon-theme \
    arc-theme xorg dbus pipewire pipewire-pulse wireplumber network-manager
else
  echo "Unsupported distro. Install Python 3.10+, GTK3, Openbox, LightDM manually."
fi

echo "==> Testing Python imports..."
python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk; print('GTK3 OK')"
python3 -c "import psutil; print('psutil OK')"

echo "==> Dev setup complete. Test the panel with:"
echo "    ./nexora-de/bin/nexora-panel"
echo "    ./nexora-de/bin/nexora-launcher"
