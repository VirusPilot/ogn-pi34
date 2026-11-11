## script to build a receiver station to feed the Open Glider Network:
- install script usage:
  - `install-pi34.sh ogn` installing only OGN feed
  - `install-pi34.sh dump1090` installing OGN/ADSB feed (including dump1090)
  - `install-pi34.sh ogn2readsb` installing OGN/ADSB feed  (including readsb and unified local tar1090 traffic map)
## docker versions are available for option 1 and 3, support for both arm64 and x64 platforms
- https://github.com/VirusPilot/docker-ogn (equivalent to the OGN-only install option)
- https://github.com/VirusPilot/docker-ogn2readsb (equivalent to the ogn2readsb install option)
## supported platforms and OS by these scripts (using rtlsdr-ogn-bin-arm64-0.3.3.tgz):
- armhf/arm64 (32/64-bit ARM CPUs with hardware floating point processor), Debian 13 Trixie (includes native RTL-SDR Blog v4 support)
## supported platform for manual install (using rtlsdr-ogn-bin-x64-0.3.3.tgz):
- x64 (64-bit AMD/Intel CPUs)
- several config files need to be modified, therefore only intended for experts
## three install options
- `install-pi34.sh ogn` installs OGN only
- `install-pi34.sh dump1090`
  - requires a **second SDR**
  - installs https://github.com/VirusPilot/dump1090 in addition to feed Open Glider Network with ADS-B
  - ADS-B SDR adaptive gain and adaptive burst mode enabled (to prefer local traffic)
- `install-pi34.sh ogn2readsb`
  - requires a **second SDR**
  - installs https://github.com/wiedehopf/readsb
  - installs https://github.com/b3nn0/ogn2dump1090
  - feeds Open Glider Network with ADS-B
  - inject Open Glider Network Traffic for display on a unified local tar1090 traffic map
