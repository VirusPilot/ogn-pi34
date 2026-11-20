# script to build a receiver station to feed the Open Glider Network using beta ogn libs
## 2026-11-20 Update
- install option 4 added which uses the Eurocontrol ASTERIX CAT021 protocol to convert and display OGN traffic on the readsb/tar1090 traffic map
- the SBS Station protocol used in option 3 has quite some limitations, e.g. no field element for WGS-84 geometric altitude, therefore option 4 is recommended, option 3 still maintained
- option 4 further includes traffic patterns for Germany and Austria ("UK Radar Corridors" needs to be selected in `tar1090` settings)
- WIP for option 4:
  - droneaware traffic support and mapping
  - docker version
  - move traffic pattern selection option to `tar1090` custom map settings
## 2026-11-09 Update
- consolidate all scripts into one, script now needs to be executed with an argument for option selection
## 2026-11-04 Update
- new version of rtlsdr-ogn-bin-arm64-0.3.3.tgz (64-bit), now includes some nice sensitivity plots on port 8083
## install options
1. `install-pi34.sh ogn`
  - installs OGN only
2. `install-pi34.sh dump1090`
  - requires a **second SDR**
  - installs https://github.com/VirusPilot/dump1090 in addition to feeding the Open Glider Network with ADS-B
  - ADS-B SDR adaptive gain and adaptive burst mode enabled (to prefer local traffic)
3. `install-pi34.sh ogn-sbs-readsb`
  - requires a **second SDR**
  - installs https://github.com/wiedehopf/readsb
  - installs https://github.com/b3nn0/ogn2dump1090
  - feeds Open Glider Network with ADS-B
  - injects Open Glider Network Traffic for display on a unified local tar1090 traffic map using the **SBS Station protocol**
4. `install-pi34.sh ogn-asterix-readsb`
  - requires a **second SDR**
  - installs https://github.com/wiedehopf/readsb
  - installs https://github.com/VirusPilot/ogn-asterix-bridge
  - feeds Open Glider Network with ADS-B
  - injects Open Glider Network Traffic for display on a unified local tar1090 traffic map using the Eurocontrol **ASTERIX CAT021 protocol**
