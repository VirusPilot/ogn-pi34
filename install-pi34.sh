#!/bin/bash
#set -x

sudo apt install git build-essential libconfig9 libfftw3-bin libtool libusb-1.0-0-dev lynx ntp ntpdate procserv telnet -y

ARCH=$(arch)
if [ $ARCH == aarch64 ]; then # arm64
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_arm64.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_arm64.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_arm64.deb
else # armhf
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr0_0.6.0-4_armhf.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/librtlsdr-dev_0.6.0-4_armhf.deb
    wget http://ftp.de.debian.org/debian/pool/main/r/rtl-sdr/rtl-sdr_0.6.0-4_armhf.deb
fi
sudo dpkg -i *.deb
rm -f *.deb
sudo ldconfig

# prevent kernel modules claiming use of the USB DVB-T dongle
echo blacklist rtl2832 | sudo tee /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist r820t | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl2830 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_v2 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl8xxxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf

# unpack version 0.2.9
ARCH=$(arch)
if [ $ARCH == aarch64 ]; then # arm64
  tar xvf ogn-pi34/rtlsdr-ogn-bin-arm64-0.2.9_BullsEye.tgz
else # armhf
  tar xvf ogn-pi34/rtlsdr-ogn-bin-ARM-0.2.9_Buster.tgz
fi

cd rtlsdr-ogn
sudo chown root gsm_scan
sudo chmod a+s gsm_scan
sudo chown root ogn-rf
sudo chmod a+s  ogn-rf
sudo chown root rtlsdr-ogn
sudo chmod a+s  rtlsdr-ogn
sudo mknod gpu_dev c 100 0

echo
echo "Please edit Template.conf, to set-up the receiver:"
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo
read -p "Press any key to continue"
sudo nano Template.conf

sudo wget http://download.glidernet.org/common/WW15MGH.DAC

# install rtlsdr-ogn to run OGN receiver as a service
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
