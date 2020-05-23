#!/bin/bash
#set -x

sudo apt install librtlsdr0 -y
sudo apt install librtlsdr-dev -y
sudo apt install rtl-sdr -y
sudo apt install libconfig9 -y
sudo apt install libjpeg8 -y
sudo apt install lynx -y
sudo apt install ntpdate -y
sudo apt install ntp -y
sudo apt install procserv -y
sudo apt install telnet -y

wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-bin_3.3.5-3_armhf.deb
wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-dev_3.3.5-3_armhf.deb
wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-double3_3.3.5-3_armhf.deb
wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-single3_3.3.5-3_armhf.deb
sudo dpkg -i libfftw*.deb
rm libfftw*.deb
sudo apt-mark hold libfftw3-bin
sudo apt-mark hold libfftw3-dev
sudo apt-mark hold libfftw3-double3
sudo apt-mark hold libfftw3-single3

echo blacklist rtl2832 | sudo tee /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist r820t | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl2830 | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | sudo tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf

wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-latest.tgz
tar xvzf rtlsdr-ogn-bin-ARM-latest.tgz
rm *.tgz
cd rtlsdr-ogn
mkfifo ogn-rf.fifo
sudo chown root gsm_scan
sudo chmod a+s gsm_scan
sudo chown root ogn-rf
sudo chmod a+s  ogn-rf

cp -f Template.conf myPlace.conf
# - edit myPlace.conf, to set-up the receiver:
# - enter your crystal correction
# - GSM frequency for calibration, geographical position, APRS name
sudo nano myPlace.conf

sudo wget --no-check-certificate http://earth-info.nga.mil/GandG/wgs84/gravitymod/egm96/binary/WW15MGH.DAC

sudo wget http://download.glidernet.org/common/service/rtlsdr-ogn -O /etc/init.d/rtlsdr-ogn
sudo wget http://download.glidernet.org/common/service/rtlsdr-ogn.conf -O /etc/rtlsdr-ogn.conf
sudo chmod +x /etc/init.d/rtlsdr-ogn
sudo update-rc.d rtlsdr-ogn defaults

# Update /etc/rtlsdr-ogn.conf according to name of your configuration file
# by replacing SampleConfigurationFileNameToChange.conf by the name of your config file (e.g. myPlace.conf)
# and pi with your actual username
sudo nano /etc/rtlsdr-ogn.conf

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]"
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  sudo reboot
fi
