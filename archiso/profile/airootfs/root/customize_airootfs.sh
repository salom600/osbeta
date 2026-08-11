#!/bin/bash
#
# NexoraOS — customize_airootfs.sh
# Runs INSIDE the chroot during archiso build, AFTER all packages are installed.
# This is where we:
#   - enable services
#   - create the live user (nexora)
#   - install our custom desktop binaries from /usr/local/bin
#   - seed configs into /etc/skel
#   - regenerate locale
#   - install Nerd Fonts / wallpapers / theme
#   - run mkinitcpio
#
# Failure handling: every command must succeed. If something fails the build
# aborts and the CI auto-fix workflow will be triggered.

set -euo pipefail

echo "==> [customize_airootfs] NexoraOS post-install customization"

# ---- 1. Locale generation ----
echo "==> Generating locales..."
sed -i 's/^#\?\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# ---- 2. Timezone ----
echo "==> Setting timezone UTC..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# ---- 3. Live user: nexora ----
echo "==> Creating live user 'nexora'..."
if ! id nexora &>/dev/null; then
    useradd -m -G wheel,storage,power,network,video,audio,input,lp,autologin -s /bin/bash nexora
    echo 'nexora:nexora' | chpasswd
    # Passwordless sudo for the live session (installer sets real passwords later)
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/10-wheel-nopasswd
    chmod 440 /etc/sudoers.d/10-wheel-nopasswd
fi

# ---- 4. Copy skeleton into /etc/skel (used by useradd -m) ----
echo "==> Seeding /etc/skel..."
install -d /etc/skel/{.config/openbox,.config/nexora,.config/gtk-3.0,Desktop,Downloads,Documents,Pictures,Music,Videos}
cat > /etc/skel/.config/openbox/autostart <<'AUTOSTART'
# NexoraDE autostart
/usr/lib/geoclue-2.0/demos/apply-l10n.sh 2>/dev/null || true
xset -dpms s off s noblank 2>/dev/null || true
setxkbmap -option terminate:ctrl_alt_bksp 2>/dev/null || true
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
/usr/local/bin/nexora-panel &
nm-applet --no-agent &
volumeicon &
/usr/bin/xdg-user-dirs-update 2>/dev/null || true
AUTOSTART

cat > /etc/skel/.config/openbox/rc.xml <<'RCXML'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus><focusNew>yes</focusNew><followMouse>no</followMouse></focus>
  <placement><policy>Smart</policy><center>yes</center></placement>
  <theme>
    <name>Nexora-2026</name>
    <titleLayout>NLIMC</titleLayout>
    <font place="ActiveWindow"><name>Ubuntu</name><size>11</size><weight>Bold</weight></font>
    <font place="MenuHeader"><name>Ubuntu</name><size>11</size></font>
    <font place="MenuItem"><name>Ubuntu</name><size>10</size></font>
  </theme>
  <desktops><number>2</number><firstdesk>1</firstdesk><names><name>Workspace 1</name><name>Workspace 2</name></names></desktops>
  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>
    <keybind key="W-r"><action name="Execute"><command>nexora-launcher</command></action></keybind>
    <keybind key="W-Return"><action name="Execute"><command>lxterminal</command></action></keybind>
    <keybind key="W-e"><action name="Execute"><command>pcmanfm</command></action></keybind>
    <keybind key="W-s"><action name="Execute"><command>nexora-store</command></action></keybind>
    <keybind key="W-F4"><action name="Execute"><command>nexora-logout</command></action></keybind>
    <keybind key="A-F4"><action name="Close"/></keybind>
    <keybind key="A-Tab"><action name="NextWindow"/></keybind>
    <keybind key="A-S-Tab"><action name="PreviousWindow"/></keybind>
    <keybind key="W-d"><action name="ToggleShowDesktop"/></keybind>
    <keybind key="W-1"><action name="Desktop"><desktop>1</desktop></action></keybind>
    <keybind key="W-2"><action name="Desktop"><desktop>2</desktop></action></keybind>
  </keyboard>
  <mouse>
    <context name="Frame">
      <mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="A-Right" action="Drag"><action name="Resize"/></mousebind>
    </context>
  </mouse>
  <menu><file>menu.xml</file><hideDelay>200</hideDelay></menu>
  <applications/>
</openbox_config>
RCXML

cat > /etc/skel/.config/openbox/menu.xml <<'MENUXML'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="NexoraOS">
    <item label="Nexora Launcher"><action name="Execute"><command>nexora-launcher</command></action></item>
    <item label="Terminal"><action name="Execute"><command>lxterminal</command></action></item>
    <item label="Files"><action name="Execute"><command>pcmanfm</command></action></item>
    <item label="Nexora Store"><action name="Execute"><command>nexora-store</command></action></item>
    <item label="Web Browser"><action name="Execute"><command>firefox</command></action></item>
    <separator/>
    <menu id="settings" label="Settings">
      <item label="Nexora Settings"><action name="Execute"><command>nexora-settings</command></action></item>
      <item label="Appearance"><action name="Execute"><command>lxappearance</command></action></item>
      <item label="Displays"><action name="Execute"><command>arandr</command></action></item>
    </menu>
    <separator/>
    <item label="Install NexoraOS"><action name="Execute"><command>nexora-installer</command></action></item>
    <item label="Logout"><action name="Execute"><command>nexora-logout</command></action></item>
  </menu>
</openbox_menu>
MENUXML

