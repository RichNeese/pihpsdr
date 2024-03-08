#!/bin/sh

#####################################################
#
# prepeare your Mac  for compiling SDR++
#
######################################################

#####################################################
#
# ENABLE SOAPYSDR DRIVERS
# if you enable all the soapy drivers it will disable the
# default libs/drivers that allow use with out SoapySDR
#
# Defualt for all is N
#
# Must be enable SOAPYSDR=Y to install SoapySDR and modules
#
######################################################

SOAPYSDR=N 
SOAPYSDR_ALL_MODULES=N
SOAPYAISPY=N
SOAPYAISPYHF=N
SOAPYHACKRF=N
SOAPYLIMESUITE=N
SOAPYREDPITAYA=N
SOAPYPLUTOSDR=N
SOAPYRTLSDR=N 

################################################################
#
# a) MacOS does not have "realpath" so we need to fiddle around
#
################################################################

THISDIR="$(cd "$(dirname "$0")" && pwd -P)"

################################################################
#
# This adjusts the PATH. This is not bullet-proof, so if some-
# thing goes wrong here, the user will later not find the
# 'brew' command.
#
################################################################

if [ $SHELL == "/bin/sh" ]; then
apt -y shellenv sh >> $HOME/.profile
fi
if [ $SHELL == "/bin/bash" ]; then
apt -y shellenv csh >> $HOME/.bashrc
fi
if [ $SHELL == "/bin/csh" ]; then
apt -y shellenv csh >> $HOME/.cshrc
fi
if [ $SHELL == "/bin/zsh" ]; then
apt -y shellenv zsh >> $HOME/.zprofile
fi

################################################################
#
# All homebrew packages needed for SDR++
#
################################################################

apt -y install gtk+3
apt -y install pkg-config
apt -y install portaudio
apt -y install fftw
apt -y install libusb
apt -y install cmake
apt -y install glfw
apt -y install codec2
apt -y install libiio
apt -y install libad9361 
apt -y install volk
apt -y install python-mako
apt -y install zstd

#########################################################
# Lib for bladerf
#########################################################
apt -y install libbladerf

#########################################################
# Lib for RTL_SDR
#########################################################
if [ SOAPYRTLSDR == N  ]; then
	apt -y install rtl-sdr
fi
#########################################################
# Lib for airspy / airspyhf
# Disable if you want to us soapysdr drivers
#########################################################
if [ SOAPYAISPY == N ]; then
	apt -y install airspy
fi

if [ SOAPYAISPYHF == N ]; then
	apt -y install airspyhf
fi

#########################################################
# Lib for hackers
# Disable if you want to us soapysdr drivers
#########################################################
if [ SOAPYHACKRF == N ]; then
	apt -y install hackrf
fi

#########################################################
# Limes suite
#########################################################
if [ SOAPYLIMESUITE == N ]; then
	apt -y install limesuite
fi

################################################################
#
# This is for the SoapySDR universe
# There are even more radios supported for which you need
# additional modules, for a list, goto the web page
# https://formulae.brew.sh
# and insert the search string "pothosware". In the long
# list produced, search for the same string using the
# "search" facility of your internet browser
#
################################################################
if [ SOAPYSDR == Y ]; then

	apt -y install soapysdr

	if [ SOAPYSDR_ALL_MODULES == Y]; then
		apt -y install soapy
	fi

	if [ SOAPYAIRSPY == Y]; then
		apt -y install soapyairspy
	fi

	if [ SOAPYAISPYHF == Y ]; then
		apt -y install soapyairspyhf
	fi

	if [ SOAPYHACKRF == Y ]; then
		apt -y install soapyhackrf
	fi

	if [ SOAPYLIMESUITE == Y ]; then
		apt -y install limesuite
	fi

	if [ SOAPYREDPITAYA == Y  ]; then	
		apt -y install soapyredpitaya
	fi

	if [ SOAPYRTLSDR == Y  ]; then
		apt -y install soapyrtlsdr
	fi

	if [ SOAPYPLUTOSDR == Y  ]; then
		apt -y install soapyplutosdr
	fi
fi


