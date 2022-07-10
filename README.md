# ogn-pi34
Script to built an OGN station on a Pi Zero 2W, Pi3 or Pi4, based on OGN version 0.2.9 and **RasPiOS Lite** (32bit or 64bit), using latest Raspberry Pi Imager from here: https://www.raspberrypi.com/software/

## prepare script for Pi3B, Pi4B or Pi Zero 2W:
- flash latest **RasPiOS Lite Image** (32bit or 64bit), using latest Raspberry Pi Imager with the following settings:
  - select appropriate hostname
  - enable ssh
  - enable user pi with password
  - configure WiFi (particularly important for Pi Zero 2W)
- boot and wait until your Pi is connected to your LAN or WiFi

## preparation of OGN credentials
During the setup process you will be asked to edit (using nano) `Template.conf` for which you should have the following credentials at hand:
- SDR device number (to avoid conflicts if you have multiple SDRs installed); alternatively if you know already the serial number of your SDR, you can use that to automatically select the appropriate SDR
- SDR frequency correction [ppm] (this can also be measured and mofified accordingly post install if unknown)
```
RF:
{
  Device   = 0;            # Device index for OGN reception. E.g. check "sudo rtl_eeprom -d 0" or "-d 1", ...
  #DeviceSerial = "868";   # alternative
  FreqCorr = 0;            # [ppm] "big" R820T sticks have 40-80ppm correction factors, measure it with gsm_scan
};
```
- GPS coordinates and altitude for your OGN station:
```
Position:
{ 
  Latitude   =   +48.0000; # [deg] Antenna coordinates
  Longitude  =    +9.0000; # [deg]
  Altitude   =        100; # [m]   Altitude above sea leavel
};
```
- APRS name (please remove the `#` in front of `Call` and change `SampleAPRSnameToChange` to your APRS callsign):
```
APRS:
{
  Call = "SampleAPRSnameToChange";      # APRS callsign (max. 9 characters)
                                        # Please refer to http://wiki.glidernet.org/receiver-naming-convention
};
```
- in case you plan to combine the OGN station with a dump1090 feeder, the following addition is recommended:
```
HTTP:
{
  Port = 8082;
};
```
- in case you plan to feed OGN traffic to OpenSky, the following additional line in the "Demodulator" section is necessary:
```
Demodulator:
{ 
  MergeServer = "flarm-collector.opensky-network.org:20002";
};
```
- in case you want to contribute with your OGN station to the Fast Radio Bursts (FRBs) project (https://arxiv.org/abs/1701.01475), you need to add the following:
```
FRB:
{
  DetectSNR = 10.0;
  Server = "ogn3.glidernet.org:50000";
};
```

## automatic setup
- plug your SD card into the Pi, connect your Pi3 or Pi4 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- connect to your pi using ssh
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh
```
- reboot
## post install modifications
### GSM gain/frequency and ppm calibration
- see https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### OGN gain
- the SDR gain should be set such that the RF input noise is only a couple of dBs
### nightly reboot at 1 am
- execute the following: `crontab -l | { cat; echo "0 1 * * * /sbin/reboot"; } | crontab -` 
