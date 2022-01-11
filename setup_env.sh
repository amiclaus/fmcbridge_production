#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

BOARD="fmcbridge"

setup_write_autostart_config() {
	local autostart_path="$HOME/.config/autostart"

	mkdir -p $autostart_path

	local font_size="16"

	# FIXME: see about generalizing this to other desktops [Gnome, MATE, LXDE, etc]
	cat > $autostart_path/test-jig-tool.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=test-jig-tool
Comment=test-jig-tool
Exec=sudo xfce4-terminal --font="DejaVu Sans Mono $font_size" --fullscreen --hide-borders --hide-scrollbar --hide-menubar -x $SCRIPT_DIR/production_${BOARD}.sh
OnlyShowIn=XFCE;LXDE
StartupNotify=false
Terminal=false
Hidden=false
	EOF

	if type ufw &> /dev/null ; then
		sudo ufw enable
		sudo ufw allow ssh
	fi

	cat > $autostart_path/auto-save-logs.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=auto-save-logs
Comment=auto-save-logs
Exec=sudo /bin/bash $SCRIPT_DIR/autosave_logs.sh
StartupNotify=false
Terminal=false
Hidden=false
	EOF

}

setup_write_autostart_config