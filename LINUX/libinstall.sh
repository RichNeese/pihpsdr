#!/bin/sh

################################################################
#
# A script to clone wdsp from github and to compile and 
# install it. This is a prerequisite for compiling pihpsdr
#
################################################################

################################################################
#
# a) determine the location of THIS script
#    (this is where the files should be located)
#    and assume this is in the pihpsdr directory
#
################################################################

SCRIPT_FILE=`realpath $0`
THIS_DIR=`dirname $SCRIPT_FILE`
TARGET=`dirname $THIS_DIR`
WORKDIR='/tmp'

################################################################
#
# c) install lots of packages
# (many of them should already be there)
#
################################################################

# ------------------------------------
# Install standard tools and compilers
# ------------------------------------

apt -y install build-essential
apt -y install module-assistant
apt -y install vim
apt -y install make
apt -y install gcc
apt -y install g++
apt -y install gfortran
apt -y install git
apt -y install gpiod
apt -y install pkg-config
apt -y install cmake
apt -y install autoconf
apt -y install autopoint
apt -y install gettext
apt -y install automake
apt -y install libtool
apt -y install cppcheck
apt -y install dos2unix
apt -y install libzstd-dev

# ---------------------------------------
# Install libraries necessary for piHPSDR
# ---------------------------------------

apt -y install libfftw3-dev
apt -y install libgtk-3-dev
apt -y install libasound2-dev
apt -y install libcurl4-openssl-dev
apt -y install libusb-1.0-0-dev
apt -y install libi2c-dev
apt -y install libgpiod-dev
apt -y install libpulse-dev
apt -y install pulseaudio

# ----------------------------------------------
# Install standard libraries necessary for SOAPY
# ----------------------------------------------

apt -y install libaio-dev
apt -y install libavahi-client-dev
apt -y install libad9361-dev
apt -y install libiio-dev
apt -y install bison
apt -y install flex
apt -y install libxml2-dev
apt -y install librtlsdr-dev

################################################################
#
# c) download and install SoapySDR core
#
################################################################

cd $THISDIR
yes | rm -r SoapySDR
git clone https://github.com/pothosware/SoapySDR.git

cd $THISDIR/SoapySDR
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j 4
make install
ldconfig

################################################################
#
# d) download and install libiio
#    NOTE: libiio has just changed the API and SoapyPlutoSDR
#          is not yet updated. So compile version 0.25, which
#          is the last one with the old API
#
################################################################

################################################################
#
# e) download and install Soapy for Adalm Pluto
#
################################################################

cd $THISDIR
yes | rm -rf SoapyPlutoSDR
git clone https://github.com/pothosware/SoapyPlutoSDR

cd $WORKDIR/SoapyPlutoSDR
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j 4
make install
ldconfig

################################################################
#
# f) download and install Soapy for RTL sticks
#
################################################################

cd $WORKDIR
rm -rf wdsp SoapyPlutoSDR

cd $THISDIR/SoapyRTLSDR
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j 4
sudo make install
sudo ldconfig

################################################################
#
# g) create desktop icons, start scripts, etc.  for pihpsdr
#
################################################################

rm -f $HOME/Desktop/pihpsdr.desktop
rm -f $HOME/.local/share/applications/pihpsdr.desktop

cat <<EOT > $TARGET/pihpsdr.sh
cd $TARGET
$TARGET/pihpsdr >log 2>&1
EOT
chmod +x $TARGET/pihpsdr.sh

cat <<EOT > $TARGET/pihpsdr.desktop
#!/usr/bin/env xdg-open
[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Name[eb_GB]=piHPSDR
Exec=$TARGET/pihpsdr.sh
Icon=$TARGET/hpsdr_icon.png
Name=piHPSDR
EOT

cp $TARGET/pihpsdr.desktop $HOME/Desktop
mkdir -p $HOME/.local/share/applications
cp $TARGET/pihpsdr.desktop $HOME/.local/share/applications

cp $TARGET/release/pihpsdr/hpsdr.png $TARGET
cp $TARGET/release/pihpsdr/hpsdr_icon.png $TARGET

################################################################
#
# h) default GPIO lines to input + pullup
#
################################################################

if test -f "/boot/config.txt"; then
  if grep -q "gpio=4-13,16-27=ip,pu" /boot/config.txt; then
    echo "/boot/config.txt already contains gpio setup."
  else
    echo "/boot/config.txt does not contain gpio setup - adding it."
    echo "Please reboot system for this to take effect."
    cat <<EGPIO | sudo tee -a /boot/config.txt > /dev/null
[all]
# setup GPIO for pihpsdr controllers
gpio=4-13,16-27=ip,pu
EGPIO
  fi
fi
