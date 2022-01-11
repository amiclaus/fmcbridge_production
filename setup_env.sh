#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

BOARD="fmcbridge"

setup_apt_install_prereqs() {
	type apt-get &> /dev/null || {
		echo "No 'apt-get' found; cannot install dependencies"
		return 0
	}
	sudo_required
	sudo -s <<-EOF
	apt-get -y update
	apt-get -y install bc sshpass libfftw3-dev librsvg2-dev libgtk-3-dev \
		cmake build-essential git libxml2 libxml2-dev bison flex \
		expect usbutils dfu-util screen libaio-dev libglib2.0-dev picocom \
		wget unzip curl cups cups-bsd intltool itstool libxml2-utils \
		libusb-dev libusb-1.0-0-dev htpdate xfce4-terminal libiec16022-dev \
		openssh-server gpg dnsmasq libcurl4-gnutls-dev libqrencode-dev pv \
		python3-pytest python3-libiio python3-scapy python3-scipy
	/etc/init.d/htpdate restart
	EOF
}

setup_write_autostart_config() {
	local autostart_path="$HOME/.config/autostart"
	local configs_disable="blueman light-locker polkit-gnome-authentication-agent-1"

	configs_disable="$configs_disable print-applet pulseaudio snap-userd-autostart"
	configs_disable="$configs_disable spice-vdagent update-notifier user-dirs-update-gtk xdg-user-dirs"

	mkdir -p $autostart_path

	for cfg in $configs_disable ; do
		cat > $autostart_path/$cfg.desktop <<-EOF
[Desktop Entry]
Hidden=true
		EOF
	done

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

setup_apt_install_prereqs

setup_write_autostart_config
