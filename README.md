# ogn-pi34
scripts to built an OGN station on a Pi Zero 2W, Pi3 or Pi4, based on OGN version 0.2.9 and **RasPiOS Lite** (32bit or 64bit), using latest Raspberry Pi Imager from here: https://www.raspberrypi.com/software/

the alternative script which makes use of the GPU on the Pi3 to reduce CPU workload

## supported RasPiOS and Pi versions
- `rtlsdr-ogn-bin-arm64-0.2.9_debian_bullseye.tgz`: Bullseye (v11.x) **64-bit**, Pi Zero 2W, Pi3 or Pi4
- `rtlsdr-ogn-bin-ARM-0.2.9_raspbian_buster.tgz`: Bullseye (v11.x) and Buster (v10.x) **32-bit**, Pi Zero 2W, Pi3 or Pi4
- `rtlsdr-ogn-bin-ARM-0.2.9_raspbian_stretch.tgz`: Stretch (v9.x) 32-bit, Pi Zero 2W or Pi3
- `rtlsdr-ogn-bin-RPI-GPU-0.2.9_raspbian_stretch.tgz`: GPU version for Stretch and Buster, 32-bit, Pi3

## packages for x86 and x64 based thin-clients, please install them manually
- `rtlsdr-ogn-bin-x64-0.2.9_debian_bullseye.tgz`
- `rtlsdr-ogn-bin-x64-0.2.9_ubuntu_cosmic.tgz`
- `rtlsdr-ogn-bin-x86-0.2.9_debian_buster.tgz`

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
- enable SDR autogain (adding MinNoise and MaxNoise values):
```
  OGN:
  {
    CenterFreq = 868.8;    # [MHz] with 868.8MHz and 2MHz bandwidth you can capture all systems: FLARM/OGN/FANET/PilotAware
    Gain       =  50.0;    # [dB]  Normally use full gain, unless intermodulation occurs of you run with an LNA, then you need to find best value
    MinNoise   =   2.0;    # default minimum allowed noise
    MaxNoise   =   8.0;    # default maximum allowed noise
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

## automatic setup (standard script)
- plug your SD card into the Pi, connect your Pi3 or Pi4 to LAN via Ethernet cable and boot (in case of Pi Zero 2W you may need to wait and check for successful WiFi connection)
- connect to your pi using ssh
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi34.sh
```

## automatic setup (alternative script with GPU code for Pi3)
```
sudo apt update
sudo apt install git -y
git clone https://github.com/VirusPilot/ogn-pi34.git
./ogn-pi34/install-pi3-gpu.sh
```

## post install modifications
### GSM gain/frequency and ppm calibration
- see https://github.com/glidernet/ogn-rf/blob/6d6cd8a15a5fbff122542401180ea7e58af9ed92/INSTALL#L42
### OGN manual gain
- in case the SDR gain is set manually, it should be set such that the RF input noise is only a couple of dBs
### nightly reboot at 1 am
- execute the following: `sudo crontab -e` then add `0 1 * * * /sbin/reboot` and save 
