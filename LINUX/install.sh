#!/bin/sh

echo "#################################################################"
echo ""
echo " Prepeare your Linux system for compiling and Installing "
echo ""
echo "                       piHPSDR "
echo""
echo "#################################################################"
echo ""
echo "################################################################"
echo ""
echo " First we need to make sure dependancies are installed. "
echo ""
echo " There may be several packages to install.  "
echo ""
echo " This could take several minutes to complete. "
echo ""
echo "################################################################"
echo ""

################################################################
#
# All packages needed for SDR++
#
################################################################
echo "Installing Deps for building SDR++ / SDR++Brown"
sudo apt -y install build-essential
sudo apt -y install cmake
sudo apt -y install pkg-config
sudo apt -y install libcodec2-dev
sudo apt -y install libgtk-3-dev
sudo apt -y install portaudio19-dev
sudo apt -y install libfftw3-dev
sudo apt -y install libpulse-dev
sudo apt -y install libsoundio-dev
sudo apt -y install libasound2-dev
sudo apt -y install libusb-dev
sudo apt -y install libglfw3-dev
sudo apt -y install libiio-dev
sudo apt -y install libiio-utils
sudo apt -y install libad9361-dev
sudo apt -y install librtaudio-dev
sudo apt -y install libvolk2-dev
sudo apt -y install libvulkan-volk-dev
sudo apt -y install libzstd-dev
sudo apt -y install zstd
echo "Done"

#########################################################
# Python make
#########################################################
echo "INSTALLING MAKO FOR PYTHON3"
sudo apt -y install python3-mako
echo "Done"

#########################################################
# Lib for bladerf
#########################################################
echo "INSTALLING BLADERF"
sudo apt -y install bladerf
sudo apt -y install libbladerf-dev
sudo apt -y install bladerf-firmware-fx3
sudo apt -y install bladerf-fpga-hostedx115
sudo apt -y install bladerf-fpga-hostedx40
sudo apt -y install bladerf-fpga-hostedxa4
sudo apt -y install bladerf-fpga-hostedxa5
sudo apt -y install bladerf-fpga-hostedxa9
echo "Done"

#########################################################
# Lib for RTL_SDR
#########################################################
echo "Installing RTL-SDR"
sudo apt -y install librtlsdr-dev
sudo apt -y install rtl-sdr
echo "Done"

sudo apt-get --yes install libfftw3-dev
sudo apt-get --yes install libgtk-3-dev
sudo apt-get --yes install libasound2-dev
sudo apt-get --yes install libcurl4-openssl-dev
sudo apt-get --yes install libusb-1.0-0-dev
sudo apt-get --yes install libi2c-dev
sudo apt-get --yes install libgpiod-dev
sudo apt-get --yes install libpulse-dev
sudo apt-get --yes install pulseaudio
sudo apt-get --yes install libpcap-dev

echo "Installing AIRSPYHF"
sudo apt -y install airspyhf
sudo apt -y install libairspyhf-dev
echo "Done"
echo ""

#########################################################
# Lib for hackers
# Disable if you want to us soapysdr drivers
#########################################################
echo "Installing HackRF"
sudo apt -y install hackrf
sudo apt -y install libhackrf-dev
echo "Done"
echo ""

#########################################################
# Limes suite
#########################################################
echo "Installing LimeSuite"
sudo apt -y install limesuite
sudo apt -y install liblimesuite-dev
echo "Done"
echo ""

################################################################
#
# This is for the SoapySDR universe
# This installs all the modules and firmware
# 
#
################################################################
echo "Installing SoapySDR and Deps"
sudo apt -y install libsoapysdr-dev
sudo apt -y install soapysdr-module-all
sudo apt -y install soapysdr-module-xtrx 
sudo apt -y install soapysapt-cache
sudo apt -y install libsoapysdr-doc
sudo apt -y install uhd-host
sudo apt -y install uhd-soapysdr
sudo apt -y install soapysdr-module-uhd
echo "Done"
echo ""

################################################################
# Dir for building pkgs
################################################################
mkdir tmp

################################################################
# GIt the sdrplay soapy audio module and building & install it.
################################################################
echo " building and installing SoapyAudio"
cd tmp
git clone https://github.com/pothosware/SoapyAudio.git
cd SoapyAudio
mkdir build
cd build
cmake ..
make
sudo make install
cd ~
echo "Done"
echo ""

################################################################
# GIt the sdrplay SoapyRTLTCP module and building  & install it.
################################################################
echo " building and installing SoapyRTLTCP"
cd tmp
git clone https://github.com/pothosware/SoapyRTLTCP.git
cd SoapyRTLTCP
mkdir build
cd build
cmake ..
make
sudo make install
cd ~
echo "Done"
echo ""