## notes
- Pi Zero 2W, Pi3, Pi4 or Pi5 are supported
- Raspberry Pi Imager (https://www.raspberrypi.com/software/) is recommended
- latest 0.3.3 version enables **SDR autogain** to avoid crossmodulation
- latest 0.3.3 version supports the following protocols:
  - ADS-B (requires `dump1090` or `readsb` running on the same receiver but on a **second SDR**)
  - FLARM [GFSK 868.2/868.4MHz]
  - OGN [GFSK 868.4/868.2MHz]
  - M-Band ADS-L [GFSK 868.2/868.4MHz]
  - LDR ADS-L [GFSK 869.525MHz]
  - HDR ADS-L [GFSK 869.525MHz]
  - FANET [LoRa 868.2MHz]
  - PilotAware [GFSK 869.525MHz]
  - DVS (weather provided by Davis meteo stations)
  - Meshtastic
  - ...
- supported platforms and OS by these scripts (using rtlsdr-ogn-bin-arm64-0.3.3.tgz):
  - armhf/arm64 (32/64-bit ARM CPUs with hardware floating point processor), Debian 13 Trixie (includes native RTL-SDR Blog v4 support)
- supported platform for manual install (using rtlsdr-ogn-bin-x64-0.3.3.tgz):
  - x64 (64-bit AMD/Intel CPUs)
  - several config files need to be modified, therefore only intended for experts
- docker versions are available for option 1 and 3, support for both arm64 and x64 platforms
  - https://github.com/VirusPilot/docker-ogn (equivalent to install option 1)
  - https://github.com/VirusPilot/docker-ogn2readsb (equivalent to install option 3)
## prepare scripts for Pi3, Pi4, Pi5 or Pi Zero 2W:
- flash the **latest Raspberry Pi OS Lite image** (32-bit or 64-bit), using the latest [Raspberry Pi Imager](https://www.raspberrypi.com/software/) with the following settings:
  - select appropriate Raspberry Pi hostname
  - enable ssh
  - enable user pi with password (all these scripts need to run as user "pi" but they also require sudo privileges; when your user "pi" was the first created user on a Raspberry Pi, it will have passwordless sudo privileges)
  - configure WiFi (particularly important for Pi Zero 2W)
- boot and wait until your Pi is connected to your LAN or WiFi
- connect to your pi with ssh
- **all scripts need to be executed from the /home/pi directory**
- before executing the script, make sure you have all credentials available

## preparation of credentials
During the setup process you will be automatically asked to edit `Template.conf` and potentially `dump1090` or `readsb` for which you should have the following credentials at hand:
- SDR index numbers or SDR serial numbers (SN) for both the OGN and ADS-B SDRs
- SDR ppm calibration (only required for non-TCXO SDRs), this can also be measured and modified accordingly post install if unknown
- OGN station name, e.g. your local airport ICAO code (max. 9 characters), please refer to http://wiki.glidernet.org/receiver-naming-convention
- station coordinates and altitude for both the OGN and ADS-B configuration files

### OGN `Template.conf` edits
SDR selection and ppm correction:
```
RF:
{
  Async = 2;               # = 0, frequency calibration based on GSM signals
                           # = 1, causes the RF to read data continuously without any gaps, required for Time-of-Arrival service
                           # = 2, (default) same as Async = 1 but latency is further reduced by 50%
  Device   = 0;            # device selection based on SDR index number, please double-check post-install using "rtl_test"
  #DeviceSerial = "868";   # alternative device selection based on SDR serial number (SN), please double-check post-install using "rtl_test"
  FreqCorr = 0;            # [ppm] SDR correction factor, newer sticks have a TCXO so no correction required
  SampleRate = 2.0;        # [MHz] 1.0 or 2.0MHz, 2MHz is required to capture PilotAware
  BiasTee  = 0;            # BiasTee is disabled by default, only enable it if you are sure about your setup,
                           # e.g. your SDR is NOT directly connected to a DC short-circuited antenna unless you are using an LNA
};
```
In case your OGN station is in an area with no GSM stations then the automatic gsm_scan should be deactivated by changing to `GSM.CenterFreq=0` (as an alternative you can omit the entire GSM section for SDRs with TCXO):
```
GSM:                  # for frequency calibration based on GSM signals
{                     # you can omit the whole GSM section for sticks with TCXO
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
Replace <NewOGNrx> with your actual APRS callsign and remove the leading "#", please refer to http://wiki.glidernet.org/receiver-naming-convention:
```
APRS:
{
  #Call = "NewOGNrx";          # enable this line and replace <NewOGNrx> with your actual APRS callsign, e.g. your local airport ICAO code (max. 9 characters)
                               # please refer to http://wiki.glidernet.org/receiver-naming-convention
};
```
In case you plan to combine the OGN station with an ADS-B feeder (options 2,3,4), the following section is required:
```
HTTP:           # this section is required to be able to monitor the different status pages of your receiver
{               # e.g. http://raspberrypi:8080 for monitoring dump1090 ADS-B traffic
  Port = 8082;  # e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
};              # e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
```

## execute the script
### option 1: ogn only
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh ogn
```
cross-check (after the reboot):
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
### option 2: ogn + dump1090
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh dump1090
```
cross-check:
- e.g. http://raspberrypi:8080 for monitoring ADS-B traffic
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
### option 3: ogn + readsb + ogn2dump1090
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh ogn-sbs-readsb
```
cross-check (after the reboot):
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
- e.g. http://raspberrypi/tar1090 for monitoring OGN and ADS-B traffic on the unified tar1090 traffic map
### option 4: ogn + readsb + ogn-asterix-bridge
```
sudo apt update
sudo apt full-upgrade -y
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh ogn-asterix-readsb
```
cross-check (after the reboot):
- e.g. http://raspberrypi:8082 for monitoring the RTLSDR OGN RF processor status page
- e.g. http://raspberrypi:8083 for monitoring the RTLSDR OGN demodulator and decoder status page
- e.g. http://raspberrypi/tar1090 for monitoring OGN and ADS-B traffic on the unified tar1090 traffic map

## post install modifications
### remove Raspberry Pi USB power supply limitation
- it might be necessary to remove the Raspberry Pi5 USB power supply limitation by adding `usb_max_current_enable=1` to `/boot/firmware/config.txt`
### SDR ppm correction (mandatory for non-TCXO SDRs)
- https://gist.github.com/VirusPilot/e5c56df879320bd995f77afdd86b05ac
### optional: nightly reboot at 1 am
- execute the following: `sudo crontab -e` then add `0 1 * * * /sbin/reboot` and save
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