cat > /etc/skel/.xprofile <<'XPROFILE'
export GTK_THEME=Nexora-2026:dark
export QT_QPA_PLATFORMTHEME=qt5ct
export XDG_CURRENT_DESKTOP=Nexora
export XDG_SESSION_DESKTOP=nexora
export XDG_SESSION_TYPE=x11
export SAL_USE_VCLPLUGIN=gtk3
export MOZ_ENABLE_WAYLAND=0
export _JAVA_AWT_WM_NONREPARENTING=1
XPROFILE

cat > /etc/skel/.bashrc <<'BASHRC'
# NexoraOS .bashrc
alias ls='ls --color=auto'
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias search='pacman -Ss'
alias store='nexora-store'

export PS1='\[\e[36m\]\u@\h\[\e[0m\] \[\e[34m\]\w\[\e[0m\] \$ '
export EDITOR=nano
export VISUAL=nano
export PATH="$PATH:/usr/local/bin"

# Starship prompt if available
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi
BASHRC

# Copy skeleton into nexora's home
cp -r /etc/skel/. /home/nexora/
chown -R nexora:nexora /home/nexora

# ---- 5. Nexora session Xsession file ----
echo "==> Installing Xsession..."
cat > /usr/share/xsessions/nexora.desktop <<'XSESSION'
[Desktop Entry]
Name=NexoraDE
Comment=NexoraOS Lightweight Desktop Environment
Exec=/usr/local/bin/nexora-session
TryExec=/usr/local/bin/nexora-session
Type=Application
X-LightDM-SessionName=nexora
XDG_SESSION_TYPE=x11
XDG_SESSION_DESKTOP=nexora
XDG_CURRENT_DESKTOP=Nexora
XSESSION

# ---- 6. Enable services ----
echo "==> Enabling systemd services..."
systemctl enable NetworkManager.service
systemctl enable lightdm.service
systemctl enable bluetooth.service
systemctl enable systemd-timesyncd.service
systemctl enable haveged.service
systemctl enable systemd-resolved.service
systemctl enable udisks2.service
systemctl enable polkit.service
systemctl enable cups.service 2>/dev/null || true
systemctl enable tlp.service 2>/dev/null || true
systemctl enable fstrim.timer 2>/dev/null || true
systemctl enable reflector.timer 2>/dev/null || true

# ---- 7. Mkinitcpio ----
echo "==> Configuring mkinitcpio for live ISO..."
# archiso will run mkinitcpio AFTER this script — we just set the HOOKS here.
# No `autodetect` so the initramfs boots on any hardware (live ISO use case).
cat > /etc/mkinitcpio.conf <<'MKINIT'
MODULES=(vmd nvme ahci sd_mod usb_storage sdhci sdhci_acpi ext4 btrfs vfat exfat iso9660 udf)
BINARIES=()
FILES=()
HOOKS=(base udev modconf archiso block filesystems keyboard fsck)
COMPRESSION="zstd"
COMPRESSION_OPTIONS=(-c)
MKINIT
# Ensure the mkinitcpio preset is the default Arch one
cat > /etc/mkinitcpio.d/linux.preset <<'PRESET'
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default' 'fallback')
default_image="/boot/initramfs-linux.img"
fallback_image="/boot/initramfs-linux-fallback.img"
fallback_options="-S autodetect"
PRESET

# ---- 8. Branding / OS release ----
echo "==> Writing /etc/os-release..."
cat > /etc/os-release <<'OSRELEASE'
NAME="NexoraOS"
ID=nexora
ID_LIKE=arch
VERSION="2026.1 (Vortex)"
VERSION_ID=2026.1
PRETTY_NAME="NexoraOS 2026.1 (Vortex)"
ANSI_COLOR="0;36"
HOME_URL="https://github.com/salom600/osbeta"
DOCUMENTATION_URL="https://github.com/salom600/osbeta/wiki"
SUPPORT_URL="https://github.com/salom600/osbeta/issues"
BUG_REPORT_URL="https://github.com/salom600/osbeta/issues"
LOGO=nexora
OSRELEASE

# ---- 9. LightDM autologin ----
echo "==> Enabling lightdm autologin for nexora..."
groupadd -f autologin
usermod -aG autologin nexora

# ---- 10. Set default wallpaper (procedural, no binary blob needed) ----
mkdir -p /usr/share/nexora/wallpapers
cat > /usr/share/nexora/wallpapers/make-default.sh <<'WALLSCRIPT'
#!/bin/bash
# Generate the default NexoraOS wallpaper with ImageMagick (if available)
# or fall back to a solid-color PNG written in Python.
WALL=/usr/share/nexora/wallpapers/default.png
if command -v convert &>/dev/null; then
    convert -size 1920x1080 \
        -define gradient:angle=135 \
        gradient:'#0f2027'-'#203a43'-'#2c5364' \
        -gravity south -pointsize 24 -fill white -annotate +40+30 'NexoraOS 2026' \
        "$WALL"
else
    python3 - <<PY
from PIL import Image, ImageDraw
img = Image.new('RGB', (1920, 1080), (15, 32, 39))
d = ImageDraw.Draw(img)
for y in range(1080):
    r = int(15 + (44-15) * y/1080)
    g = int(32 + (58-32) * y/1080)
    b = int(39 + (100-39) * y/1080)
    d.line([(0, y), (1920, y)], fill=(r, g, b))
img.save('$WALL')
PY
fi
WALLSCRIPT
chmod +x /usr/share/nexora/wallpapers/make-default.sh
bash /usr/share/nexora/wallpapers/make-default.sh

# ---- 11. Make Nexora scripts executable ----
chmod +x /usr/local/bin/nexora-* 2>/dev/null || true

echo "==> [customize_airootfs] Done."
