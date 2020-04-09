#!/bin/bash
#set -x

apt update
apt full-upgrade -y
apt install rtl-sdr -y
apt install libconfig9 -y
apt install libjpeg8 -y
apt install lynx -y
apt install ntpdate -y
apt install ntp -y
apt install procserv -y
apt install telnet -y

wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-bin_3.3.5-3_armhf.deb
wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-dev_3.3.5-3_armhf.deb
wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-double3_3.3.5-3_armhf.deb
wget http://ftp.debian.org/debian/pool/main/f/fftw3/libfftw3-single3_3.3.5-3_armhf.deb
dpkg -i libfftw*.deb
rm libfftw*.deb
apt-mark hold libfftw3-bin
apt-mark hold libfftw3-dev
apt-mark hold libfftw3-double3
apt-mark hold libfftw3-single3

echo blacklist rtl2832 | tee /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist r820t | tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist rtl2830 | tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf
echo blacklist dvb_usb_rtl28xxu | tee -a /etc/modprobe.d/rtl-glidernet-blacklist.conf

wget http://download.glidernet.org/arm/rtlsdr-ogn-bin-ARM-latest.tgz
tar xvzf rtlsdr-ogn-bin-ARM-latest.tgz
rm
cd rtlsdr-ogn
mkfifo ogn-rf.fifo
chown root gsm_scan
chmod a+s gsm_scan
chown root ogn-rf
chmod a+s  ogn-rf

cp Template.conf myPlace.conf
# Then edit the file, to set-up the receiver:
# - enter your crystal correction
# - GSM frequency for calibration, geographical position, APRS name
nano myPlace.conf

wget http://download.glidernet.org/common/service/rtlsdr-ogn -O /etc/init.d/rtlsdr-ogn
wget http://download.glidernet.org/common/service/rtlsdr-ogn.conf -O /etc/rtlsdr-ogn.conf
chmod +x /etc/init.d/rtlsdr-ogn
update-rc.d rtlsdr-ogn defaults

# Update /etc/rtlsdr-ogn.conf according to name of your configuration file
# by replacing SampleConfigurationFileNameToChange.conf by the name of your config file (e.g. myPlace.conf)
# and pi with your actual username
nano /etc/rtlsdr-ogn.conf

service rtlsdr-ogn start

echo
read -t 1 -n 10000 discard
read -p "Reboot now? [y/n]"
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  reboot
fi
