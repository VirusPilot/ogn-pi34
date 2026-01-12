#!/bin/bash
#set -x

sudo apt update
sudo apt install librtlsdr-dev librtlsdr0 rtl-sdr git cmake libfftw3-bin libusb-1.0-0-dev lynx chrony procserv telnet netcat-traditional debhelper -y
sudo apt autoremove -y

ARCH=$(getconf LONG_BIT)
DIST=$(lsb_release -r -s)

# legacy DVB-T TV drivers need to be properly blacklisted (e.g. they will activate the bias tee by default)
echo 'blacklist dvb_usb_rtl28xxu' | sudo tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

# install rtlsdr-ogn
if [ "$ARCH" -ne 64 ] || [ "$DIST" -ne 13 ]; then
  echo
  echo "wrong platform for this script, exiting"
  echo
  exit
fi
tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.3.3_Trixie.tgz
cp -f ogn-pi34/Template.conf rtlsdr-ogn/Template.conf
cd rtlsdr-ogn
# sudo chown root gsm_scan ogn-rf rtlsdr-ogn
# sudo chmod a+s gsm_scan ogn-rf rtlsdr-ogn

echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "Mandatory: enter your geographical position and APRS callsign"
echo "Optional: enter your ppm correction, GSM frequency and information about your station"
echo
read -p "Press any key to continue"
sudo nano Template.conf

wget http://download.glidernet.org/common/WW15MGH.DAC

# install rtlsdr-ogn service
sudo cp -v rtlsdr-ogn /etc/init.d/rtlsdr-ogn
sudo cp -v rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo update-rc.d rtlsdr-ogn defaults

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