## notes
- Pi Zero 2W, Pi3, Pi4 or Pi5 are supported
- Raspberry Pi Imager (https://www.raspberrypi.com/software/) is recommended
- latest 0.3.3 version enables **SDR autogain** to avoid crossmodulation
- latest 0.3.3 version supports the following protocols:
  - ADS-B (requires `dump1090` or `readsb`runing on the same receiver but on a **second SDR**)
  - FLARM [GFSK 868.2/868.4MHz]
  - OGN [GFSK 868.4/868.2MHz]
  - M-Band ADS-L [GFSK 868.2/868.4MHz]
  - LDR ADS-L [GFSK 869.525MHz]
  - HDR ADS-L [GFSK 869.525MHz]
  - FANET [LoRa 868.2MHz]
  - PilotAware [GFSK 869.525MHz]
  - ...
## prepare script for Pi3, Pi4, Pi5 or Pi Zero 2W:
- flash **latest RasPiOS Lite Image** (32bit or 64bit), using latest [Raspberry Pi Imager](https://www.raspberrypi.com/software/) with the following settings:
  - select appropriate hostname
  - enable ssh
  - enable user pi with password (<ins>all these scripts need to run as user "pi" but they also require sudo privileges; when your user "pi" was the first created user on a Raspberry Pi, it will have passwordless sudo privileges</ins>)
  - configure WiFi (particularly important for Pi Zero 2W)
- boot and wait until your Pi is connected to your LAN or WiFi
- connect to your pi with ssh
- **all scripts need to be exectuted from the /home/pi directory**

## preparation of credentials
During the setup process you will be automatically asked to edit `Template.conf` and potentially `dump1090` or `readsb` for which you should have the following credentials at hand:
- SDR index numbers or SDR serial numbers (SN) for both the OGN and ADS-B SDRs
- SDR ppm calibration (only required for non-TCXO SDRs), this can also be measured and modified accordingly post install if unknown
- OGN station name, e.g. your local airport ICAO code (max. 9 characters), please refer to http://wiki.glidernet.org/receiver-naming-convention
- station coordinates and altitude for both the OGN and ADS-B configuration files

SDR selection and ppm correction:
```
RF:
{
  Async = 1;               # = 0, frequency calibration based on GSM signals
                           # = 1, (default) causes the RF to read data continously without any gaps, required for Time-of-Arrival service
                           # = 2, same as Async = 1 but latency is further reduced by 50%
  Device   = 0;            # device selection based on SDR index number, please doublecheck post-install using "rtl_test"
  #DeviceSerial = "868";   # alternative device selection based on SDR serial number (SN), please doublecheck post-install using "rtl_test"
  FreqCorr = 0;            # [ppm] SDR correction factor, newer sticks have a TCXO so no correction required
  SampleRate = 2.0;        # [MHz] 1.0 or 2.0MHz, 2MHz is required to captue PilotAware
  BiasTee  = 0;            # BiasTee is disabled by default, only enable it if you are sure about your setup,
                           # e.g. your SDR is NOT directly connected to a DC short circuited antenna unless you are using an LNA
};
```
In case your OGN station is in an area with no GSM stations then the automatic gsm_scan should be deactivated by changing to `GSM.CenterFreq=0` (as an alternative you can ommit the entire GSM section for SDRs with TCXO):
```
GSM:                  # for frequency calibration based on GSM signals
{                     # you can ommit the whole GSM section for sticks with TCXO
  CenterFreq  =    0; # [MHz] you may enter the GSM frequency that you found with gsm_scan but ONLY if you have GSM stations nearby
  Gain        = 25.0; # [dB]  RF input gain (beware that GSM signals are very strong)
};
```
GPS coordinates and altitude for your OGN station:
```
Position:
{ 
  Latitude   =   +48.0000; # [deg] please put in the appropriate latitude for your OGN station antenna
  Longitude  =   +10.0000; # [deg] please put in the appropriate longitude for your OGN station antenna
  Altitude   =        500; # [m]   altitude AMSL, please put in the appropriate altitude for your OGN station antenna
};
```
Required configuration for feeding Open Glider Network with ADS-B traffic:
```
ADSB:                      # feeding Open Glider Network with ADS-B traffic
{
  AVR = "localhost:30002"; # disable this line if you DO NOT WANT to feed Open Glider Network with ADS-B traffic
  MaxAlt = 18000;          # [ft] default maximum altitude, feel free to increase but this will potentially increase your internet traffic
};
```
Replace <NewOGNrx> with your actual APRS callsign, please refer to http://wiki.glidernet.org/receiver-naming-convention:
```
APRS:
{
  #Call = "NewOGNrx";          # enable this line and replace <NewOGNrx> with your actual APRS callsign, e.g. your local airport ICAO code (max. 9 characters)
                               # please refer to http://wiki.glidernet.org/receiver-naming-convention
};
```
In case you plan to combine the OGN station with a dump1090 feeder (like in the alternative install script below), the following section is required:
```
HTTP:           # this section is required to be able to monitor the different status pages of your receiver
{               # e.g. http://raspberrypi:8080 for monitoring dump1090 ADS-B traffic
  Port = 8082;  # e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
};              # e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
```

## setup
- plug your SD card into the Pi, connect your Pi3, Pi4 or Pi5 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- connect to your pi using ssh
### option 1
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh ogn
```
crosscheck (after the reboot):
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
### option 2: adding dump1090
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh dump1090
```
crosscheck:
- e.g. http://raspberrypi:8080 for monitoring ADS-B traffic
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
### option 3: adding readsb and ogn2dump1090 (aka. ogn2readsb)
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh ogn2readsb
```
crosscheck (after the reboot):
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
- e.g. http://raspberrypi/tar1090 for monitoring OGN and ADS-B traffic on the unified tar1090 traffic map

## post install modifications
- please note that an accurate Raspberry Pi system time is required for a proper decoding of traffic, e.g. synchronized via systemd-timesyncd (default) or chrony
### remove Raspberry Pi USB power supply limitation
- it might be necessary to remove the Raspberry Pi5 USB power supply limitation by adding `usb_max_current_enable=1` to `/boot/config.txt` (`/boot/firmware/config.txt` in case of Bookworm or Trixie)
### SDR ppm correction (mandatory for non-TCXO SDRs)
- https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### SDR ppm automatic fine calibration (+/- 10.0 ppm)
- the following steps are required:
  - `sudo service rtlsdr-ogn stop` (on a running OGN receiver station)
  - `cd rtlsdr-ogn`
  - `./gsm_scan --device 0 --gain 25` (in case OGN is using SDR #0)
  - `./gsm_scan --serial 868 --gain 25` (in case OGN is using the SDR with serial #868)
  - identify the GSM frequency with the highest level (e.g. +20.0dB)
  - you may have to adjust the gain value such that this highest level clearly sticks out of all other levels
  - enter this frequency (e.g. 935.8) to `CenterFreq` in the GSM section of `Template.conf`
  - enter the final gain value to `Gain` in the GSM section of `Template.conf`
  - if nothing can be measured at all you may not have a GSM station nearby (in USA/Canada you need to add `--gsm-850`)
  - `sudo service rtlsdr-ogn start`
  - monitor the ogn-rf page on port 8082 how `Fine calib. FreqCorr` automatically adjusts over time
  - if the `Fine calib. FreqCorr` value increases to a very high value (more than +/- 10.0 ppm) then your SDR may not have a TCXO; in such case you should change the `FreqCorr` value in the RF section of `Template.conf` according to the prior section, followed by a `sudo service rtlsdr-ogn restart`
### optional: nightly reboot at 1 am
- execute the following: `sudo crontab -e` then add `0 1 * * * /sbin/reboot` and save
### optional: daily update of OGN database at 2 am
- execute the following: `sudo crontab -e` then add `0 2 * * * /usr/bin/wget -O /home/pi/ogn2dump1090/ddb.json http://ddb.glidernet.org/download/?j=1 && sudo service ogn2dump1090 restart` and save
### optional: automatic reboot after losing network connection (e.g router IP 192.168.1.1)
- the following steps are required:
  - `sudo apt update`
  - `sudo apt install watchdog`
  - `sudo nano /etc/watchdog.conf` and add the following lines:
    - `ping       = 192.168.1.1`
    - `ping-count = 5`
  - `sudo systemctl enable watchdog`
  - `sudo systemctl start watchdog`
  - `journalctl --list-boots` lists all reboots
### optional: enable read-only file system
- `sudo raspi-config`
- -> 4 Performance Options / P2 Overlay File System -> yes (not required for the boot partition)
