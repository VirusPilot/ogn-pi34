#!/bin/bash
#set -x

sudo timedatectl set-timezone Europe/Berlin

sudo apt install build-essential cmake libconfig9 libfftw3-bin libjpeg62-turbo-dev libtool libusb-1.0-0-dev lynx ntp ntpdate procserv telnet -y

# install librtlsdr
cd
rm -rf rtl-sdr
git clone https://github.com/osmocom/rtl-sdr.git
cd rtl-sdr
mkdir build
cd build
cmake ../ -DENABLE_ZEROCOPY=0
make
sudo make install
sudo ldconfig
cd
rm -rf rtl-sdr

# prevent kernel modules claiming use of the USB DVB-T dongle
echo blacklist rtl2832 | sudo tee /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist r820t | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl2830 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf

# download and unpack version 0.2.8
if grep -q "Pi 4" /proc/device-tree/model; then
  wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-latest.tgz
else
  wget http://download.glidernet.org/rpi-gpu/rtlsdr-ogn-bin-RPI-GPU-latest.tgz
fi
tar xzf rtlsdr-ogn-bin-*.tgz
rm rtlsdr-ogn-bin-*.tgz

cd rtlsdr-ogn
sudo chown root gsm_scan
sudo chmod a+s gsm_scan
sudo chown root ogn-rf
sudo chmod a+s  ogn-rf
sudo chown root rtlsdr-ogn
sudo chmod a+s  rtlsdr-ogn
sudo mknod gpu_dev c 100 0

cp -f Template.conf myPlace.conf
echo
echo "Please edit myPlace.conf, to set-up the receiver:"
echo "enter your ppm correction, GSM frequency for calibration, geographical position and APRS name"
echo
read -p "Press any key to continue"
sudo nano myPlace.conf

#sudo wget --no-check-certificate https://download.osgeo.org/proj/vdatum/egm96_15/outdated/WW15MGH.DAC
sudo wget http://download.glidernet.org/common/WW15MGH.DAC

# install rtlsdr-ogn to run OGN receiver as a service
sudo cp -v rtlsdr-ogn /etc/init.d/rtlsdr-ogn
sudo cp -v rtlsdr-ogn.conf /etc/rtlsdr-ogn.conf
sudo update-rc.d rtlsdr-ogn defaults

echo
echo "Please Update /etc/rtlsdr-ogn.conf according to name of your configuration file by replacing"
echo "SampleConfigurationFileNameToChange.conf by the name of your config file (e.g. myPlace.conf)"
echo
read -p "Press any key to continue"
sudo nano /etc/rtlsdr-ogn.conf

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]"
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
