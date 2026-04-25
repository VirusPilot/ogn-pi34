#!/bin/bash
#set -x

cd /home/pi || { echo "Error: /home/pi doesn't exist!"; exit 1; }

sudo apt update
sudo apt install librtlsdr-dev librtlsdr0 rtl-sdr git cmake libfftw3-bin libusb-1.0-0-dev lynx chrony procserv telnet netcat-traditional debhelper -y
sudo apt autoremove -y

# legacy DVB-T TV drivers need to be properly blacklisted (e.g. they will activate the bias tee by default)
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# install rtlsdr-ogn
ARCH=$(arch) # linux architecture 
DIST=$(lsb_release -r -s) # linux OS release number
case "${ARCH}_${DIST}" in
  aarch64_13)
    echo
    echo "installing OGN v0.3.3 on aarch64 Debian 13 Trixie"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.3.3.tgz
    ;;
  armv7l_13)
    echo
    echo "installing OGN v0.3.3 on armv7l Debian 13 Trixie"
    echo "press Return to continue or Ctr-C to abort"
    read -r
    tar xvf ogn-pi34/rtlsdr-ogn-bin-ARM-0.3.3.tgz
    ;;
  *)
    echo
    echo "wrong platform for this script, exiting"
    echo
    exit 1
    ;;
esac

# copy systemd files
sudo cp -v rtlsdr-ogn/rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo cp -v ogn-pi34/rtlsdr-ogn.service /etc/systemd/system/

# prepare OGN configuration file
cp -v ogn-pi34/Template.conf rtlsdr-ogn/Template.conf
echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo
read -p "Press any key to continue"
nano rtlsdr-ogn/Template.conf

# download EGM grid file
wget http://download.glidernet.org/common/WW15MGH.DAC -O rtlsdr-ogn/WW15MGH.DAC

# enable and start rtlsdr-ogn service
sudo systemctl daemon-reload
sudo systemctl enable rtlsdr-ogn
sudo systemctl start rtlsdr-ogn

echo
read -t 1 -n 10000 discard  # Clear input buffer
read -p "Installation complete. Reboot now? [y/n]: " -n 1 -r
echo    # New line after input
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sleep 2
    sudo reboot
else
    echo "Reboot skipped. Run 'sudo reboot' manually when ready."
fi