################################################################
# GIt the sdrplay soapyPlutoSDR module and building & install it.
################################################################
echo " building and installing SoapyPlutoSDR"
cd tmp
git clone https://github.com/pothosware/SoapyPlutoSDR.git
cd SoapyPlutoSDR
mkdir build
cd build
cmake ..
make
sudo make install
cd ~
echo "Done"
echo ""

################################################################
# GIt the sdrplay soapyPlutoSDR module and building & install it.
################################################################
echo " building and installing SoapyMultiSDR"
cd tmp
git clone https://github.com/pothosware/SoapyMultiSDR.git
cd SoapyMultiSDR
mkdir build
cd build
cmake ..
make
sudo make install
cd ~
echo "Done"

################################################################
# GIt the sdrplay soapy NetSDR module and building & install it.
################################################################
echo " building and installing SoapyNetSDR"
cd tmp
git clone https://github.com/pothosware/SoapyNetSDR.git
cd SoapyNestSDR
mkdir build
cd build
cmake ..
make
sudo make install
cd ~
echo "Done"
echo ""

################################################################
# Modules in the works 
################################################################
################################################################
# Git the sdrplay soapySpyServer module and buildin & install it.
################################################################
#echo " building and installing SoapySpyServer"
#git clone https://github.com/pothosware/SoapySpyServer.git
#cd SoapySpyServer
#mkdir build
#cd build
#cmake ..
#make
#sudo make install
#cd ~
#echo "Done"

################################################################
# Git the sdrplay soapyPlutoSDR module and building & install it.
################################################################
#echo " building and installing SoapyVOLKConverters"
#git clone https://github.com/pothosware/SoapyVOLKConverters.git
#cd SoapyVOLKConverters
#mkdir build
#cd build
#cmake ..
#make
#sudo make install
#cd ~
#echo "Done"
#echo ""

################################################################
# GIt the sdrplay soapy sidekiq module and building & install it.
################################################################
#echo " building and installing SoapySidekiq"
#cd tmp
#git clone https://github.com/pothosware/SoapySidekiq.git
#cd SoapySidekiq
#mkdir build
#cd build
#cmake ..
#make
#sudo make install
#cd ~
#echo "Done"
#echo ""

################################################################
# GIt the sdrplay soapy FunCube module and building & install it.
################################################################
#echo " building and installing SoapyFCDPP"
#cd tmp
#git clone https://github.com/pothosware/SoapyFCDPP.git
#cd SoapyFCDPP
#mkdir build
#cd build
#cmake ..
#make
#sudo make install
#cd ~
#echo "Done"
#echo ""

################################################################
#
# INSTALL SDRPLAY API for Linux
#
################################################################
echo "Installing SDRPLAY API FOR Linux And SOAPYSDR"
wget https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.14.0.run
sudo chmod 755 ./SDRplay_RSP_API-Linux-3.14.0.run
sudo ./SDRplay_RSP_API-Linux-3.14.0.run
cd ~
echo "Done"
#echo ""

################################################################
# GIt the sdrplay soapy module and build it.
################################################################
echo " building and installing SoapySDRPlay3"
git clone https://github.com/pothosware/SoapySDRPlay3.git
cd SoapySDRPlay3
mkdir build
cd build
cmake ..
make
sudo make install
cd ~
echo "Done"
echo ""

################################################################
# Install  Wdsp
################################################################
echo " Installing wdsp lib "
cd tmp
git clone https://github.com/dl1ycf/wdsp.git
cd wdsp
make clean
make -j4
sudo make install
cd ~
echo "Done"
echo ""

################################################################
# Remove the tmp dir and cleaning up space
################################################################
rm -rf tmp

echo ""
echo "################################################################"
echo " IF any errors please report them so that they can be fixed"
echo "################################################################"
echo " If there were no errors reporte."
echo " Everything should be ready to go."
echo " You can Now build piHPSDR "
echo "################################################################"
echo ""

echo "#####################################################"
echo ""
echo " Building and installing piHPSDR"
echo""
echo "#####################################################"
mkdir tmp
cd tmp
git clone -b my-work-branch --depth=1 https://github.com/RichNeese/pihpsdr.git
cd pihpsdr
cp Makefile MakefileGNU
echo "##############################################################"
echo ""
echo " Editing MakfileGNU to enable the features you want."
echo ""
echo " When finshed editing hit ctl+x to exit and save the changes"
echo ""
echo "##############################################################"
nano MakefileGNU
echo "buildig piHPSDH/LinHPSDR"
make -j4 -f MakefileGNU
echo " Installing piHPSDR / LinHPSDRR"
make -f MakefileGNU install
echo " Doing Cleanup"
make clean
cd ~
rm -rf tmp

echo "#####################################################"
echo ""
echo " piHPSDR is installed please reboot system "
echo""
echo "#####################################################"
