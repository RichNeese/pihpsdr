#######################################################################################
#
# Compile-time options, to be modified by end user.
# To activate an option, just change to XXXX=ON except for the AUDIO option,
# which reads AUDIO=YYYY with YYYY=ALSA or YYYY=PULSE.
#
#######################################################################################

AUDIO=
CWDAEMON=
EXTENDED_NR=
GPIO=
MIDI=
PURESIGNAL=
SATURN=
SERVER=
SOAPYSDR=
STEMLAB=
USBOZY=

#######################################################################################
# Explanation of compile time options
#######################################################################################

# AUDIO        | If AUDIO=ALSA, use ALSA rather than PulseAudio on Linux
# CWDAEMON     | If ON, compile with CWDAEMON support
# EXTENDED_NR  | If ON, piHPSDR can use extended noise reduction (VU3RDD WDSP version)
# GPIO         | If ON, compile with GPIO support (RaspPi only)
# MIDI         | If ON, compile with MIDI support
# PURESIGNAL   | If ON, compile with PureSignal support 
# SATURN       | If ON, compile with native SATURN/G2 XDMA support
# SERVER       | If ON, include client/server code (still far from being complete)
# SOAPYSDR     | If ON, piHPSDR can talk to radios via SoapySDR library
# STEMLAB      | If ON, piHPSDR can start SDR app on RedPitay via Web interface
# USBOZY       | If ON, piHPSDR can talk to legacy USB OZY radios

#######################################################################################
#
# No end-user changes below this line!
#
#######################################################################################

# get the OS Name
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S), Darwin)
	MACAPPDIR=$HOME/Applications
else
	PREFIX?=/usr
	APPSDIR=$(PREFIX)/share/applications
	APPICONDIR=$(PREFIX)/share/pihpsdr
	EXECDIR=$(PREFIX)/local/bin
	ICONSDIR=$(PREFIX)/share/icons/pihpsdr
endif

# Get git commit version and date
GIT_DATE := $(firstword $(shell git --no-pager show --date=short --format="%ai" --name-only))
GIT_VERSION := $(shell git describe --abbrev=0 --tags --always --dirty)
GIT_COMMIT := $(shell git log --pretty=format:"%h"  -1)

CFLAGS?= -O3 -Wno-deprecated-declarations -Wall
LINK?=   $(CC)

#
# The "official" way to compile+link with pthreads is now to use the -pthread option
# *both* for the compile and the link step.
#
CFLAGS+=-pthread -I./src
LINK+=-pthread

PKG_CONFIG = pkg-config

WDSP_INCLUDE=-I./wdsp
WDSP_LIBS=wdsp/libwdsp.a `$(PKG_CONFIG) --libs fftw3`

##############################################################################
#
# Settings for optional features, to be requested by un-commenting lines above
#
##############################################################################

##############################################################################
#
# disable GPIO and SATURN for MacOS, simply because it is not there
#
##############################################################################

ifeq ($(UNAME_S), Darwin)
GPIO=
SATURN=
endif

##############################################################################
#
# Add modules for Pure Signal if requested.
# Note these are different for Linux/MacOS
#
##############################################################################

ifeq ($(PURESIGNAL),ON)
PURESIGNAL_OPTIONS=-D PURESIGNAL
PURESIGNAL_SOURCES= src/puresignal.c
PURESIGNAL_HEADERS= src/puresignal.h
PURESIGNAL_OBJS= src/puresignal.o
endif

##############################################################################
#
# Add modules for PCWDAEMON if requested.
# Note these are different for Linux/MacOS
#
##############################################################################

ifeq ($(UNAME_S), Linux)
# cwdaemon support. Allows linux based logging software to key an Hermes/HermesLite2
# needs :
#			https://github.com/m5evt/unixcw-3.5.1.git

ifeq ($(CWDAEMON),ON)
CWDAEMON_OPTIONS=-D CWDAEMON
CWDAEMON_LIBS=-lcw
CWDAEMON_SOURCES= src/cwdaemon.c
CWDAEMON_HEADERS= src/cwdaemon.h
CWDAEMON_OBJS= src/cwdaemon.o
endif
endif

##############################################################################
#
# Add modules for MIDI if requested.
# Note these are different for Linux/MacOS
#
##############################################################################

ifeq ($(MIDI),ON)
MIDI_OPTIONS=-D MIDI
MIDI_HEADERS= midi.h midi_menu.h alsa_midi.h
ifeq ($(UNAME_S), Darwin)
MIDI_SOURCES= src/mac_midi.c src/midi2.c src/midi3.c src/midi_menu.c
MIDI_OBJS= src/mac_midi.o src/midi2.o src/midi3.o src/midi_menu.o
MIDI_LIBS= -framework CoreMIDI -framework Foundation
endif
ifeq ($(UNAME_S), Linux)
MIDI_SOURCES= src/alsa_midi.c src/midi2.c src/midi3.c src/midi_menu.c
MIDI_OBJS= src/alsa_midi.o src/midi2.o src/midi3.o src/midi_menu.o
MIDI_LIBS= -lasound
endif
endif

##############################################################################
#
# Add libraries for Saturn support, if requested
#
##############################################################################

ifeq ($(SATURN),ON)
SATURN_OPTIONS=-D SATURN
SATURN_SOURCES= src/saturndrivers.c src/saturnregisters.c src/saturnserver.c \
src/saturnmain.c src/saturn_menu.c
SATURN_HEADERS= src/saturndrivers.h src/saturnregisters.h src/saturnserver.h \
src/saturnmain.h src/saturn_menu.h
SATURN_OBJS= src/saturndrivers.o src/saturnregisters.o src/saturnserver.o \
src/saturnmain.o src/saturn_menu.o
endif

##############################################################################
#
# Add libraries for USB OZY support, if requested
#
##############################################################################

ifeq ($(USBOZY),ON)
USBOZY_OPTIONS=-D USBOZY
USBOZY_LIBS=-lusb-1.0
USBOZY_SOURCES= src/ozyio.c
USBOZY_HEADERS= src/ozyio.h
USBOZY_OBJS= src/ozyio.o
endif

##############################################################################
#
# Add libraries for SoapySDR support, if requested
#
##############################################################################

ifeq ($(SOAPYSDR),ON)
SOAPYSDR_OPTIONS=-D SOAPYSDR
SOAPYSDRLIBS=-lSoapySDR
SOAPYSDR_SOURCES= src/soapy_discovery.c src/soapy_protocol.c
SOAPYSDR_HEADERS= src/soapy_discovery.h src/soapy_protocol.h
SOAPYSDR_OBJS= src/soapy_discovery.o src/soapy_protocol.o
endif

##############################################################################
#
# Add support for extended noise reduction, if requested
# This implies that one compiles against a wdsp.h e.g. in /usr/local/include,
# and links with a WDSP shared lib e.g. in /usr/local/lib
#
##############################################################################

ifeq ($(EXTENDED_NR), ON)
EXTNR_OPTIONS=-DEXTNR
WDSP_INCLUDE=
WDSP_LIBS=-lwdsp
endif

##############################################################################
#
# Add libraries for GPIO support, if requested
#
##############################################################################

ifeq ($(GPIO),ON)
GPIO_OPTIONS=-D GPIO
GPIOD_VERSION=$(shell pkg-config --modversion libgpiod)
ifeq ($(GPIOD_VERSION),1.2)
GPIO_OPTIONS += -D OLD_GPIOD
endif
GPIO_LIBS=-lgpiod -li2c
endif

##############################################################################
#
# Activate code for RedPitaya (Stemlab/Hamlab/plain vanilla), if requested
# This code detects the RedPitaya by its WWW interface and starts the SDR
# application.
# If the RedPitaya auto-starts the SDR application upon system start,
# this option is not needed!
#
##############################################################################

ifeq ($(STEMLAB), ON)
STEMLAB_OPTIONS=-D STEMLAB_DISCOVERY `$(PKG_CONFIG) --cflags libcurl`
STEMLAB_LIBS=`$(PKG_CONFIG) --libs libcurl`
STEMLAB_SOURCES= src/stemlab_discovery.c
STEMLAB_HEADERS= src/stemlab_discovery.h
STEMLAB_OBJS= src/stemlab_discovery.o
endif

##############################################################################
#
# Activate code for remote operation, if requested.
# This feature is not yet finished. If finished, it
# allows to run two instances of piHPSDR on two
# different computers, one interacting with the operator
# and the other talking to the radio, and both computers
# may be connected by a long-distance internet connection.
#
##############################################################################

ifeq ($(SERVER), ON)
SERVER_OPTIONS=-D CLIENT_SERVER
SERVER_SOURCES= src/client_server.c src/server_menu.c
SERVER_HEADERS= src/client_server.h src/server_menu.h
SERVER_OBJS= src/client_server.o src/server_menu.o
endif

##############################################################################
#
# Options for audio module
#  - MacOS: only PORTAUDIO
#  - Linux: either PULSEAUDIO (default) or ALSA (upon request)
#
##############################################################################

ifeq ($(UNAME_S), Darwin)
  AUDIO=PORTAUDIO
endif
ifeq ($(UNAME_S), Linux)
  ifneq ($(AUDIO) , ALSA)
    AUDIO=PULSE
  endif
endif

##############################################################################
#
# Add libraries for using PulseAudio, if requested
#
##############################################################################

ifeq ($(AUDIO), PULSE)
AUDIO_OPTIONS=-DPULSEAUDIO
ifeq ($(UNAME_S), Linux)
  AUDIO_LIBS=-lpulse-simple -lpulse -lpulse-mainloop-glib
endif
ifeq ($(UNAME_S), Darwin)
  AUDIO_LIBS=-lpulse-simple -lpulse
endif
AUDIO_SOURCES=src/pulseaudio.c
AUDIO_OBJS=src/pulseaudio.o
endif

##############################################################################
#
# Add libraries for using ALSA, if requested
#
##############################################################################

ifeq ($(AUDIO), ALSA)
AUDIO_OPTIONS=-DALSA
AUDIO_LIBS=-lasound
AUDIO_SOURCES=src/audio.c
AUDIO_OBJS=src/audio.o
endif

##############################################################################
#
# Add libraries for using PortAudio, if requested
#
##############################################################################

ifeq ($(AUDIO), PORTAUDIO)
AUDIO_OPTIONS=-DPORTAUDIO `$(PKG_CONFIG) --cflags portaudio-2.0`
AUDIO_LIBS=`$(PKG_CONFIG) --libs portaudio-2.0`
AUDIO_SOURCES=src/portaudio.c
AUDIO_OBJS=src/portaudio.o
endif

##############################################################################
#
# End of "libraries for optional features" section
#
##############################################################################

##############################################################################
#
# Includes and Libraries for the graphical user interface (GTK)
#
##############################################################################

GTKINCLUDES=`$(PKG_CONFIG) --cflags gtk+-3.0`
GTKLIBS=`$(PKG_CONFIG) --libs gtk+-3.0`

##############################################################################
#
# Specify additional OS-dependent system libraries
#
##############################################################################

ifeq ($(UNAME_S), Linux)
SYSLIBS=-lrt
endif

ifeq ($(UNAME_S), Darwin)
SYSLIBS=-framework IOKit
endif

##############################################################################
#
# All the command-line options to compile the *.c files
#
##############################################################################

OPTIONS=$(MIDI_OPTIONS) $(USBOZY_OPTIONS) \
	$(GPIO_OPTIONS) $(SOAPYSDR_OPTIONS) \
	$(ANDROMEDA_OPTIONS) $(SATURN_OPTIONS) \
	$(STEMLAB_OPTIONS) $(SERVER_OPTIONS) \
	$(AUDIO_OPTIONS) $(EXTNR_OPTIONS) \
	$(PURESIGNAL_OPTIONS) $(CWDAEMON_OPTIONS) \
	-D GIT_DATE='"$(GIT_DATE)"' -D GIT_VERSION='"$(GIT_VERSION)"' -D GIT_COMMIT='"$(GIT_COMMIT)"'

INCLUDES=$(GTKINCLUDES)
COMPILE=$(CC) $(CFLAGS) $(WDSP_INCLUDE) $(OPTIONS) $(INCLUDES)

.c.o:
	$(COMPILE) -c -o $@ $<

##############################################################################
#
# All the libraries we need to link with (including WDSP, libm, $(SYSLIBS))
#
##############################################################################

LIBS= $(LDFLAGS) $(AUDIO_LIBS) $(USBOZY_LIBS) $(GTKLIBS) $(GPIO_LIBS) $(SOAPYSDRLIBS) $(STEMLAB_LIBS) \
	$(MIDI_LIBS) $(WDSP_LIBS) -lm $(SYSLIBS)

##############################################################################
#
# The main target, the pihpsdr program
#
##############################################################################

PROGRAM=pihpsdr

##############################################################################
#
# The core *.c files in alphabetical order
#
##############################################################################

SOURCES= \
src/MacOS.c \
src/about_menu.c \
src/actions.c \
src/action_dialog.c \
src/agc_menu.c \
src/ant_menu.c \
src/appearance.c \
src/band.c \
src/band_menu.c \
src/bandstack_menu.c \
src/css.c \
src/configure.c \
src/cw_menu.c \
src/cwramp.c \
src/discovered.c \
src/discovery.c \
src/display_menu.c \
src/diversity_menu.c \
src/encoder_menu.c \
src/equalizer_menu.c \
src/exit_menu.c \
src/ext.c \
src/fft_menu.c \
src/filter.c \
src/filter_menu.c \
src/gpio.c \
src/i2c.c \
src/iambic.c \
src/led.c \
src/main.c \
src/message.c \
src/meter.c \
src/meter_menu.c \
src/mode.c \
src/mode_menu.c \
src/mystring.c \
src/new_discovery.c \
src/new_menu.c \
src/new_protocol.c \
src/noise_menu.c \
src/oc_menu.c \
src/old_discovery.c \
src/old_protocol.c \
src/pa_menu.c \
src/property.c \
src/protocols.c \
src/ps_menu.c \
src/radio.c \
src/radio_menu.c \
src/receiver.c \
src/rigctl.c \
src/rigctl_menu.c \
src/rx_menu.c \
src/rx_panadapter.c \
src/screen_menu.c \
src/sintab.c \
src/sliders.c \
src/startup.c \
src/store.c \
src/store_menu.c \
src/switch_menu.c \
src/toolbar.c \
src/toolbar_menu.c \
src/transmitter.c \
src/tx_menu.c \
src/tx_panadapter.c \
src/version.c \
src/vfo.c \
src/vfo_menu.c \
src/vox.c \
src/vox_menu.c \
src/waterfall.c \
src/xvtr_menu.c \
src/zoompan.c

##############################################################################
#
# The core *.h (header) files in alphabetical order
#
##############################################################################

HEADERS= \
src/MacOS.h \
src/about_menu.h \
src/actions.h \
src/action_dialog.h \
src/adc.h \
src/agc.h \
src/agc_menu.h \
src/alex.h \
src/ant_menu.h \
src/appearance.h \
src/band.h \
src/band_menu.h \
src/bandstack_menu.h \
src/bandstack.h \
src/channel.h \
src/configure.h \
src/css.h \
src/cw_menu.h \
src/dac.h \
src/discovered.h \
src/discovery.h \
src/display_menu.h \
src/diversity_menu.h \
src/encoder_menu.h \
src/equalizer_menu.h \
src/exit_menu.h \
src/ext.h \
src/fft_menu.h \
src/filter.h \
src/filter_menu.h \
src/gpio.h \
src/iambic.h \
src/i2c.h \
src/led.h \
src/main.h \
src/message.h \
src/meter.h \
src/meter_menu.h \
src/mode.h \
src/mode_menu.h \
src/mystring.h \
src/new_discovery.h \
src/new_menu.h \
src/new_protocol.h \
src/noise_menu.h \
src/oc_menu.h \
src/old_discovery.h \
src/old_protocol.h \
src/pa_menu.h \
src/property.h \
src/protocols.h \
src/ps_menu.h \
src/radio.h \
src/radio_menu.h \
src/receiver.h \
src/rigctl.h \
src/rigctl_menu.h \
src/rx_menu.h \
src/rx_panadapter.h \
src/screen_menu.h \
src/sintab.h \
src/sliders.h \
src/startup.h \
src/store.h \
src/store_menu.h \
src/switch_menu.h \
src/toolbar.h \
src/toolbar_menu.h \
src/transmitter.h \
src/tx_menu.h \
src/tx_panadapter.h \
src/version.h \
src/vfo.h \
src/vfo_menu.h \
src/vox.h \
src/vox_menu.h \
src/waterfall.h \
src/xvtr_menu.h \
src/zoompan.h

##############################################################################
#
# The core *.o (object) files in alphabetical order
#
##############################################################################

OBJS= \
src/MacOS.o \
src/about_menu.o \
src/actions.o \
src/action_dialog.o \
src/agc_menu.o \
src/ant_menu.o \
src/appearance.o \
src/band.o \
src/band_menu.o \
src/bandstack_menu.o \
src/configure.o \
src/css.o \
src/cw_menu.o \
src/cwramp.o \
src/discovered.o \
src/discovery.o \
src/display_menu.o \
src/diversity_menu.o \
src/encoder_menu.o \
src/equalizer_menu.o \
src/exit_menu.o \
src/ext.o \
src/fft_menu.o \
src/filter.o \
src/filter_menu.o \
src/gpio.o \
src/iambic.o \
src/i2c.o \
src/led.o \
src/main.o \
src/message.o \
src/meter.o \
src/meter_menu.o \
src/mode.o \
src/mode_menu.o \
src/mystring.o \
src/new_discovery.o \
src/new_menu.o \
src/new_protocol.o \
src/noise_menu.o \
src/oc_menu.o \
src/old_discovery.o \
src/old_protocol.o \
src/pa_menu.o \
src/property.o \
src/protocols.o \
src/ps_menu.o \
src/radio.o \
src/radio_menu.o \
src/receiver.o \
src/rigctl.o \
src/rigctl_menu.o \
src/rx_menu.o \
src/rx_panadapter.o \
src/screen_menu.o \
src/sintab.o \
src/sliders.o \
src/startup.o \
src/store.o \
src/store_menu.o \
src/switch_menu.o \
src/toolbar.o \
src/toolbar_menu.o \
src/transmitter.o \
src/tx_menu.o \
src/tx_panadapter.o \
src/version.o \
src/vfo.o \
src/vfo_menu.o \
src/vox.o \
src/vox_menu.o \
src/xvtr_menu.o \
src/waterfall.o \
src/zoompan.o

##############################################################################
#
# How to link the program
#
##############################################################################

$(PROGRAM):  $(OBJS) $(AUDIO_OBJS) $(USBOZY_OBJS) $(SOAPYSDR_OBJS) \
		$(MIDI_OBJS) $(STEMLAB_OBJS) $(SERVER_OBJS) $(SATURN_OBJS)
	$(COMPILE) -c -o src/version.o src/version.c
ifneq (z$(WDSP_INCLUDE), z)
	@+make -C wdsp
endif
	$(LINK) -o $(PROGRAM) $(OBJS) $(AUDIO_OBJS) $(USBOZY_OBJS) $(SOAPYSDR_OBJS) \
		$(MIDI_OBJS) $(STEMLAB_OBJS) $(SERVER_OBJS) $(SATURN_OBJS) $(LIBS)

##############################################################################
#
# "make check" invokes the cppcheck program to do a source-code checking.
#
# The "-pthread" compiler option is not valid for cppcheck and must be filtered out.
# Furthermore, we can add additional options to cppcheck in the variable CPPOPTIONS
#
# Normally cppcheck complains about variables that could be declared "const".
# Suppress this warning for callback functions because adding "const" would need
# an API change in many cases.
#
# On MacOS, cppcheck usually cannot find the system include files so we suppress any
# warnings therefrom. Furthermore, we can use --check-level=exhaustive on MacOS
# since there we have new newest version (2.11), while on RaspPi we still have 2.3.
#
##############################################################################

CPPOPTIONS= --inline-suppr --enable=all
CPPOPTIONS += --suppress=unusedFunction
CPPOPTIONS += --suppress=constParameterCallback
CPPOPTIONS += --suppress=missingIncludeSystem
CPPINCLUDES:=$(shell echo $(INCLUDES) | sed -e "s/-pthread / /" )

ifeq ($(UNAME_S), Darwin)
CPPOPTIONS += -D__APPLE__ --check-level=exhaustive
else
CPPOPTIONS += -D__linux__
endif

.PHONY:	cppcheck
cppcheck:
	cppcheck -j 4 $(CPPOPTIONS) $(OPTIONS) $(CPPINCLUDES) $(AUDIO_SOURCES) $(SOURCES) \
	$(USBOZY_SOURCES)  $(SOAPYSDR_SOURCES) $(MIDI_SOURCES) $(STEMLAB_SOURCES) \
	$(SERVER_SOURCES) $(SATURN_SOURCES)

.PHONY:	clean
clean:
	rm -f src/*.o
	rm -f $(PROGRAM) hpsdrsim bootloader
	rm -rf $(PROGRAM).app
	@make -C release/LatexManual clean
	@make -C wdsp clean

#############################################################################
#
# "make release" is for maintainers and not for end-users.
# If this results in an error for end users, this is a feature not a bug.
# Remove pihpsdr and libwdsp.so from release/pihpsdr since these might
# be left-overs.
#
#############################################################################

.PHONY:	release
release: $(PROGRAM)
	make -C release/LatexManual release
	rm -f release/pihpsdr/pihpsdr
	rm -f release/pihpsdr/libwdsp.so
	cp $(PROGRAM) release/pihpsdr
	cd release; tar cvf pihpsdr-$(GIT_VERSION).tar pihpsdr

.PHONY: install-deps
install-deps:
ifeq ($(UNAME_S), Darwin)
	zsh ./MacOs/brew.init
else
	bash ./LINUX/libinstall.sh
endif

.PHONY: install-dirs
install-dirs:
ifeq ($(UNAME_S), Linux)
	mkdir -p $(EXECDIR) $(ICONSDIR) $(APPSDIR) 
endif

.PHONY: install
install: install-dirs
ifeq ($(UNAME_S), Linux)
	install $(PROGRAM) $(EXECDIR)
	install LINUX/hpsdr.png $(APPICONDIR)
	install LINUX/hpsdr_icon.png $(ICONSDIR)
	install LINUX/pihpsdr.desktop $(APPSDIR)
endif

.PHONY: gpio
gpio:
#currently for raspbian only (working to fix on armbian setups)
ifeq ($(UNAME_S), Linux)
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
		endif
	endif
endif

.PHONY: uninstall
uninstall:
ifeq ($(UNAME_S), Linux)
	rm $(EXECDIR)/pihpsdr
	rm $(APPSDIR)/pihpsdr.desktop
	rm -rf $(ICONSDIR)
endif

#############################################################################
#
# hpsdrsim is a cool program that emulates an SDR board with UDP and TCP
# facilities. It even feeds back the TX signal and distorts it, so that
# you can test PureSignal.
# This feature only works if the sample rate is 48000
#
#############################################################################

src/hpsdrsim.o:     src/hpsdrsim.c  src/hpsdrsim.h
	$(CC) -c $(CFLAGS) -o src/hpsdrsim.o src/hpsdrsim.c
	
src/newhpsdrsim.o:	src/newhpsdrsim.c src/hpsdrsim.h
	$(CC) -c $(CFLAGS) -o src/newhpsdrsim.o src/newhpsdrsim.c

hpsdrsim:       src/hpsdrsim.o src/newhpsdrsim.o
	$(LINK) -o hpsdrsim src/hpsdrsim.o src/newhpsdrsim.o -lm


#############################################################################
#
# bootloader is a small command-line program that allows to
# set the radio's IP address and upload firmware through the
# ancient protocol. This program can only be run as root since
# this protocol requires "sniffing" at the Ethernet adapter
# (this "sniffing" is done via the pcap library)
#
#############################################################################

bootloader:	src/bootloader.c
	$(CC) -o bootloader src/bootloader.c -lpcap

#############################################################################
#
# We do not do package building because piHPSDR is preferably built from
# the sources on the target machine. Take the following  lines as a hint
# to package bundlers.
#
#############################################################################

debian:
	mkdir -p pkg/pihpsdr/usr/local/bin
	mkdir -p pkg/pihpsdr/usr/local/lib
	mkdir -p pkg/pihpsdr/usr/share/pihpsdr
	mkdir -p pkg/pihpsdr/usr/share/applications
	cp $(PROGRAM) pkg/pihpsdr/usr/local/bin
	cp /usr/local/lib/libwdsp.so pkg/pihpsdr/usr/local/lib
	cp release/pihpsdr/hpsdr.png pkg/pihpsdr/usr/share/pihpsdr
	cp release/pihpsdr/hpsdr_icon.png pkg/pihpsdr/usr/share/pihpsdr
	cp release/pihpsdr/pihpsdr.desktop pkg/pihpsdr/usr/share/applications
	cd pkg; dpkg-deb --build pihpsdr

#############################################################################
#
# Create a file named DEPEND containing dependencies, to be added to
# the Makefile. This is done here because we need lots of #defines
# to make it right.
#
#############################################################################

.PHONY: DEPEND
DEPEND:
	rm -f DEPEND
	touch DEPEND
	makedepend -DMIDI -DSATURN -DUSBOZY -DSOAPYSDR -DEXTNR -DGPIO \
		-DSTEMLAB_DISCOVERY -DCLIENT_SERVER -DPULSEAUDIO \
		-DPORTAUDIO -DALSA -D__APPLE__ -D__linux__ \
		-f DEPEND -I./src src/*.c src/*.h
#############################################################################
#
# This is for MacOS "app" creation ONLY
#
#       The piHPSDR working directory is
#	$HOME -> Application Support -> piHPSDR
#
#       That is the directory where the WDSP wisdom file (created upon first
#       start of piHPSDR) but also the radio settings and the midi.props file
#       are stored.
#
#       No libraries are included in the app bundle, so it will only run
#       on the computer where it was created, and on other computers which
#       have all librariesand possibly the SoapySDR support
#       modules installed.
#############################################################################

.PHONY: app
app:	$(OBJS) $(AUDIO_OBJS) $(USBOZY_OBJS)  $(SOAPYSDR_OBJS) \
		$(MIDI_OBJS) $(STEMLAB_OBJS) $(SERVER_OBJS) $(SATURN_OBJS)
ifneq (z$(WDSP_INCLUDE), z)
	@+make -C wdsp
endif
	$(LINK) -headerpad_max_install_names -o $(PROGRAM) $(OBJS) $(AUDIO_OBJS) $(USBOZY_OBJS)  \
		$(SOAPYSDR_OBJS) $(MIDI_OBJS) $(STEMLAB_OBJS) $(SERVER_OBJS) $(SATURN_OBJS) \
		$(LIBS) $(LDFLAGS)
	@rm -rf pihpsdr.app
	@mkdir -p pihpsdr.app/Contents/MacOS
	@mkdir -p pihpsdr.app/Contents/Frameworks
	@mkdir -p pihpsdr.app/Contents/Resources
	@cp pihpsdr pihpsdr.app/Contents/MacOS/pihpsdr
	@cp MacOS/PkgInfo pihpsdr.app/Contents
	@cp MacOS/Info.plist pihpsdr.app/Contents
	@cp MacOS/hpsdr.icns pihpsdr.app/Contents/Resources/hpsdr.icns
	@cp MacOS/hpsdr.png pihpsdr.app/Contents/Resources

#############################################################################
#
# What follows is automatically generated by the "makedepend" program
# implemented here with "make DEPEND". This should be re-done each time
# a header file is added, or added to a C source code file.
#
#############################################################################

# DO NOT DELETE

src/MacOS.o: /usr/include/stdio.h /usr/include/semaphore.h
src/MacOS.o: /usr/include/features.h /usr/include/features-time64.h
src/MacOS.o: /usr/include/stdc-predef.h /usr/include/errno.h src/message.h
src/about_menu.o: /usr/include/ctype.h /usr/include/features.h
src/about_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/about_menu.o: /usr/include/stdio.h /usr/include/string.h
src/about_menu.o: /usr/include/strings.h /usr/include/stdlib.h
src/about_menu.o: /usr/include/alloca.h /usr/include/netinet/in.h
src/about_menu.o: /usr/include/endian.h /usr/include/arpa/inet.h
src/about_menu.o: src/new_menu.h src/about_menu.h src/discovered.h
src/about_menu.o: /usr/include/SoapySDR/Device.h
src/about_menu.o: /usr/include/SoapySDR/Config.h
src/about_menu.o: /usr/include/SoapySDR/Types.h
src/about_menu.o: /usr/include/SoapySDR/Constants.h
src/about_menu.o: /usr/include/SoapySDR/Errors.h src/radio.h src/adc.h
src/about_menu.o: src/dac.h src/receiver.h /usr/include/portaudio.h
src/about_menu.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/about_menu.o: /usr/include/fcntl.h /usr/include/assert.h
src/about_menu.o: /usr/include/poll.h /usr/include/errno.h
src/about_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/about_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/about_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/about_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/about_menu.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/about_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/about_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/about_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/about_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/about_menu.o: /usr/include/alsa/seq_midi_event.h
src/about_menu.o: /usr/include/pulse/pulseaudio.h
src/about_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/about_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/about_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/about_menu.o: /usr/include/pulse/version.h
src/about_menu.o: /usr/include/pulse/mainloop-api.h
src/about_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/about_menu.o: /usr/include/pulse/channelmap.h
src/about_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/about_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/about_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/about_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/about_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/about_menu.o: /usr/include/pulse/utf8.h
src/about_menu.o: /usr/include/pulse/thread-mainloop.h
src/about_menu.o: /usr/include/pulse/mainloop.h
src/about_menu.o: /usr/include/pulse/mainloop-signal.h
src/about_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/about_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/about_menu.o: src/transmitter.h src/version.h src/mystring.h
src/action_dialog.o: src/main.h src/actions.h
src/actions.o: /usr/include/math.h src/main.h src/discovery.h src/receiver.h
src/actions.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/actions.o: /usr/include/unistd.h /usr/include/features.h
src/actions.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/actions.o: /usr/include/stdio.h /usr/include/stdlib.h
src/actions.o: /usr/include/alloca.h /usr/include/string.h
src/actions.o: /usr/include/strings.h /usr/include/fcntl.h
src/actions.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/actions.o: /usr/include/endian.h /usr/include/alsa/asoundef.h
src/actions.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/actions.o: /usr/include/time.h /usr/include/alsa/input.h
src/actions.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/actions.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/actions.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/actions.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/actions.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/actions.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/actions.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/actions.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/actions.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/actions.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/actions.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/actions.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/actions.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/actions.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/actions.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/actions.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/actions.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/actions.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/actions.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/actions.o: /usr/include/pulse/mainloop.h
src/actions.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/actions.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/actions.o: /usr/include/pulse/simple.h src/sliders.h src/transmitter.h
src/actions.o: src/actions.h src/band_menu.h src/diversity_menu.h src/vfo.h
src/actions.o: src/mode.h src/radio.h src/adc.h src/dac.h src/discovered.h
src/actions.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/actions.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/actions.o: /usr/include/SoapySDR/Constants.h
src/actions.o: /usr/include/SoapySDR/Errors.h src/radio_menu.h src/new_menu.h
src/actions.o: src/new_protocol.h src/MacOS.h /usr/include/semaphore.h
src/actions.o: src/ps_menu.h src/agc.h src/filter.h src/band.h
src/actions.o: src/bandstack.h src/noise_menu.h src/client_server.h src/ext.h
src/actions.o: src/zoompan.h src/gpio.h src/toolbar.h src/iambic.h
src/actions.o: src/store.h src/message.h src/mystring.h
src/agc_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/agc_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/agc_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/agc_menu.o: /usr/include/stdc-predef.h /usr/include/string.h
src/agc_menu.o: /usr/include/strings.h src/new_menu.h src/agc_menu.h
src/agc_menu.o: src/agc.h src/band.h src/bandstack.h src/radio.h src/adc.h
src/agc_menu.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/agc_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/agc_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/agc_menu.o: /usr/include/SoapySDR/Constants.h
src/agc_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/agc_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/agc_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/agc_menu.o: /usr/include/assert.h /usr/include/poll.h
src/agc_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/agc_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/agc_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/agc_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/agc_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/agc_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/agc_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/agc_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/agc_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/agc_menu.o: /usr/include/alsa/seq_midi_event.h
src/agc_menu.o: /usr/include/pulse/pulseaudio.h
src/agc_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/agc_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/agc_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/agc_menu.o: /usr/include/pulse/version.h
src/agc_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/agc_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/agc_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/agc_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/agc_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/agc_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/agc_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/agc_menu.o: /usr/include/pulse/utf8.h
src/agc_menu.o: /usr/include/pulse/thread-mainloop.h
src/agc_menu.o: /usr/include/pulse/mainloop.h
src/agc_menu.o: /usr/include/pulse/mainloop-signal.h
src/agc_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/agc_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/agc_menu.o: src/transmitter.h src/vfo.h src/mode.h src/ext.h
src/agc_menu.o: src/client_server.h
src/alsa_midi.o: src/actions.h src/midi.h src/midi_menu.h src/alsa_midi.h
src/alsa_midi.o: src/message.h
src/ant_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/ant_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/ant_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/ant_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/ant_menu.o: /usr/include/string.h /usr/include/strings.h src/new_menu.h
src/ant_menu.o: src/ant_menu.h src/band.h src/bandstack.h src/radio.h
src/ant_menu.o: src/adc.h src/dac.h src/discovered.h
src/ant_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/ant_menu.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/ant_menu.o: /usr/include/SoapySDR/Types.h
src/ant_menu.o: /usr/include/SoapySDR/Constants.h
src/ant_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/ant_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/ant_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/ant_menu.o: /usr/include/assert.h /usr/include/poll.h
src/ant_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/ant_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/ant_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/ant_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/ant_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/ant_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/ant_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/ant_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/ant_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/ant_menu.o: /usr/include/alsa/seq_midi_event.h
src/ant_menu.o: /usr/include/pulse/pulseaudio.h
src/ant_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/ant_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/ant_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/ant_menu.o: /usr/include/pulse/version.h
src/ant_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/ant_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/ant_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/ant_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/ant_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/ant_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/ant_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/ant_menu.o: /usr/include/pulse/utf8.h
src/ant_menu.o: /usr/include/pulse/thread-mainloop.h
src/ant_menu.o: /usr/include/pulse/mainloop.h
src/ant_menu.o: /usr/include/pulse/mainloop-signal.h
src/ant_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/ant_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/ant_menu.o: src/transmitter.h src/new_protocol.h src/MacOS.h
src/ant_menu.o: src/soapy_protocol.h src/message.h
src/appearance.o: /usr/include/stdlib.h /usr/include/alloca.h
src/appearance.o: /usr/include/features.h /usr/include/features-time64.h
src/appearance.o: /usr/include/stdc-predef.h src/appearance.h
src/audio.o: /usr/include/stdint.h /usr/include/stdio.h /usr/include/stdlib.h
src/audio.o: /usr/include/alloca.h /usr/include/features.h
src/audio.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/audio.o: /usr/include/unistd.h /usr/include/string.h
src/audio.o: /usr/include/strings.h /usr/include/errno.h /usr/include/fcntl.h
src/audio.o: /usr/include/sched.h /usr/include/semaphore.h
src/audio.o: /usr/include/alsa/asoundlib.h /usr/include/assert.h
src/audio.o: /usr/include/poll.h /usr/include/endian.h
src/audio.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/audio.o: /usr/include/alsa/global.h /usr/include/time.h
src/audio.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/audio.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/audio.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/audio.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/audio.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/audio.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/audio.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/audio.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/audio.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/audio.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/audio.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/audio.o: src/receiver.h /usr/include/portaudio.h
src/audio.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/audio.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/audio.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/audio.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/audio.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/audio.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/audio.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/audio.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/audio.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/audio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/audio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/audio.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/audio.o: /usr/include/pulse/mainloop.h
src/audio.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/audio.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/audio.o: /usr/include/pulse/simple.h src/transmitter.h src/audio.h
src/audio.o: src/mode.h src/vfo.h src/message.h
src/band.o: /usr/include/stdio.h /usr/include/stdlib.h /usr/include/alloca.h
src/band.o: /usr/include/features.h /usr/include/features-time64.h
src/band.o: /usr/include/stdc-predef.h /usr/include/string.h
src/band.o: /usr/include/strings.h src/bandstack.h src/band.h src/filter.h
src/band.o: src/mode.h src/property.h src/mystring.h src/radio.h src/adc.h
src/band.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/band.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/band.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/band.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/band.o: src/receiver.h /usr/include/portaudio.h
src/band.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/band.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/band.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/band.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/band.o: /usr/include/time.h /usr/include/alsa/input.h
src/band.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/band.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/band.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/band.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/band.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/band.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/band.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/band.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/band.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/band.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/band.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/band.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/band.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/band.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/band.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/band.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/band.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/band.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/band.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/band.o: /usr/include/pulse/mainloop.h
src/band.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/band.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/band.o: /usr/include/pulse/simple.h src/transmitter.h src/vfo.h
src/band_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/band_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/band_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/band_menu.o: /usr/include/stdc-predef.h /usr/include/string.h
src/band_menu.o: /usr/include/strings.h src/new_menu.h src/band_menu.h
src/band_menu.o: src/band.h src/bandstack.h src/filter.h src/mode.h
src/band_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/band_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/band_menu.o: /usr/include/SoapySDR/Device.h
src/band_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/band_menu.o: /usr/include/SoapySDR/Constants.h
src/band_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/band_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/band_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/band_menu.o: /usr/include/assert.h /usr/include/poll.h
src/band_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/band_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/band_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/band_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/band_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/band_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/band_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/band_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/band_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/band_menu.o: /usr/include/alsa/seq_midi_event.h
src/band_menu.o: /usr/include/pulse/pulseaudio.h
src/band_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/band_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/band_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/band_menu.o: /usr/include/pulse/version.h
src/band_menu.o: /usr/include/pulse/mainloop-api.h
src/band_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/band_menu.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/band_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/band_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/band_menu.o: /usr/include/pulse/introspect.h
src/band_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/band_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/band_menu.o: /usr/include/pulse/utf8.h
src/band_menu.o: /usr/include/pulse/thread-mainloop.h
src/band_menu.o: /usr/include/pulse/mainloop.h
src/band_menu.o: /usr/include/pulse/mainloop-signal.h
src/band_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/band_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/band_menu.o: src/transmitter.h src/vfo.h src/client_server.h
src/bandstack_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/bandstack_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/bandstack_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/bandstack_menu.o: /usr/include/stdc-predef.h /usr/include/string.h
src/bandstack_menu.o: /usr/include/strings.h src/new_menu.h
src/bandstack_menu.o: src/bandstack_menu.h src/band.h src/bandstack.h
src/bandstack_menu.o: src/filter.h src/mode.h src/radio.h src/adc.h src/dac.h
src/bandstack_menu.o: src/discovered.h /usr/include/netinet/in.h
src/bandstack_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/bandstack_menu.o: /usr/include/SoapySDR/Config.h
src/bandstack_menu.o: /usr/include/SoapySDR/Types.h
src/bandstack_menu.o: /usr/include/SoapySDR/Constants.h
src/bandstack_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/bandstack_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/bandstack_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/bandstack_menu.o: /usr/include/assert.h /usr/include/poll.h
src/bandstack_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/bandstack_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/bandstack_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/bandstack_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/bandstack_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/bandstack_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/bandstack_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/bandstack_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/bandstack_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/bandstack_menu.o: /usr/include/alsa/seq_midi_event.h
src/bandstack_menu.o: /usr/include/pulse/pulseaudio.h
src/bandstack_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/bandstack_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/bandstack_menu.o: /usr/include/pulse/sample.h
src/bandstack_menu.o: /usr/include/pulse/gccmacro.h
src/bandstack_menu.o: /usr/include/pulse/version.h
src/bandstack_menu.o: /usr/include/pulse/mainloop-api.h
src/bandstack_menu.o: /usr/include/pulse/format.h
src/bandstack_menu.o: /usr/include/pulse/proplist.h
src/bandstack_menu.o: /usr/include/pulse/channelmap.h
src/bandstack_menu.o: /usr/include/pulse/context.h
src/bandstack_menu.o: /usr/include/pulse/operation.h
src/bandstack_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/bandstack_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/bandstack_menu.o: /usr/include/pulse/subscribe.h
src/bandstack_menu.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/bandstack_menu.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/bandstack_menu.o: /usr/include/pulse/thread-mainloop.h
src/bandstack_menu.o: /usr/include/pulse/mainloop.h
src/bandstack_menu.o: /usr/include/pulse/mainloop-signal.h
src/bandstack_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/bandstack_menu.o: /usr/include/pulse/rtclock.h
src/bandstack_menu.o: /usr/include/pulse/simple.h src/transmitter.h src/vfo.h
src/bootldrsim.o: /usr/include/stdio.h /usr/include/stdlib.h
src/bootldrsim.o: /usr/include/alloca.h /usr/include/features.h
src/bootldrsim.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/bootldrsim.o: /usr/include/unistd.h /usr/include/errno.h
src/bootldrsim.o: /usr/include/netinet/in.h /usr/include/endian.h
src/bootldrsim.o: /usr/include/arpa/inet.h /usr/include/netinet/if_ether.h
src/bootldrsim.o: /usr/include/linux/if_ether.h /usr/include/linux/types.h
src/bootldrsim.o: /usr/include/linux/posix_types.h
src/bootldrsim.o: /usr/include/linux/stddef.h /usr/include/net/ethernet.h
src/bootldrsim.o: /usr/include/stdint.h /usr/include/net/if_arp.h
src/bootldrsim.o: /usr/include/fcntl.h /usr/include/string.h
src/bootldrsim.o: /usr/include/strings.h
src/bootloader.o: /usr/include/stdio.h /usr/include/stdlib.h
src/bootloader.o: /usr/include/alloca.h /usr/include/features.h
src/bootloader.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/bootloader.o: /usr/include/unistd.h /usr/include/errno.h
src/bootloader.o: /usr/include/netinet/in.h /usr/include/endian.h
src/bootloader.o: /usr/include/arpa/inet.h /usr/include/netinet/if_ether.h
src/bootloader.o: /usr/include/linux/if_ether.h /usr/include/linux/types.h
src/bootloader.o: /usr/include/linux/posix_types.h
src/bootloader.o: /usr/include/linux/stddef.h /usr/include/net/ethernet.h
src/bootloader.o: /usr/include/stdint.h /usr/include/net/if_arp.h
src/bootloader.o: /usr/include/fcntl.h /usr/include/string.h
src/bootloader.o: /usr/include/strings.h
src/client_server.o: /usr/include/stdio.h /usr/include/stdlib.h
src/client_server.o: /usr/include/alloca.h /usr/include/features.h
src/client_server.o: /usr/include/features-time64.h
src/client_server.o: /usr/include/stdc-predef.h /usr/include/netinet/in.h
src/client_server.o: /usr/include/endian.h /usr/include/netinet/ip.h
src/client_server.o: /usr/include/net/if.h /usr/include/arpa/inet.h
src/client_server.o: /usr/include/netdb.h /usr/include/rpc/netdb.h
src/client_server.o: /usr/include/string.h /usr/include/strings.h
src/client_server.o: /usr/include/semaphore.h src/discovered.h
src/client_server.o: /usr/include/SoapySDR/Device.h
src/client_server.o: /usr/include/SoapySDR/Config.h
src/client_server.o: /usr/include/SoapySDR/Types.h
src/client_server.o: /usr/include/SoapySDR/Constants.h
src/client_server.o: /usr/include/SoapySDR/Errors.h src/adc.h src/dac.h
src/client_server.o: src/receiver.h /usr/include/portaudio.h
src/client_server.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/client_server.o: /usr/include/fcntl.h /usr/include/assert.h
src/client_server.o: /usr/include/poll.h /usr/include/errno.h
src/client_server.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/client_server.o: /usr/include/alsa/global.h /usr/include/time.h
src/client_server.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/client_server.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/client_server.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/client_server.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/client_server.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/client_server.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/client_server.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/client_server.o: /usr/include/alsa/seq_midi_event.h
src/client_server.o: /usr/include/pulse/pulseaudio.h
src/client_server.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/client_server.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/client_server.o: /usr/include/pulse/sample.h
src/client_server.o: /usr/include/pulse/gccmacro.h
src/client_server.o: /usr/include/pulse/version.h
src/client_server.o: /usr/include/pulse/mainloop-api.h
src/client_server.o: /usr/include/pulse/format.h
src/client_server.o: /usr/include/pulse/proplist.h
src/client_server.o: /usr/include/pulse/channelmap.h
src/client_server.o: /usr/include/pulse/context.h
src/client_server.o: /usr/include/pulse/operation.h
src/client_server.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/client_server.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/client_server.o: /usr/include/pulse/subscribe.h
src/client_server.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/client_server.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/client_server.o: /usr/include/pulse/thread-mainloop.h
src/client_server.o: /usr/include/pulse/mainloop.h
src/client_server.o: /usr/include/pulse/mainloop-signal.h
src/client_server.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/client_server.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/client_server.o: src/transmitter.h src/radio.h src/main.h src/vfo.h
src/client_server.o: src/mode.h src/client_server.h src/ext.h src/audio.h
src/client_server.o: src/zoompan.h src/noise_menu.h src/radio_menu.h
src/client_server.o: src/sliders.h src/actions.h src/message.h src/mystring.h
src/configure.o: /usr/include/math.h /usr/include/unistd.h
src/configure.o: /usr/include/features.h /usr/include/features-time64.h
src/configure.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/configure.o: /usr/include/alloca.h /usr/include/string.h
src/configure.o: /usr/include/strings.h /usr/include/semaphore.h
src/configure.o: /usr/include/netinet/in.h /usr/include/endian.h
src/configure.o: /usr/include/arpa/inet.h src/radio.h src/adc.h src/dac.h
src/configure.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/configure.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/configure.o: /usr/include/SoapySDR/Constants.h
src/configure.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/configure.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/configure.o: /usr/include/stdio.h /usr/include/fcntl.h
src/configure.o: /usr/include/assert.h /usr/include/poll.h
src/configure.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/configure.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/configure.o: /usr/include/time.h /usr/include/alsa/input.h
src/configure.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/configure.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/configure.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/configure.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/configure.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/configure.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/configure.o: /usr/include/alsa/seqmid.h
src/configure.o: /usr/include/alsa/seq_midi_event.h
src/configure.o: /usr/include/pulse/pulseaudio.h
src/configure.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/configure.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/configure.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/configure.o: /usr/include/pulse/version.h
src/configure.o: /usr/include/pulse/mainloop-api.h
src/configure.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/configure.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/configure.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/configure.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/configure.o: /usr/include/pulse/introspect.h
src/configure.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/configure.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/configure.o: /usr/include/pulse/utf8.h
src/configure.o: /usr/include/pulse/thread-mainloop.h
src/configure.o: /usr/include/pulse/mainloop.h
src/configure.o: /usr/include/pulse/mainloop-signal.h
src/configure.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/configure.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/configure.o: src/transmitter.h src/main.h src/channel.h src/actions.h
src/configure.o: src/gpio.h src/i2c.h src/message.h
src/css.o: src/css.h src/message.h
src/cw_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/cw_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/cw_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/cw_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/cw_menu.o: /usr/include/string.h /usr/include/strings.h src/new_menu.h
src/cw_menu.o: src/pa_menu.h src/band.h src/bandstack.h src/filter.h
src/cw_menu.o: src/mode.h src/radio.h src/adc.h src/dac.h src/discovered.h
src/cw_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/cw_menu.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/cw_menu.o: /usr/include/SoapySDR/Types.h
src/cw_menu.o: /usr/include/SoapySDR/Constants.h
src/cw_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/cw_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/cw_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/cw_menu.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/cw_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/cw_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/cw_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/cw_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/cw_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/cw_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/cw_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/cw_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/cw_menu.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/cw_menu.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/cw_menu.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/cw_menu.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/cw_menu.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/cw_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/cw_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/cw_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/cw_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/cw_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/cw_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/cw_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/cw_menu.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/cw_menu.o: /usr/include/pulse/mainloop.h
src/cw_menu.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/cw_menu.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/cw_menu.o: /usr/include/pulse/simple.h src/transmitter.h
src/cw_menu.o: src/new_protocol.h src/MacOS.h src/old_protocol.h src/iambic.h
src/cw_menu.o: src/ext.h src/client_server.h
src/cwdaemon.o: /usr/include/stdlib.h /usr/include/alloca.h
src/cwdaemon.o: /usr/include/features.h /usr/include/features-time64.h
src/cwdaemon.o: /usr/include/stdc-predef.h src/cwdaemon.h
src/cwdaemon.o: /usr/include/string.h /usr/include/strings.h
src/cwdaemon.o: /usr/include/unistd.h /usr/include/arpa/inet.h
src/cwdaemon.o: /usr/include/netinet/in.h /usr/include/endian.h
src/cwdaemon.o: /usr/include/fcntl.h /usr/include/errno.h src/band.h
src/cwdaemon.o: src/bandstack.h src/channel.h src/discovered.h
src/cwdaemon.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/cwdaemon.o: /usr/include/SoapySDR/Types.h
src/cwdaemon.o: /usr/include/SoapySDR/Constants.h
src/cwdaemon.o: /usr/include/SoapySDR/Errors.h src/mode.h src/filter.h
src/cwdaemon.o: src/receiver.h /usr/include/portaudio.h
src/cwdaemon.o: /usr/include/alsa/asoundlib.h /usr/include/stdio.h
src/cwdaemon.o: /usr/include/assert.h /usr/include/poll.h
src/cwdaemon.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/cwdaemon.o: /usr/include/alsa/global.h /usr/include/time.h
src/cwdaemon.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/cwdaemon.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/cwdaemon.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/cwdaemon.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/cwdaemon.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/cwdaemon.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/cwdaemon.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/cwdaemon.o: /usr/include/alsa/seq_midi_event.h
src/cwdaemon.o: /usr/include/pulse/pulseaudio.h
src/cwdaemon.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/cwdaemon.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/cwdaemon.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/cwdaemon.o: /usr/include/pulse/version.h
src/cwdaemon.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/cwdaemon.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/cwdaemon.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/cwdaemon.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/cwdaemon.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/cwdaemon.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/cwdaemon.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/cwdaemon.o: /usr/include/pulse/utf8.h
src/cwdaemon.o: /usr/include/pulse/thread-mainloop.h
src/cwdaemon.o: /usr/include/pulse/mainloop.h
src/cwdaemon.o: /usr/include/pulse/mainloop-signal.h
src/cwdaemon.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/cwdaemon.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/cwdaemon.o: src/transmitter.h src/adc.h src/dac.h src/radio.h src/main.h
src/cwdaemon.o: src/audio.h /usr/include/signal.h src/vfo.h
src/discovered.o: src/discovered.h /usr/include/netinet/in.h
src/discovered.o: /usr/include/features.h /usr/include/features-time64.h
src/discovered.o: /usr/include/stdc-predef.h /usr/include/endian.h
src/discovered.o: /usr/include/SoapySDR/Device.h
src/discovered.o: /usr/include/SoapySDR/Config.h
src/discovered.o: /usr/include/SoapySDR/Types.h
src/discovered.o: /usr/include/SoapySDR/Constants.h
src/discovered.o: /usr/include/SoapySDR/Errors.h
src/discovery.o: /usr/include/math.h /usr/include/unistd.h
src/discovery.o: /usr/include/features.h /usr/include/features-time64.h
src/discovery.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/discovery.o: /usr/include/alloca.h /usr/include/string.h
src/discovery.o: /usr/include/strings.h /usr/include/semaphore.h
src/discovery.o: /usr/include/netinet/in.h /usr/include/endian.h
src/discovery.o: /usr/include/arpa/inet.h src/discovered.h
src/discovery.o: /usr/include/SoapySDR/Device.h
src/discovery.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/discovery.o: /usr/include/SoapySDR/Constants.h
src/discovery.o: /usr/include/SoapySDR/Errors.h src/old_discovery.h
src/discovery.o: src/new_discovery.h src/soapy_discovery.h src/main.h
src/discovery.o: src/radio.h src/adc.h src/dac.h src/receiver.h
src/discovery.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/discovery.o: /usr/include/stdio.h /usr/include/fcntl.h
src/discovery.o: /usr/include/assert.h /usr/include/poll.h
src/discovery.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/discovery.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/discovery.o: /usr/include/time.h /usr/include/alsa/input.h
src/discovery.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/discovery.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/discovery.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/discovery.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/discovery.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/discovery.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/discovery.o: /usr/include/alsa/seqmid.h
src/discovery.o: /usr/include/alsa/seq_midi_event.h
src/discovery.o: /usr/include/pulse/pulseaudio.h
src/discovery.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/discovery.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/discovery.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/discovery.o: /usr/include/pulse/version.h
src/discovery.o: /usr/include/pulse/mainloop-api.h
src/discovery.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/discovery.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/discovery.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/discovery.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/discovery.o: /usr/include/pulse/introspect.h
src/discovery.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/discovery.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/discovery.o: /usr/include/pulse/utf8.h
src/discovery.o: /usr/include/pulse/thread-mainloop.h
src/discovery.o: /usr/include/pulse/mainloop.h
src/discovery.o: /usr/include/pulse/mainloop-signal.h
src/discovery.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/discovery.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/discovery.o: src/transmitter.h src/ozyio.h src/stemlab_discovery.h
src/discovery.o: src/ext.h src/client_server.h src/actions.h src/gpio.h
src/discovery.o: src/configure.h src/protocols.h src/property.h
src/discovery.o: src/mystring.h src/message.h src/saturnmain.h
src/discovery.o: src/saturnregisters.h
src/display_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/display_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/display_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/display_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/display_menu.o: /usr/include/string.h /usr/include/strings.h src/main.h
src/display_menu.o: src/new_menu.h src/display_menu.h src/radio.h src/adc.h
src/display_menu.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/display_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/display_menu.o: /usr/include/SoapySDR/Config.h
src/display_menu.o: /usr/include/SoapySDR/Types.h
src/display_menu.o: /usr/include/SoapySDR/Constants.h
src/display_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/display_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/display_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/display_menu.o: /usr/include/assert.h /usr/include/poll.h
src/display_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/display_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/display_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/display_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/display_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/display_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/display_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/display_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/display_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/display_menu.o: /usr/include/alsa/seq_midi_event.h
src/display_menu.o: /usr/include/pulse/pulseaudio.h
src/display_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/display_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/display_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/display_menu.o: /usr/include/pulse/version.h
src/display_menu.o: /usr/include/pulse/mainloop-api.h
src/display_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/display_menu.o: /usr/include/pulse/channelmap.h
src/display_menu.o: /usr/include/pulse/context.h
src/display_menu.o: /usr/include/pulse/operation.h
src/display_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/display_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/display_menu.o: /usr/include/pulse/subscribe.h
src/display_menu.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/display_menu.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/display_menu.o: /usr/include/pulse/thread-mainloop.h
src/display_menu.o: /usr/include/pulse/mainloop.h
src/display_menu.o: /usr/include/pulse/mainloop-signal.h
src/display_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/display_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/display_menu.o: src/transmitter.h
src/diversity_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/diversity_menu.o: /usr/include/features-time64.h
src/diversity_menu.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/diversity_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/diversity_menu.o: /usr/include/string.h /usr/include/strings.h
src/diversity_menu.o: /usr/include/pthread.h /usr/include/sched.h
src/diversity_menu.o: /usr/include/time.h src/new_menu.h src/diversity_menu.h
src/diversity_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/diversity_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/diversity_menu.o: /usr/include/SoapySDR/Device.h
src/diversity_menu.o: /usr/include/SoapySDR/Config.h
src/diversity_menu.o: /usr/include/SoapySDR/Types.h
src/diversity_menu.o: /usr/include/SoapySDR/Constants.h
src/diversity_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/diversity_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/diversity_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/diversity_menu.o: /usr/include/assert.h /usr/include/poll.h
src/diversity_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/diversity_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/diversity_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/diversity_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/diversity_menu.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/diversity_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/diversity_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/diversity_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/diversity_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/diversity_menu.o: /usr/include/alsa/seq_midi_event.h
src/diversity_menu.o: /usr/include/pulse/pulseaudio.h
src/diversity_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/diversity_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/diversity_menu.o: /usr/include/pulse/sample.h
src/diversity_menu.o: /usr/include/pulse/gccmacro.h
src/diversity_menu.o: /usr/include/pulse/version.h
src/diversity_menu.o: /usr/include/pulse/mainloop-api.h
src/diversity_menu.o: /usr/include/pulse/format.h
src/diversity_menu.o: /usr/include/pulse/proplist.h
src/diversity_menu.o: /usr/include/pulse/channelmap.h
src/diversity_menu.o: /usr/include/pulse/context.h
src/diversity_menu.o: /usr/include/pulse/operation.h
src/diversity_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/diversity_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/diversity_menu.o: /usr/include/pulse/subscribe.h
src/diversity_menu.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/diversity_menu.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/diversity_menu.o: /usr/include/pulse/thread-mainloop.h
src/diversity_menu.o: /usr/include/pulse/mainloop.h
src/diversity_menu.o: /usr/include/pulse/mainloop-signal.h
src/diversity_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/diversity_menu.o: /usr/include/pulse/rtclock.h
src/diversity_menu.o: /usr/include/pulse/simple.h src/transmitter.h
src/diversity_menu.o: src/new_protocol.h src/MacOS.h src/old_protocol.h
src/diversity_menu.o: src/sliders.h src/actions.h src/ext.h
src/diversity_menu.o: src/client_server.h /usr/include/math.h
src/encoder_menu.o: /usr/include/stdio.h /usr/include/string.h
src/encoder_menu.o: /usr/include/strings.h /usr/include/features.h
src/encoder_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/encoder_menu.o: src/main.h src/new_menu.h src/agc_menu.h src/agc.h
src/encoder_menu.o: src/band.h src/bandstack.h src/channel.h src/radio.h
src/encoder_menu.o: src/adc.h src/dac.h src/discovered.h
src/encoder_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/encoder_menu.o: /usr/include/SoapySDR/Device.h
src/encoder_menu.o: /usr/include/SoapySDR/Config.h
src/encoder_menu.o: /usr/include/SoapySDR/Types.h
src/encoder_menu.o: /usr/include/SoapySDR/Constants.h
src/encoder_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/encoder_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/encoder_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/encoder_menu.o: /usr/include/alloca.h /usr/include/fcntl.h
src/encoder_menu.o: /usr/include/assert.h /usr/include/poll.h
src/encoder_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/encoder_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/encoder_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/encoder_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/encoder_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/encoder_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/encoder_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/encoder_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/encoder_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/encoder_menu.o: /usr/include/alsa/seqmid.h
src/encoder_menu.o: /usr/include/alsa/seq_midi_event.h
src/encoder_menu.o: /usr/include/pulse/pulseaudio.h
src/encoder_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/encoder_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/encoder_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/encoder_menu.o: /usr/include/pulse/version.h
src/encoder_menu.o: /usr/include/pulse/mainloop-api.h
src/encoder_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/encoder_menu.o: /usr/include/pulse/channelmap.h
src/encoder_menu.o: /usr/include/pulse/context.h
src/encoder_menu.o: /usr/include/pulse/operation.h
src/encoder_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/encoder_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/encoder_menu.o: /usr/include/pulse/subscribe.h
src/encoder_menu.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/encoder_menu.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/encoder_menu.o: /usr/include/pulse/thread-mainloop.h
src/encoder_menu.o: /usr/include/pulse/mainloop.h
src/encoder_menu.o: /usr/include/pulse/mainloop-signal.h
src/encoder_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/encoder_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/encoder_menu.o: src/transmitter.h src/vfo.h src/mode.h src/actions.h
src/encoder_menu.o: src/action_dialog.h src/gpio.h src/i2c.h
src/equalizer_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/equalizer_menu.o: /usr/include/features-time64.h
src/equalizer_menu.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/equalizer_menu.o: /usr/include/stdint.h /usr/include/stdlib.h
src/equalizer_menu.o: /usr/include/alloca.h /usr/include/string.h
src/equalizer_menu.o: /usr/include/strings.h src/new_menu.h
src/equalizer_menu.o: src/equalizer_menu.h src/radio.h src/adc.h src/dac.h
src/equalizer_menu.o: src/discovered.h /usr/include/netinet/in.h
src/equalizer_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/equalizer_menu.o: /usr/include/SoapySDR/Config.h
src/equalizer_menu.o: /usr/include/SoapySDR/Types.h
src/equalizer_menu.o: /usr/include/SoapySDR/Constants.h
src/equalizer_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/equalizer_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/equalizer_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/equalizer_menu.o: /usr/include/assert.h /usr/include/poll.h
src/equalizer_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/equalizer_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/equalizer_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/equalizer_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/equalizer_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/equalizer_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/equalizer_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/equalizer_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/equalizer_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/equalizer_menu.o: /usr/include/alsa/seq_midi_event.h
src/equalizer_menu.o: /usr/include/pulse/pulseaudio.h
src/equalizer_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/equalizer_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/equalizer_menu.o: /usr/include/pulse/sample.h
src/equalizer_menu.o: /usr/include/pulse/gccmacro.h
src/equalizer_menu.o: /usr/include/pulse/version.h
src/equalizer_menu.o: /usr/include/pulse/mainloop-api.h
src/equalizer_menu.o: /usr/include/pulse/format.h
src/equalizer_menu.o: /usr/include/pulse/proplist.h
src/equalizer_menu.o: /usr/include/pulse/channelmap.h
src/equalizer_menu.o: /usr/include/pulse/context.h
src/equalizer_menu.o: /usr/include/pulse/operation.h
src/equalizer_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/equalizer_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/equalizer_menu.o: /usr/include/pulse/subscribe.h
src/equalizer_menu.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/equalizer_menu.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/equalizer_menu.o: /usr/include/pulse/thread-mainloop.h
src/equalizer_menu.o: /usr/include/pulse/mainloop.h
src/equalizer_menu.o: /usr/include/pulse/mainloop-signal.h
src/equalizer_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/equalizer_menu.o: /usr/include/pulse/rtclock.h
src/equalizer_menu.o: /usr/include/pulse/simple.h src/transmitter.h src/ext.h
src/equalizer_menu.o: src/client_server.h src/vfo.h src/mode.h src/message.h
src/exit_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/exit_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/exit_menu.o: /usr/include/stdio.h /usr/include/string.h
src/exit_menu.o: /usr/include/strings.h src/main.h src/new_menu.h
src/exit_menu.o: src/exit_menu.h src/discovery.h src/radio.h src/adc.h
src/exit_menu.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/exit_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/exit_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/exit_menu.o: /usr/include/SoapySDR/Constants.h
src/exit_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/exit_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/exit_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/exit_menu.o: /usr/include/alloca.h /usr/include/fcntl.h
src/exit_menu.o: /usr/include/assert.h /usr/include/poll.h
src/exit_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/exit_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/exit_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/exit_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/exit_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/exit_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/exit_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/exit_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/exit_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/exit_menu.o: /usr/include/alsa/seqmid.h
src/exit_menu.o: /usr/include/alsa/seq_midi_event.h
src/exit_menu.o: /usr/include/pulse/pulseaudio.h
src/exit_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/exit_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/exit_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/exit_menu.o: /usr/include/pulse/version.h
src/exit_menu.o: /usr/include/pulse/mainloop-api.h
src/exit_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/exit_menu.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/exit_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/exit_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/exit_menu.o: /usr/include/pulse/introspect.h
src/exit_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/exit_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/exit_menu.o: /usr/include/pulse/utf8.h
src/exit_menu.o: /usr/include/pulse/thread-mainloop.h
src/exit_menu.o: /usr/include/pulse/mainloop.h
src/exit_menu.o: /usr/include/pulse/mainloop-signal.h
src/exit_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/exit_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/exit_menu.o: src/transmitter.h src/new_protocol.h src/MacOS.h
src/exit_menu.o: src/old_protocol.h src/soapy_protocol.h src/actions.h
src/exit_menu.o: src/gpio.h src/message.h src/saturnmain.h
src/exit_menu.o: src/saturnregisters.h
src/ext.o: /usr/include/stdint.h /usr/include/stdlib.h /usr/include/alloca.h
src/ext.o: /usr/include/features.h /usr/include/features-time64.h
src/ext.o: /usr/include/stdc-predef.h /usr/include/stdio.h src/main.h
src/ext.o: src/discovery.h src/receiver.h /usr/include/portaudio.h
src/ext.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/ext.o: /usr/include/string.h /usr/include/strings.h /usr/include/fcntl.h
src/ext.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/ext.o: /usr/include/endian.h /usr/include/alsa/asoundef.h
src/ext.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/ext.o: /usr/include/time.h /usr/include/alsa/input.h
src/ext.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/ext.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/ext.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/ext.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/ext.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/ext.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/ext.o: /usr/include/alsa/seq_midi_event.h /usr/include/pulse/pulseaudio.h
src/ext.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/ext.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/ext.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/ext.o: /usr/include/pulse/version.h /usr/include/pulse/mainloop-api.h
src/ext.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/ext.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/ext.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/ext.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/ext.o: /usr/include/pulse/introspect.h /usr/include/pulse/subscribe.h
src/ext.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/ext.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/ext.o: /usr/include/pulse/thread-mainloop.h /usr/include/pulse/mainloop.h
src/ext.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/ext.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/ext.o: /usr/include/pulse/simple.h src/sliders.h src/transmitter.h
src/ext.o: src/actions.h src/toolbar.h src/gpio.h src/vfo.h src/mode.h
src/ext.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/ext.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/ext.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/ext.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/ext.o: src/radio_menu.h src/new_menu.h src/noise_menu.h src/ext.h
src/ext.o: src/client_server.h src/zoompan.h src/equalizer_menu.h
src/fft_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/fft_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/fft_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/fft_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/fft_menu.o: /usr/include/string.h /usr/include/strings.h src/new_menu.h
src/fft_menu.o: src/fft_menu.h src/radio.h src/adc.h src/dac.h
src/fft_menu.o: src/discovered.h /usr/include/netinet/in.h
src/fft_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/fft_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/fft_menu.o: /usr/include/SoapySDR/Constants.h
src/fft_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/fft_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/fft_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/fft_menu.o: /usr/include/assert.h /usr/include/poll.h
src/fft_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/fft_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/fft_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/fft_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/fft_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/fft_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/fft_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/fft_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/fft_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/fft_menu.o: /usr/include/alsa/seq_midi_event.h
src/fft_menu.o: /usr/include/pulse/pulseaudio.h
src/fft_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/fft_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/fft_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/fft_menu.o: /usr/include/pulse/version.h
src/fft_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/fft_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/fft_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/fft_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/fft_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/fft_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/fft_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/fft_menu.o: /usr/include/pulse/utf8.h
src/fft_menu.o: /usr/include/pulse/thread-mainloop.h
src/fft_menu.o: /usr/include/pulse/mainloop.h
src/fft_menu.o: /usr/include/pulse/mainloop-signal.h
src/fft_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/fft_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/fft_menu.o: src/transmitter.h src/message.h
src/filter.o: /usr/include/stdio.h /usr/include/stdlib.h
src/filter.o: /usr/include/alloca.h /usr/include/features.h
src/filter.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/filter.o: src/sliders.h src/receiver.h /usr/include/portaudio.h
src/filter.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/filter.o: /usr/include/string.h /usr/include/strings.h
src/filter.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/filter.o: /usr/include/errno.h /usr/include/endian.h
src/filter.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/filter.o: /usr/include/alsa/global.h /usr/include/time.h
src/filter.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/filter.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/filter.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/filter.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/filter.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/filter.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/filter.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/filter.o: /usr/include/alsa/seq_midi_event.h
src/filter.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/filter.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/filter.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/filter.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/filter.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/filter.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/filter.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/filter.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/filter.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/filter.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/filter.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/filter.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/filter.o: /usr/include/pulse/mainloop.h
src/filter.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/filter.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/filter.o: /usr/include/pulse/simple.h src/transmitter.h src/actions.h
src/filter.o: src/filter.h src/mode.h src/vfo.h src/radio.h src/adc.h
src/filter.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/filter.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/filter.o: /usr/include/SoapySDR/Types.h /usr/include/SoapySDR/Constants.h
src/filter.o: /usr/include/SoapySDR/Errors.h src/property.h src/mystring.h
src/filter.o: src/message.h src/ext.h src/client_server.h
src/filter_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/filter_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/filter_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/filter_menu.o: /usr/include/stdc-predef.h /usr/include/string.h
src/filter_menu.o: /usr/include/strings.h src/new_menu.h src/filter_menu.h
src/filter_menu.o: src/band.h src/bandstack.h src/filter.h src/mode.h
src/filter_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/filter_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/filter_menu.o: /usr/include/SoapySDR/Device.h
src/filter_menu.o: /usr/include/SoapySDR/Config.h
src/filter_menu.o: /usr/include/SoapySDR/Types.h
src/filter_menu.o: /usr/include/SoapySDR/Constants.h
src/filter_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/filter_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/filter_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/filter_menu.o: /usr/include/assert.h /usr/include/poll.h
src/filter_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/filter_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/filter_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/filter_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/filter_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/filter_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/filter_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/filter_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/filter_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/filter_menu.o: /usr/include/alsa/seq_midi_event.h
src/filter_menu.o: /usr/include/pulse/pulseaudio.h
src/filter_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/filter_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/filter_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/filter_menu.o: /usr/include/pulse/version.h
src/filter_menu.o: /usr/include/pulse/mainloop-api.h
src/filter_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/filter_menu.o: /usr/include/pulse/channelmap.h
src/filter_menu.o: /usr/include/pulse/context.h
src/filter_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/filter_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/filter_menu.o: /usr/include/pulse/introspect.h
src/filter_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/filter_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/filter_menu.o: /usr/include/pulse/utf8.h
src/filter_menu.o: /usr/include/pulse/thread-mainloop.h
src/filter_menu.o: /usr/include/pulse/mainloop.h
src/filter_menu.o: /usr/include/pulse/mainloop-signal.h
src/filter_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/filter_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/filter_menu.o: src/transmitter.h src/vfo.h src/ext.h src/client_server.h
src/filter_menu.o: src/message.h
src/gpio.o: /usr/include/stdio.h /usr/include/stdlib.h /usr/include/alloca.h
src/gpio.o: /usr/include/features.h /usr/include/features-time64.h
src/gpio.o: /usr/include/stdc-predef.h /usr/include/string.h
src/gpio.o: /usr/include/strings.h /usr/include/errno.h /usr/include/unistd.h
src/gpio.o: /usr/include/stdint.h /usr/include/fcntl.h /usr/include/poll.h
src/gpio.o: /usr/include/sched.h /usr/include/linux/i2c-dev.h
src/gpio.o: /usr/include/linux/types.h /usr/include/linux/posix_types.h
src/gpio.o: /usr/include/linux/stddef.h src/band.h src/bandstack.h
src/gpio.o: src/channel.h src/discovered.h /usr/include/netinet/in.h
src/gpio.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/gpio.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/gpio.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/gpio.o: src/mode.h src/filter.h src/toolbar.h src/gpio.h src/radio.h
src/gpio.o: src/adc.h src/dac.h src/receiver.h /usr/include/portaudio.h
src/gpio.o: /usr/include/alsa/asoundlib.h /usr/include/assert.h
src/gpio.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/gpio.o: /usr/include/alsa/global.h /usr/include/time.h
src/gpio.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/gpio.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/gpio.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/gpio.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/gpio.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/gpio.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/gpio.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/gpio.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/gpio.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/gpio.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/gpio.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/gpio.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/gpio.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/gpio.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/gpio.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/gpio.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/gpio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/gpio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/gpio.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/gpio.o: /usr/include/pulse/mainloop.h
src/gpio.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/gpio.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/gpio.o: /usr/include/pulse/simple.h src/transmitter.h src/main.h
src/gpio.o: src/property.h src/mystring.h src/vfo.h src/new_menu.h
src/gpio.o: src/encoder_menu.h src/diversity_menu.h src/actions.h src/i2c.h
src/gpio.o: src/ext.h src/client_server.h src/sliders.h src/new_protocol.h
src/gpio.o: src/MacOS.h /usr/include/semaphore.h src/zoompan.h src/iambic.h
src/gpio.o: src/message.h
src/hpsdrsim.o: /usr/include/stdio.h /usr/include/errno.h
src/hpsdrsim.o: /usr/include/features.h /usr/include/features-time64.h
src/hpsdrsim.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/hpsdrsim.o: /usr/include/alloca.h /usr/include/limits.h
src/hpsdrsim.o: /usr/include/stdint.h /usr/include/string.h
src/hpsdrsim.o: /usr/include/strings.h /usr/include/unistd.h
src/hpsdrsim.o: /usr/include/fcntl.h /usr/include/math.h
src/hpsdrsim.o: /usr/include/pthread.h /usr/include/sched.h
src/hpsdrsim.o: /usr/include/time.h /usr/include/termios.h
src/hpsdrsim.o: /usr/include/netinet/in.h /usr/include/endian.h
src/hpsdrsim.o: /usr/include/netinet/tcp.h src/MacOS.h
src/hpsdrsim.o: /usr/include/semaphore.h src/hpsdrsim.h
src/i2c.o: /usr/include/string.h /usr/include/strings.h
src/i2c.o: /usr/include/features.h /usr/include/features-time64.h
src/i2c.o: /usr/include/stdc-predef.h /usr/include/unistd.h
src/i2c.o: /usr/include/errno.h /usr/include/stdio.h /usr/include/stdlib.h
src/i2c.o: /usr/include/alloca.h /usr/include/linux/i2c-dev.h
src/i2c.o: /usr/include/linux/types.h /usr/include/linux/posix_types.h
src/i2c.o: /usr/include/linux/stddef.h /usr/include/fcntl.h src/i2c.h
src/i2c.o: src/actions.h src/gpio.h src/band.h src/bandstack.h
src/i2c.o: src/band_menu.h src/radio.h src/adc.h src/dac.h src/discovered.h
src/i2c.o: /usr/include/netinet/in.h /usr/include/endian.h
src/i2c.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/i2c.o: /usr/include/SoapySDR/Types.h /usr/include/SoapySDR/Constants.h
src/i2c.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/i2c.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/i2c.o: /usr/include/assert.h /usr/include/poll.h
src/i2c.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/i2c.o: /usr/include/alsa/global.h /usr/include/time.h
src/i2c.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/i2c.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/i2c.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/i2c.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/i2c.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/i2c.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/i2c.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/i2c.o: /usr/include/alsa/seq_midi_event.h /usr/include/pulse/pulseaudio.h
src/i2c.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/i2c.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/i2c.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/i2c.o: /usr/include/pulse/version.h /usr/include/pulse/mainloop-api.h
src/i2c.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/i2c.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/i2c.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/i2c.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/i2c.o: /usr/include/pulse/introspect.h /usr/include/pulse/subscribe.h
src/i2c.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/i2c.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/i2c.o: /usr/include/pulse/thread-mainloop.h /usr/include/pulse/mainloop.h
src/i2c.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/i2c.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/i2c.o: /usr/include/pulse/simple.h src/transmitter.h src/toolbar.h
src/i2c.o: src/vfo.h src/mode.h src/ext.h src/client_server.h src/message.h
src/iambic.o: /usr/include/stdio.h /usr/include/stdlib.h
src/iambic.o: /usr/include/alloca.h /usr/include/features.h
src/iambic.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/iambic.o: /usr/include/string.h /usr/include/strings.h
src/iambic.o: /usr/include/errno.h /usr/include/unistd.h
src/iambic.o: /usr/include/stdint.h /usr/include/fcntl.h /usr/include/poll.h
src/iambic.o: /usr/include/sched.h /usr/include/pthread.h /usr/include/time.h
src/iambic.o: /usr/include/semaphore.h src/gpio.h src/radio.h src/adc.h
src/iambic.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/iambic.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/iambic.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/iambic.o: /usr/include/SoapySDR/Constants.h
src/iambic.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/iambic.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/iambic.o: /usr/include/assert.h /usr/include/alsa/asoundef.h
src/iambic.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/iambic.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/iambic.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/iambic.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/iambic.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/iambic.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/iambic.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/iambic.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/iambic.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/iambic.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/iambic.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/iambic.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/iambic.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/iambic.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/iambic.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/iambic.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/iambic.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/iambic.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/iambic.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/iambic.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/iambic.o: /usr/include/pulse/mainloop.h
src/iambic.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/iambic.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/iambic.o: /usr/include/pulse/simple.h src/transmitter.h
src/iambic.o: src/new_protocol.h src/MacOS.h src/iambic.h src/ext.h
src/iambic.o: src/client_server.h src/mode.h src/vfo.h src/message.h
src/led.o: src/message.h
src/mac_midi.o: src/discovered.h /usr/include/netinet/in.h
src/mac_midi.o: /usr/include/features.h /usr/include/features-time64.h
src/mac_midi.o: /usr/include/stdc-predef.h /usr/include/endian.h
src/mac_midi.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/mac_midi.o: /usr/include/SoapySDR/Types.h
src/mac_midi.o: /usr/include/SoapySDR/Constants.h
src/mac_midi.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/mac_midi.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/mac_midi.o: /usr/include/unistd.h /usr/include/stdio.h
src/mac_midi.o: /usr/include/stdlib.h /usr/include/alloca.h
src/mac_midi.o: /usr/include/string.h /usr/include/strings.h
src/mac_midi.o: /usr/include/fcntl.h /usr/include/assert.h
src/mac_midi.o: /usr/include/poll.h /usr/include/errno.h
src/mac_midi.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/mac_midi.o: /usr/include/alsa/global.h /usr/include/time.h
src/mac_midi.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/mac_midi.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/mac_midi.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/mac_midi.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/mac_midi.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/mac_midi.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/mac_midi.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/mac_midi.o: /usr/include/alsa/seq_midi_event.h
src/mac_midi.o: /usr/include/pulse/pulseaudio.h
src/mac_midi.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/mac_midi.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/mac_midi.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/mac_midi.o: /usr/include/pulse/version.h
src/mac_midi.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/mac_midi.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/mac_midi.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/mac_midi.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/mac_midi.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/mac_midi.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/mac_midi.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/mac_midi.o: /usr/include/pulse/utf8.h
src/mac_midi.o: /usr/include/pulse/thread-mainloop.h
src/mac_midi.o: /usr/include/pulse/mainloop.h
src/mac_midi.o: /usr/include/pulse/mainloop-signal.h
src/mac_midi.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/mac_midi.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/mac_midi.o: src/transmitter.h src/adc.h src/dac.h src/radio.h
src/mac_midi.o: src/actions.h src/midi.h src/midi_menu.h src/alsa_midi.h
src/mac_midi.o: src/message.h
src/main.o: /usr/include/math.h /usr/include/unistd.h /usr/include/features.h
src/main.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/main.o: /usr/include/stdlib.h /usr/include/alloca.h /usr/include/string.h
src/main.o: /usr/include/strings.h /usr/include/semaphore.h
src/main.o: /usr/include/netinet/in.h /usr/include/endian.h
src/main.o: /usr/include/arpa/inet.h src/appearance.h src/audio.h
src/main.o: src/receiver.h /usr/include/portaudio.h
src/main.o: /usr/include/alsa/asoundlib.h /usr/include/stdio.h
src/main.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/main.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/main.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/main.o: /usr/include/time.h /usr/include/alsa/input.h
src/main.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/main.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/main.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/main.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/main.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/main.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/main.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/main.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/main.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/main.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/main.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/main.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/main.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/main.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/main.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/main.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/main.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/main.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/main.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/main.o: /usr/include/pulse/mainloop.h
src/main.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/main.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/main.o: /usr/include/pulse/simple.h src/band.h src/bandstack.h src/main.h
src/main.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/main.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/main.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/main.o: src/configure.h src/actions.h src/gpio.h src/new_menu.h
src/main.o: src/radio.h src/adc.h src/dac.h src/transmitter.h src/version.h
src/main.o: src/discovery.h src/new_protocol.h src/MacOS.h src/old_protocol.h
src/main.o: src/soapy_protocol.h src/ext.h src/client_server.h src/vfo.h
src/main.o: src/mode.h src/css.h src/exit_menu.h src/message.h src/mystring.h
src/main.o: src/startup.h
src/message.o: /usr/include/errno.h /usr/include/features.h
src/message.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/meter.o: /usr/include/string.h /usr/include/strings.h
src/meter.o: /usr/include/features.h /usr/include/features-time64.h
src/meter.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/meter.o: /usr/include/alloca.h /usr/include/unistd.h /usr/include/math.h
src/meter.o: src/appearance.h src/band.h src/bandstack.h src/receiver.h
src/meter.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/meter.o: /usr/include/stdio.h /usr/include/fcntl.h /usr/include/assert.h
src/meter.o: /usr/include/poll.h /usr/include/errno.h /usr/include/endian.h
src/meter.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/meter.o: /usr/include/alsa/global.h /usr/include/time.h
src/meter.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/meter.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/meter.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/meter.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/meter.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/meter.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/meter.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/meter.o: /usr/include/alsa/seq_midi_event.h
src/meter.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/meter.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/meter.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/meter.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/meter.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/meter.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/meter.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/meter.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/meter.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/meter.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/meter.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/meter.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/meter.o: /usr/include/pulse/mainloop.h
src/meter.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/meter.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/meter.o: /usr/include/pulse/simple.h src/meter.h src/radio.h src/adc.h
src/meter.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/meter.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/meter.o: /usr/include/SoapySDR/Types.h /usr/include/SoapySDR/Constants.h
src/meter.o: /usr/include/SoapySDR/Errors.h src/transmitter.h src/version.h
src/meter.o: src/mode.h src/vox.h src/new_menu.h src/vfo.h src/message.h
src/meter_menu.o: /usr/include/string.h /usr/include/strings.h
src/meter_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/meter_menu.o: /usr/include/stdc-predef.h /usr/include/stdint.h
src/meter_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/meter_menu.o: /usr/include/unistd.h src/new_menu.h src/receiver.h
src/meter_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/meter_menu.o: /usr/include/stdio.h /usr/include/fcntl.h
src/meter_menu.o: /usr/include/assert.h /usr/include/poll.h
src/meter_menu.o: /usr/include/errno.h /usr/include/endian.h
src/meter_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/meter_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/meter_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/meter_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/meter_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/meter_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/meter_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/meter_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/meter_menu.o: /usr/include/alsa/seqmid.h
src/meter_menu.o: /usr/include/alsa/seq_midi_event.h
src/meter_menu.o: /usr/include/pulse/pulseaudio.h
src/meter_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/meter_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/meter_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/meter_menu.o: /usr/include/pulse/version.h
src/meter_menu.o: /usr/include/pulse/mainloop-api.h
src/meter_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/meter_menu.o: /usr/include/pulse/channelmap.h
src/meter_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/meter_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/meter_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/meter_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/meter_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/meter_menu.o: /usr/include/pulse/utf8.h
src/meter_menu.o: /usr/include/pulse/thread-mainloop.h
src/meter_menu.o: /usr/include/pulse/mainloop.h
src/meter_menu.o: /usr/include/pulse/mainloop-signal.h
src/meter_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/meter_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/meter_menu.o: src/meter_menu.h src/meter.h src/radio.h src/adc.h
src/meter_menu.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/meter_menu.o: /usr/include/SoapySDR/Device.h
src/meter_menu.o: /usr/include/SoapySDR/Config.h
src/meter_menu.o: /usr/include/SoapySDR/Types.h
src/meter_menu.o: /usr/include/SoapySDR/Constants.h
src/meter_menu.o: /usr/include/SoapySDR/Errors.h src/transmitter.h
src/midi2.o: /usr/include/stdio.h /usr/include/string.h
src/midi2.o: /usr/include/strings.h /usr/include/features.h
src/midi2.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/midi2.o: /usr/include/stdlib.h /usr/include/alloca.h /usr/include/time.h
src/midi2.o: src/MacOS.h /usr/include/semaphore.h src/receiver.h
src/midi2.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/midi2.o: /usr/include/unistd.h /usr/include/fcntl.h /usr/include/assert.h
src/midi2.o: /usr/include/poll.h /usr/include/errno.h /usr/include/endian.h
src/midi2.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/midi2.o: /usr/include/alsa/global.h /usr/include/alsa/input.h
src/midi2.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/midi2.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/midi2.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/midi2.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/midi2.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/midi2.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/midi2.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/midi2.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/midi2.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/midi2.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/midi2.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/midi2.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/midi2.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/midi2.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/midi2.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/midi2.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/midi2.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/midi2.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/midi2.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/midi2.o: /usr/include/pulse/mainloop.h
src/midi2.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/midi2.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/midi2.o: /usr/include/pulse/simple.h src/discovered.h
src/midi2.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/midi2.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/midi2.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/midi2.o: src/adc.h src/dac.h src/transmitter.h src/radio.h src/main.h
src/midi2.o: src/actions.h src/midi.h src/alsa_midi.h src/message.h
src/midi3.o: src/actions.h src/message.h src/midi.h
src/midi_menu.o: /usr/include/string.h /usr/include/strings.h
src/midi_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/midi_menu.o: /usr/include/stdc-predef.h /usr/include/stdint.h
src/midi_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/midi_menu.o: /usr/include/unistd.h /usr/include/termios.h src/main.h
src/midi_menu.o: src/discovered.h /usr/include/netinet/in.h
src/midi_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/midi_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/midi_menu.o: /usr/include/SoapySDR/Constants.h
src/midi_menu.o: /usr/include/SoapySDR/Errors.h src/mode.h src/filter.h
src/midi_menu.o: src/band.h src/bandstack.h src/receiver.h
src/midi_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/midi_menu.o: /usr/include/stdio.h /usr/include/fcntl.h
src/midi_menu.o: /usr/include/assert.h /usr/include/poll.h
src/midi_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/midi_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/midi_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/midi_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/midi_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/midi_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/midi_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/midi_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/midi_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/midi_menu.o: /usr/include/alsa/seq_midi_event.h
src/midi_menu.o: /usr/include/pulse/pulseaudio.h
src/midi_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/midi_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/midi_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/midi_menu.o: /usr/include/pulse/version.h
src/midi_menu.o: /usr/include/pulse/mainloop-api.h
src/midi_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/midi_menu.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/midi_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/midi_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/midi_menu.o: /usr/include/pulse/introspect.h
src/midi_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/midi_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/midi_menu.o: /usr/include/pulse/utf8.h
src/midi_menu.o: /usr/include/pulse/thread-mainloop.h
src/midi_menu.o: /usr/include/pulse/mainloop.h
src/midi_menu.o: /usr/include/pulse/mainloop-signal.h
src/midi_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/midi_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/midi_menu.o: src/transmitter.h src/adc.h src/dac.h src/radio.h
src/midi_menu.o: src/actions.h src/action_dialog.h src/midi.h src/alsa_midi.h
src/midi_menu.o: src/new_menu.h src/midi_menu.h src/property.h src/mystring.h
src/midi_menu.o: src/message.h
src/mode_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/mode_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/mode_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/mode_menu.o: /usr/include/stdc-predef.h /usr/include/string.h
src/mode_menu.o: /usr/include/strings.h src/new_menu.h src/band_menu.h
src/mode_menu.o: src/band.h src/bandstack.h src/filter.h src/mode.h
src/mode_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/mode_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/mode_menu.o: /usr/include/SoapySDR/Device.h
src/mode_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/mode_menu.o: /usr/include/SoapySDR/Constants.h
src/mode_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/mode_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/mode_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/mode_menu.o: /usr/include/assert.h /usr/include/poll.h
src/mode_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/mode_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/mode_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/mode_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/mode_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/mode_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/mode_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/mode_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/mode_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/mode_menu.o: /usr/include/alsa/seq_midi_event.h
src/mode_menu.o: /usr/include/pulse/pulseaudio.h
src/mode_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/mode_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/mode_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/mode_menu.o: /usr/include/pulse/version.h
src/mode_menu.o: /usr/include/pulse/mainloop-api.h
src/mode_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/mode_menu.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/mode_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/mode_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/mode_menu.o: /usr/include/pulse/introspect.h
src/mode_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/mode_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/mode_menu.o: /usr/include/pulse/utf8.h
src/mode_menu.o: /usr/include/pulse/thread-mainloop.h
src/mode_menu.o: /usr/include/pulse/mainloop.h
src/mode_menu.o: /usr/include/pulse/mainloop-signal.h
src/mode_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/mode_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/mode_menu.o: src/transmitter.h src/vfo.h
src/mystring.o: /usr/include/string.h /usr/include/strings.h
src/mystring.o: /usr/include/features.h /usr/include/features-time64.h
src/mystring.o: /usr/include/stdc-predef.h
src/new_discovery.o: /usr/include/stdlib.h /usr/include/alloca.h
src/new_discovery.o: /usr/include/features.h /usr/include/features-time64.h
src/new_discovery.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/new_discovery.o: /usr/include/netinet/in.h /usr/include/endian.h
src/new_discovery.o: /usr/include/arpa/inet.h /usr/include/netdb.h
src/new_discovery.o: /usr/include/rpc/netdb.h /usr/include/net/if_arp.h
src/new_discovery.o: /usr/include/stdint.h /usr/include/net/if.h
src/new_discovery.o: /usr/include/ifaddrs.h /usr/include/string.h
src/new_discovery.o: /usr/include/strings.h /usr/include/errno.h
src/new_discovery.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/new_discovery.o: /usr/include/SoapySDR/Config.h
src/new_discovery.o: /usr/include/SoapySDR/Types.h
src/new_discovery.o: /usr/include/SoapySDR/Constants.h
src/new_discovery.o: /usr/include/SoapySDR/Errors.h src/discovery.h
src/new_discovery.o: src/message.h src/mystring.h
src/new_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/new_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/new_menu.o: /usr/include/stdio.h /usr/include/string.h
src/new_menu.o: /usr/include/strings.h src/audio.h src/receiver.h
src/new_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/new_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/new_menu.o: /usr/include/alloca.h /usr/include/fcntl.h
src/new_menu.o: /usr/include/assert.h /usr/include/poll.h
src/new_menu.o: /usr/include/errno.h /usr/include/endian.h
src/new_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/new_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/new_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/new_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/new_menu.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/new_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/new_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/new_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/new_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/new_menu.o: /usr/include/alsa/seq_midi_event.h
src/new_menu.o: /usr/include/pulse/pulseaudio.h
src/new_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/new_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/new_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/new_menu.o: /usr/include/pulse/version.h
src/new_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/new_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/new_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/new_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/new_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/new_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/new_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/new_menu.o: /usr/include/pulse/utf8.h
src/new_menu.o: /usr/include/pulse/thread-mainloop.h
src/new_menu.o: /usr/include/pulse/mainloop.h
src/new_menu.o: /usr/include/pulse/mainloop-signal.h
src/new_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/new_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/new_menu.o: src/new_menu.h src/about_menu.h src/exit_menu.h
src/new_menu.o: src/radio_menu.h src/rx_menu.h src/ant_menu.h
src/new_menu.o: src/display_menu.h src/pa_menu.h src/rigctl_menu.h
src/new_menu.o: src/oc_menu.h src/cw_menu.h src/store_menu.h src/xvtr_menu.h
src/new_menu.o: src/equalizer_menu.h src/radio.h src/adc.h src/dac.h
src/new_menu.o: src/discovered.h /usr/include/netinet/in.h
src/new_menu.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/new_menu.o: /usr/include/SoapySDR/Types.h
src/new_menu.o: /usr/include/SoapySDR/Constants.h
src/new_menu.o: /usr/include/SoapySDR/Errors.h src/transmitter.h
src/new_menu.o: src/meter_menu.h src/band_menu.h src/bandstack_menu.h
src/new_menu.o: src/mode_menu.h src/filter_menu.h src/noise_menu.h
src/new_menu.o: src/agc_menu.h src/vox_menu.h src/diversity_menu.h
src/new_menu.o: src/tx_menu.h src/ps_menu.h src/encoder_menu.h
src/new_menu.o: src/switch_menu.h src/toolbar_menu.h src/vfo_menu.h
src/new_menu.o: src/fft_menu.h src/main.h src/actions.h src/gpio.h
src/new_menu.o: src/old_protocol.h src/new_protocol.h src/MacOS.h
src/new_menu.o: src/server_menu.h src/midi.h src/midi_menu.h
src/new_menu.o: src/screen_menu.h src/saturn_menu.h
src/new_protocol.o: /usr/include/errno.h /usr/include/features.h
src/new_protocol.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/new_protocol.o: /usr/include/stdio.h /usr/include/stdlib.h
src/new_protocol.o: /usr/include/alloca.h /usr/include/string.h
src/new_protocol.o: /usr/include/strings.h /usr/include/unistd.h
src/new_protocol.o: /usr/include/netinet/in.h /usr/include/endian.h
src/new_protocol.o: /usr/include/arpa/inet.h /usr/include/netdb.h
src/new_protocol.o: /usr/include/rpc/netdb.h /usr/include/net/if_arp.h
src/new_protocol.o: /usr/include/stdint.h /usr/include/net/if.h
src/new_protocol.o: /usr/include/netinet/ip.h /usr/include/ifaddrs.h
src/new_protocol.o: /usr/include/semaphore.h /usr/include/math.h
src/new_protocol.o: /usr/include/signal.h src/alex.h src/audio.h
src/new_protocol.o: src/receiver.h /usr/include/portaudio.h
src/new_protocol.o: /usr/include/alsa/asoundlib.h /usr/include/fcntl.h
src/new_protocol.o: /usr/include/assert.h /usr/include/poll.h
src/new_protocol.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/new_protocol.o: /usr/include/alsa/global.h /usr/include/time.h
src/new_protocol.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/new_protocol.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/new_protocol.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/new_protocol.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/new_protocol.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/new_protocol.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/new_protocol.o: /usr/include/alsa/seqmid.h
src/new_protocol.o: /usr/include/alsa/seq_midi_event.h
src/new_protocol.o: /usr/include/pulse/pulseaudio.h
src/new_protocol.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/new_protocol.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/new_protocol.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/new_protocol.o: /usr/include/pulse/version.h
src/new_protocol.o: /usr/include/pulse/mainloop-api.h
src/new_protocol.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/new_protocol.o: /usr/include/pulse/channelmap.h
src/new_protocol.o: /usr/include/pulse/context.h
src/new_protocol.o: /usr/include/pulse/operation.h
src/new_protocol.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/new_protocol.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/new_protocol.o: /usr/include/pulse/subscribe.h
src/new_protocol.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/new_protocol.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/new_protocol.o: /usr/include/pulse/thread-mainloop.h
src/new_protocol.o: /usr/include/pulse/mainloop.h
src/new_protocol.o: /usr/include/pulse/mainloop-signal.h
src/new_protocol.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/new_protocol.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/new_protocol.o: src/band.h src/bandstack.h src/new_protocol.h src/MacOS.h
src/new_protocol.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/new_protocol.o: /usr/include/SoapySDR/Config.h
src/new_protocol.o: /usr/include/SoapySDR/Types.h
src/new_protocol.o: /usr/include/SoapySDR/Constants.h
src/new_protocol.o: /usr/include/SoapySDR/Errors.h src/mode.h src/filter.h
src/new_protocol.o: src/radio.h src/adc.h src/dac.h src/transmitter.h
src/new_protocol.o: src/vfo.h src/toolbar.h src/gpio.h src/vox.h src/ext.h
src/new_protocol.o: src/client_server.h src/iambic.h src/message.h
src/new_protocol.o: src/saturnmain.h src/saturnregisters.h
src/newhpsdrsim.o: /usr/include/stdlib.h /usr/include/alloca.h
src/newhpsdrsim.o: /usr/include/features.h /usr/include/features-time64.h
src/newhpsdrsim.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/newhpsdrsim.o: /usr/include/stdint.h /usr/include/pthread.h
src/newhpsdrsim.o: /usr/include/sched.h /usr/include/time.h
src/newhpsdrsim.o: /usr/include/errno.h /usr/include/string.h
src/newhpsdrsim.o: /usr/include/strings.h /usr/include/netinet/in.h
src/newhpsdrsim.o: /usr/include/endian.h /usr/include/unistd.h
src/newhpsdrsim.o: /usr/include/arpa/inet.h /usr/include/math.h src/MacOS.h
src/newhpsdrsim.o: /usr/include/semaphore.h src/hpsdrsim.h
src/noise_menu.o: /usr/include/stdio.h /usr/include/stdlib.h
src/noise_menu.o: /usr/include/alloca.h /usr/include/features.h
src/noise_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/noise_menu.o: /usr/include/string.h /usr/include/strings.h src/new_menu.h
src/noise_menu.o: src/noise_menu.h src/band.h src/bandstack.h src/filter.h
src/noise_menu.o: src/mode.h src/radio.h src/adc.h src/dac.h src/discovered.h
src/noise_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/noise_menu.o: /usr/include/SoapySDR/Device.h
src/noise_menu.o: /usr/include/SoapySDR/Config.h
src/noise_menu.o: /usr/include/SoapySDR/Types.h
src/noise_menu.o: /usr/include/SoapySDR/Constants.h
src/noise_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/noise_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/noise_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/noise_menu.o: /usr/include/assert.h /usr/include/poll.h
src/noise_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/noise_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/noise_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/noise_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/noise_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/noise_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/noise_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/noise_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/noise_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/noise_menu.o: /usr/include/alsa/seqmid.h
src/noise_menu.o: /usr/include/alsa/seq_midi_event.h
src/noise_menu.o: /usr/include/pulse/pulseaudio.h
src/noise_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/noise_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/noise_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/noise_menu.o: /usr/include/pulse/version.h
src/noise_menu.o: /usr/include/pulse/mainloop-api.h
src/noise_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/noise_menu.o: /usr/include/pulse/channelmap.h
src/noise_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/noise_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/noise_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/noise_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/noise_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/noise_menu.o: /usr/include/pulse/utf8.h
src/noise_menu.o: /usr/include/pulse/thread-mainloop.h
src/noise_menu.o: /usr/include/pulse/mainloop.h
src/noise_menu.o: /usr/include/pulse/mainloop-signal.h
src/noise_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/noise_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/noise_menu.o: src/transmitter.h src/vfo.h src/ext.h src/client_server.h
src/oc_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/oc_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/oc_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/oc_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/oc_menu.o: /usr/include/string.h /usr/include/strings.h src/main.h
src/oc_menu.o: src/new_menu.h src/oc_menu.h src/band.h src/bandstack.h
src/oc_menu.o: src/filter.h src/mode.h src/radio.h src/adc.h src/dac.h
src/oc_menu.o: src/discovered.h /usr/include/netinet/in.h
src/oc_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/oc_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/oc_menu.o: /usr/include/SoapySDR/Constants.h
src/oc_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/oc_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/oc_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/oc_menu.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/oc_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/oc_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/oc_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/oc_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/oc_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/oc_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/oc_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/oc_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/oc_menu.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/oc_menu.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/oc_menu.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/oc_menu.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/oc_menu.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/oc_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/oc_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/oc_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/oc_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/oc_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/oc_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/oc_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/oc_menu.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/oc_menu.o: /usr/include/pulse/mainloop.h
src/oc_menu.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/oc_menu.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/oc_menu.o: /usr/include/pulse/simple.h src/transmitter.h
src/oc_menu.o: src/new_protocol.h src/MacOS.h src/message.h
src/old_discovery.o: /usr/include/stdlib.h /usr/include/alloca.h
src/old_discovery.o: /usr/include/features.h /usr/include/features-time64.h
src/old_discovery.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/old_discovery.o: /usr/include/netinet/in.h /usr/include/endian.h
src/old_discovery.o: /usr/include/arpa/inet.h /usr/include/netdb.h
src/old_discovery.o: /usr/include/rpc/netdb.h /usr/include/net/if_arp.h
src/old_discovery.o: /usr/include/stdint.h /usr/include/net/if.h
src/old_discovery.o: /usr/include/ifaddrs.h /usr/include/string.h
src/old_discovery.o: /usr/include/strings.h /usr/include/errno.h
src/old_discovery.o: /usr/include/fcntl.h src/discovered.h
src/old_discovery.o: /usr/include/SoapySDR/Device.h
src/old_discovery.o: /usr/include/SoapySDR/Config.h
src/old_discovery.o: /usr/include/SoapySDR/Types.h
src/old_discovery.o: /usr/include/SoapySDR/Constants.h
src/old_discovery.o: /usr/include/SoapySDR/Errors.h src/discovery.h
src/old_discovery.o: src/old_discovery.h src/stemlab_discovery.h
src/old_discovery.o: src/message.h src/mystring.h
src/old_protocol.o: /usr/include/stdlib.h /usr/include/alloca.h
src/old_protocol.o: /usr/include/features.h /usr/include/features-time64.h
src/old_protocol.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/old_protocol.o: /usr/include/netinet/in.h /usr/include/endian.h
src/old_protocol.o: /usr/include/arpa/inet.h /usr/include/netdb.h
src/old_protocol.o: /usr/include/rpc/netdb.h /usr/include/net/if_arp.h
src/old_protocol.o: /usr/include/stdint.h /usr/include/net/if.h
src/old_protocol.o: /usr/include/netinet/ip.h /usr/include/ifaddrs.h
src/old_protocol.o: /usr/include/semaphore.h /usr/include/string.h
src/old_protocol.o: /usr/include/strings.h /usr/include/errno.h
src/old_protocol.o: /usr/include/math.h /usr/include/signal.h src/MacOS.h
src/old_protocol.o: /usr/include/time.h src/audio.h src/receiver.h
src/old_protocol.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/old_protocol.o: /usr/include/unistd.h /usr/include/fcntl.h
src/old_protocol.o: /usr/include/assert.h /usr/include/poll.h
src/old_protocol.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/old_protocol.o: /usr/include/alsa/global.h /usr/include/alsa/input.h
src/old_protocol.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/old_protocol.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/old_protocol.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/old_protocol.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/old_protocol.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/old_protocol.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/old_protocol.o: /usr/include/alsa/seq_midi_event.h
src/old_protocol.o: /usr/include/pulse/pulseaudio.h
src/old_protocol.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/old_protocol.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/old_protocol.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/old_protocol.o: /usr/include/pulse/version.h
src/old_protocol.o: /usr/include/pulse/mainloop-api.h
src/old_protocol.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/old_protocol.o: /usr/include/pulse/channelmap.h
src/old_protocol.o: /usr/include/pulse/context.h
src/old_protocol.o: /usr/include/pulse/operation.h
src/old_protocol.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/old_protocol.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/old_protocol.o: /usr/include/pulse/subscribe.h
src/old_protocol.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/old_protocol.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/old_protocol.o: /usr/include/pulse/thread-mainloop.h
src/old_protocol.o: /usr/include/pulse/mainloop.h
src/old_protocol.o: /usr/include/pulse/mainloop-signal.h
src/old_protocol.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/old_protocol.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/old_protocol.o: src/band.h src/bandstack.h src/discovered.h
src/old_protocol.o: /usr/include/SoapySDR/Device.h
src/old_protocol.o: /usr/include/SoapySDR/Config.h
src/old_protocol.o: /usr/include/SoapySDR/Types.h
src/old_protocol.o: /usr/include/SoapySDR/Constants.h
src/old_protocol.o: /usr/include/SoapySDR/Errors.h src/mode.h src/filter.h
src/old_protocol.o: src/old_protocol.h src/radio.h src/adc.h src/dac.h
src/old_protocol.o: src/transmitter.h src/vfo.h src/ext.h src/client_server.h
src/old_protocol.o: src/iambic.h src/message.h src/ozyio.h
src/ozyio.o: /usr/include/stdio.h /usr/include/stdlib.h /usr/include/alloca.h
src/ozyio.o: /usr/include/features.h /usr/include/features-time64.h
src/ozyio.o: /usr/include/stdc-predef.h /usr/include/ctype.h
src/ozyio.o: /usr/include/errno.h /usr/include/string.h
src/ozyio.o: /usr/include/strings.h /usr/include/unistd.h
src/ozyio.o: /usr/include/libusb-1.0/libusb.h /usr/include/limits.h
src/ozyio.o: /usr/include/stdint.h /usr/include/time.h src/ozyio.h
src/ozyio.o: src/message.h
src/pa_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/pa_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/pa_menu.o: /usr/include/stdio.h /usr/include/string.h
src/pa_menu.o: /usr/include/strings.h src/new_menu.h src/pa_menu.h src/band.h
src/pa_menu.o: src/bandstack.h src/radio.h src/adc.h src/dac.h
src/pa_menu.o: src/discovered.h /usr/include/netinet/in.h
src/pa_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/pa_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/pa_menu.o: /usr/include/SoapySDR/Constants.h
src/pa_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/pa_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/pa_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/pa_menu.o: /usr/include/alloca.h /usr/include/fcntl.h
src/pa_menu.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/pa_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/pa_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/pa_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/pa_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/pa_menu.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/pa_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/pa_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/pa_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/pa_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/pa_menu.o: /usr/include/alsa/seq_midi_event.h
src/pa_menu.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/pa_menu.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/pa_menu.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/pa_menu.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/pa_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/pa_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/pa_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/pa_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/pa_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/pa_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/pa_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/pa_menu.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/pa_menu.o: /usr/include/pulse/mainloop.h
src/pa_menu.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/pa_menu.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/pa_menu.o: /usr/include/pulse/simple.h src/transmitter.h src/vfo.h
src/pa_menu.o: src/mode.h src/message.h
src/portaudio.o: /usr/include/stdio.h /usr/include/stdlib.h
src/portaudio.o: /usr/include/alloca.h /usr/include/features.h
src/portaudio.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/portaudio.o: /usr/include/unistd.h /usr/include/string.h
src/portaudio.o: /usr/include/strings.h /usr/include/errno.h
src/portaudio.o: /usr/include/fcntl.h /usr/include/pthread.h
src/portaudio.o: /usr/include/sched.h /usr/include/time.h
src/portaudio.o: /usr/include/semaphore.h /usr/include/portaudio.h
src/portaudio.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/portaudio.o: /usr/include/netinet/in.h /usr/include/endian.h
src/portaudio.o: /usr/include/SoapySDR/Device.h
src/portaudio.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/portaudio.o: /usr/include/SoapySDR/Constants.h
src/portaudio.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/portaudio.o: /usr/include/alsa/asoundlib.h /usr/include/assert.h
src/portaudio.o: /usr/include/poll.h /usr/include/alsa/asoundef.h
src/portaudio.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/portaudio.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/portaudio.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/portaudio.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/portaudio.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/portaudio.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/portaudio.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/portaudio.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/portaudio.o: /usr/include/alsa/seq_midi_event.h
src/portaudio.o: /usr/include/pulse/pulseaudio.h
src/portaudio.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/portaudio.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/portaudio.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/portaudio.o: /usr/include/pulse/version.h
src/portaudio.o: /usr/include/pulse/mainloop-api.h
src/portaudio.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/portaudio.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/portaudio.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/portaudio.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/portaudio.o: /usr/include/pulse/introspect.h
src/portaudio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/portaudio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/portaudio.o: /usr/include/pulse/utf8.h
src/portaudio.o: /usr/include/pulse/thread-mainloop.h
src/portaudio.o: /usr/include/pulse/mainloop.h
src/portaudio.o: /usr/include/pulse/mainloop-signal.h
src/portaudio.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/portaudio.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/portaudio.o: src/transmitter.h src/mode.h src/audio.h src/message.h
src/portaudio.o: src/vfo.h
src/property.o: /usr/include/stdlib.h /usr/include/alloca.h
src/property.o: /usr/include/features.h /usr/include/features-time64.h
src/property.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/property.o: /usr/include/string.h /usr/include/strings.h src/property.h
src/property.o: src/mystring.h src/message.h
src/protocols.o: /usr/include/math.h /usr/include/unistd.h
src/protocols.o: /usr/include/features.h /usr/include/features-time64.h
src/protocols.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/protocols.o: /usr/include/alloca.h /usr/include/string.h
src/protocols.o: /usr/include/strings.h /usr/include/semaphore.h
src/protocols.o: /usr/include/netinet/in.h /usr/include/endian.h
src/protocols.o: /usr/include/arpa/inet.h src/radio.h src/adc.h src/dac.h
src/protocols.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/protocols.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/protocols.o: /usr/include/SoapySDR/Constants.h
src/protocols.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/protocols.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/protocols.o: /usr/include/stdio.h /usr/include/fcntl.h
src/protocols.o: /usr/include/assert.h /usr/include/poll.h
src/protocols.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/protocols.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/protocols.o: /usr/include/time.h /usr/include/alsa/input.h
src/protocols.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/protocols.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/protocols.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/protocols.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/protocols.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/protocols.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/protocols.o: /usr/include/alsa/seqmid.h
src/protocols.o: /usr/include/alsa/seq_midi_event.h
src/protocols.o: /usr/include/pulse/pulseaudio.h
src/protocols.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/protocols.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/protocols.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/protocols.o: /usr/include/pulse/version.h
src/protocols.o: /usr/include/pulse/mainloop-api.h
src/protocols.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/protocols.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/protocols.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/protocols.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/protocols.o: /usr/include/pulse/introspect.h
src/protocols.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/protocols.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/protocols.o: /usr/include/pulse/utf8.h
src/protocols.o: /usr/include/pulse/thread-mainloop.h
src/protocols.o: /usr/include/pulse/mainloop.h
src/protocols.o: /usr/include/pulse/mainloop-signal.h
src/protocols.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/protocols.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/protocols.o: src/transmitter.h src/protocols.h src/property.h
src/protocols.o: src/mystring.h
src/ps_menu.o: /usr/include/math.h /usr/include/stdio.h /usr/include/stdlib.h
src/ps_menu.o: /usr/include/alloca.h /usr/include/features.h
src/ps_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/ps_menu.o: /usr/include/string.h /usr/include/strings.h src/new_menu.h
src/ps_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/ps_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/ps_menu.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/ps_menu.o: /usr/include/SoapySDR/Types.h
src/ps_menu.o: /usr/include/SoapySDR/Constants.h
src/ps_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/ps_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/ps_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/ps_menu.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/ps_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/ps_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/ps_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/ps_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/ps_menu.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/ps_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/ps_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/ps_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/ps_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/ps_menu.o: /usr/include/alsa/seq_midi_event.h
src/ps_menu.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/ps_menu.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/ps_menu.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/ps_menu.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/ps_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/ps_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/ps_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/ps_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/ps_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/ps_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/ps_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/ps_menu.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/ps_menu.o: /usr/include/pulse/mainloop.h
src/ps_menu.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/ps_menu.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/ps_menu.o: /usr/include/pulse/simple.h src/transmitter.h src/toolbar.h
src/ps_menu.o: src/gpio.h src/new_protocol.h src/MacOS.h
src/ps_menu.o: /usr/include/semaphore.h src/vfo.h src/mode.h src/ext.h
src/ps_menu.o: src/client_server.h src/message.h src/mystring.h
src/pulseaudio.o: /usr/include/pulse/pulseaudio.h
src/pulseaudio.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/pulseaudio.o: /usr/include/inttypes.h /usr/include/features.h
src/pulseaudio.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/pulseaudio.o: /usr/include/stdint.h /usr/include/pulse/cdecl.h
src/pulseaudio.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/pulseaudio.o: /usr/include/pulse/version.h
src/pulseaudio.o: /usr/include/pulse/mainloop-api.h
src/pulseaudio.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/pulseaudio.o: /usr/include/pulse/channelmap.h
src/pulseaudio.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/pulseaudio.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/pulseaudio.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/pulseaudio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/pulseaudio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/pulseaudio.o: /usr/include/stdlib.h /usr/include/alloca.h
src/pulseaudio.o: /usr/include/assert.h /usr/include/pulse/utf8.h
src/pulseaudio.o: /usr/include/pulse/thread-mainloop.h
src/pulseaudio.o: /usr/include/pulse/mainloop.h
src/pulseaudio.o: /usr/include/pulse/mainloop-signal.h
src/pulseaudio.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/pulseaudio.o: /usr/include/pulse/rtclock.h
src/pulseaudio.o: /usr/include/pulse/glib-mainloop.h
src/pulseaudio.o: /usr/include/pulse/simple.h src/radio.h src/adc.h src/dac.h
src/pulseaudio.o: src/discovered.h /usr/include/netinet/in.h
src/pulseaudio.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/pulseaudio.o: /usr/include/SoapySDR/Config.h
src/pulseaudio.o: /usr/include/SoapySDR/Types.h
src/pulseaudio.o: /usr/include/SoapySDR/Constants.h
src/pulseaudio.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/pulseaudio.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/pulseaudio.o: /usr/include/unistd.h /usr/include/stdio.h
src/pulseaudio.o: /usr/include/string.h /usr/include/strings.h
src/pulseaudio.o: /usr/include/fcntl.h /usr/include/poll.h
src/pulseaudio.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/pulseaudio.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/pulseaudio.o: /usr/include/time.h /usr/include/alsa/input.h
src/pulseaudio.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/pulseaudio.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/pulseaudio.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/pulseaudio.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/pulseaudio.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/pulseaudio.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/pulseaudio.o: /usr/include/alsa/seq_midi_event.h src/transmitter.h
src/pulseaudio.o: src/audio.h src/mode.h src/vfo.h src/message.h
src/puresignal.o: src/puresignal.h src/agc.h src/mode.h src/filter.h
src/puresignal.o: src/bandstack.h src/band.h src/discovered.h
src/puresignal.o: /usr/include/netinet/in.h /usr/include/features.h
src/puresignal.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/puresignal.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/puresignal.o: /usr/include/SoapySDR/Config.h
src/puresignal.o: /usr/include/SoapySDR/Types.h
src/puresignal.o: /usr/include/SoapySDR/Constants.h
src/puresignal.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/puresignal.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/puresignal.o: /usr/include/unistd.h /usr/include/stdio.h
src/puresignal.o: /usr/include/stdlib.h /usr/include/alloca.h
src/puresignal.o: /usr/include/string.h /usr/include/strings.h
src/puresignal.o: /usr/include/fcntl.h /usr/include/assert.h
src/puresignal.o: /usr/include/poll.h /usr/include/errno.h
src/puresignal.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/puresignal.o: /usr/include/alsa/global.h /usr/include/time.h
src/puresignal.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/puresignal.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/puresignal.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/puresignal.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/puresignal.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/puresignal.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/puresignal.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/puresignal.o: /usr/include/alsa/seq_midi_event.h
src/puresignal.o: /usr/include/pulse/pulseaudio.h
src/puresignal.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/puresignal.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/puresignal.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/puresignal.o: /usr/include/pulse/version.h
src/puresignal.o: /usr/include/pulse/mainloop-api.h
src/puresignal.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/puresignal.o: /usr/include/pulse/channelmap.h
src/puresignal.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/puresignal.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/puresignal.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/puresignal.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/puresignal.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/puresignal.o: /usr/include/pulse/utf8.h
src/puresignal.o: /usr/include/pulse/thread-mainloop.h
src/puresignal.o: /usr/include/pulse/mainloop.h
src/puresignal.o: /usr/include/pulse/mainloop-signal.h
src/puresignal.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/puresignal.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/puresignal.o: src/transmitter.h src/adc.h src/dac.h src/radio.h
src/puresignal.o: src/main.h src/vfo.h src/meter.h src/rx_panadapter.h
src/puresignal.o: src/tx_panadapter.h src/waterfall.h src/audio.h
src/puresignal.o: src/property.h src/mystring.h src/rigctl.h
src/puresignal.o: /usr/include/math.h
src/puresignal_dialog.o: /usr/include/math.h /usr/include/string.h
src/puresignal_dialog.o: /usr/include/strings.h /usr/include/features.h
src/puresignal_dialog.o: /usr/include/features-time64.h
src/puresignal_dialog.o: /usr/include/stdc-predef.h /usr/include/stdint.h
src/puresignal_dialog.o: /usr/include/stdlib.h /usr/include/alloca.h
src/puresignal_dialog.o: /usr/include/unistd.h /usr/include/netinet/in.h
src/puresignal_dialog.o: /usr/include/endian.h /usr/include/arpa/inet.h
src/puresignal_dialog.o: src/receiver.h /usr/include/portaudio.h
src/puresignal_dialog.o: /usr/include/alsa/asoundlib.h /usr/include/stdio.h
src/puresignal_dialog.o: /usr/include/fcntl.h /usr/include/assert.h
src/puresignal_dialog.o: /usr/include/poll.h /usr/include/errno.h
src/puresignal_dialog.o: /usr/include/alsa/asoundef.h
src/puresignal_dialog.o: /usr/include/alsa/version.h
src/puresignal_dialog.o: /usr/include/alsa/global.h /usr/include/time.h
src/puresignal_dialog.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/puresignal_dialog.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/puresignal_dialog.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/puresignal_dialog.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/puresignal_dialog.o: /usr/include/alsa/control.h
src/puresignal_dialog.o: /usr/include/alsa/mixer.h
src/puresignal_dialog.o: /usr/include/alsa/seq_event.h
src/puresignal_dialog.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/puresignal_dialog.o: /usr/include/alsa/seq_midi_event.h
src/puresignal_dialog.o: /usr/include/pulse/pulseaudio.h
src/puresignal_dialog.o: /usr/include/pulse/direction.h
src/puresignal_dialog.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/puresignal_dialog.o: /usr/include/pulse/cdecl.h
src/puresignal_dialog.o: /usr/include/pulse/sample.h
src/puresignal_dialog.o: /usr/include/pulse/gccmacro.h
src/puresignal_dialog.o: /usr/include/pulse/version.h
src/puresignal_dialog.o: /usr/include/pulse/mainloop-api.h
src/puresignal_dialog.o: /usr/include/pulse/format.h
src/puresignal_dialog.o: /usr/include/pulse/proplist.h
src/puresignal_dialog.o: /usr/include/pulse/channelmap.h
src/puresignal_dialog.o: /usr/include/pulse/context.h
src/puresignal_dialog.o: /usr/include/pulse/operation.h
src/puresignal_dialog.o: /usr/include/pulse/stream.h
src/puresignal_dialog.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/puresignal_dialog.o: /usr/include/pulse/introspect.h
src/puresignal_dialog.o: /usr/include/pulse/subscribe.h
src/puresignal_dialog.o: /usr/include/pulse/scache.h
src/puresignal_dialog.o: /usr/include/pulse/error.h
src/puresignal_dialog.o: /usr/include/pulse/xmalloc.h
src/puresignal_dialog.o: /usr/include/pulse/utf8.h
src/puresignal_dialog.o: /usr/include/pulse/thread-mainloop.h
src/puresignal_dialog.o: /usr/include/pulse/mainloop.h
src/puresignal_dialog.o: /usr/include/pulse/mainloop-signal.h
src/puresignal_dialog.o: /usr/include/pulse/util.h
src/puresignal_dialog.o: /usr/include/pulse/timeval.h
src/puresignal_dialog.o: /usr/include/pulse/rtclock.h
src/puresignal_dialog.o: /usr/include/pulse/simple.h src/transmitter.h
src/puresignal_dialog.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/puresignal_dialog.o: /usr/include/SoapySDR/Config.h
src/puresignal_dialog.o: /usr/include/SoapySDR/Types.h
src/puresignal_dialog.o: /usr/include/SoapySDR/Constants.h
src/puresignal_dialog.o: /usr/include/SoapySDR/Errors.h src/adc.h src/dac.h
src/puresignal_dialog.o: src/radio.h src/main.h src/audio.h src/band.h
src/puresignal_dialog.o: src/bandstack.h
src/radio.o: /usr/include/stdlib.h /usr/include/alloca.h
src/radio.o: /usr/include/features.h /usr/include/features-time64.h
src/radio.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/radio.o: /usr/include/string.h /usr/include/strings.h
src/radio.o: /usr/include/semaphore.h /usr/include/math.h
src/radio.o: /usr/include/netinet/in.h /usr/include/endian.h
src/radio.o: /usr/include/arpa/inet.h /usr/include/netdb.h
src/radio.o: /usr/include/rpc/netdb.h /usr/include/termios.h src/appearance.h
src/radio.o: src/adc.h src/dac.h src/audio.h src/receiver.h
src/radio.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/radio.o: /usr/include/unistd.h /usr/include/fcntl.h /usr/include/assert.h
src/radio.o: /usr/include/poll.h /usr/include/errno.h
src/radio.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/radio.o: /usr/include/alsa/global.h /usr/include/time.h
src/radio.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/radio.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/radio.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/radio.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/radio.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/radio.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/radio.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/radio.o: /usr/include/alsa/seq_midi_event.h
src/radio.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/radio.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/radio.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/radio.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/radio.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/radio.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/radio.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/radio.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/radio.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/radio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/radio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/radio.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/radio.o: /usr/include/pulse/mainloop.h
src/radio.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/radio.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/radio.o: /usr/include/pulse/simple.h src/discovered.h
src/radio.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/radio.o: /usr/include/SoapySDR/Types.h /usr/include/SoapySDR/Constants.h
src/radio.o: /usr/include/SoapySDR/Errors.h src/filter.h src/mode.h
src/radio.o: src/main.h src/radio.h src/transmitter.h src/agc.h src/band.h
src/radio.o: src/bandstack.h src/channel.h src/property.h src/mystring.h
src/radio.o: src/new_menu.h src/new_protocol.h src/MacOS.h src/old_protocol.h
src/radio.o: src/store.h src/soapy_protocol.h src/actions.h src/gpio.h
src/radio.o: src/vfo.h src/vox.h src/meter.h src/rx_panadapter.h
src/radio.o: src/tx_panadapter.h src/waterfall.h src/zoompan.h src/sliders.h
src/radio.o: src/toolbar.h src/rigctl.h src/ext.h src/client_server.h
src/radio.o: src/radio_menu.h src/iambic.h src/rigctl_menu.h
src/radio.o: src/screen_menu.h src/midi.h src/alsa_midi.h src/midi_menu.h
src/radio.o: src/message.h src/saturnmain.h src/saturnregisters.h
src/radio.o: src/saturnserver.h
src/radio_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/radio_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/radio_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/radio_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/radio_menu.o: /usr/include/string.h /usr/include/strings.h src/main.h
src/radio_menu.o: src/discovered.h /usr/include/netinet/in.h
src/radio_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/radio_menu.o: /usr/include/SoapySDR/Config.h
src/radio_menu.o: /usr/include/SoapySDR/Types.h
src/radio_menu.o: /usr/include/SoapySDR/Constants.h
src/radio_menu.o: /usr/include/SoapySDR/Errors.h src/new_menu.h
src/radio_menu.o: src/radio_menu.h src/adc.h src/band.h src/bandstack.h
src/radio_menu.o: src/filter.h src/mode.h src/radio.h src/dac.h
src/radio_menu.o: src/receiver.h /usr/include/portaudio.h
src/radio_menu.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/radio_menu.o: /usr/include/fcntl.h /usr/include/assert.h
src/radio_menu.o: /usr/include/poll.h /usr/include/errno.h
src/radio_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/radio_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/radio_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/radio_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/radio_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/radio_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/radio_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/radio_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/radio_menu.o: /usr/include/alsa/seqmid.h
src/radio_menu.o: /usr/include/alsa/seq_midi_event.h
src/radio_menu.o: /usr/include/pulse/pulseaudio.h
src/radio_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/radio_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/radio_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/radio_menu.o: /usr/include/pulse/version.h
src/radio_menu.o: /usr/include/pulse/mainloop-api.h
src/radio_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/radio_menu.o: /usr/include/pulse/channelmap.h
src/radio_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/radio_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/radio_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/radio_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/radio_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/radio_menu.o: /usr/include/pulse/utf8.h
src/radio_menu.o: /usr/include/pulse/thread-mainloop.h
src/radio_menu.o: /usr/include/pulse/mainloop.h
src/radio_menu.o: /usr/include/pulse/mainloop-signal.h
src/radio_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/radio_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/radio_menu.o: src/transmitter.h src/sliders.h src/actions.h
src/radio_menu.o: src/new_protocol.h src/MacOS.h src/old_protocol.h
src/radio_menu.o: src/soapy_protocol.h src/gpio.h src/vfo.h src/ext.h
src/radio_menu.o: src/client_server.h
src/receiver.o: /usr/include/math.h /usr/include/stdio.h
src/receiver.o: /usr/include/stdlib.h /usr/include/alloca.h
src/receiver.o: /usr/include/features.h /usr/include/features-time64.h
src/receiver.o: /usr/include/stdc-predef.h src/agc.h src/audio.h
src/receiver.o: src/receiver.h /usr/include/portaudio.h
src/receiver.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/receiver.o: /usr/include/string.h /usr/include/strings.h
src/receiver.o: /usr/include/fcntl.h /usr/include/assert.h
src/receiver.o: /usr/include/poll.h /usr/include/errno.h
src/receiver.o: /usr/include/endian.h /usr/include/alsa/asoundef.h
src/receiver.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/receiver.o: /usr/include/time.h /usr/include/alsa/input.h
src/receiver.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/receiver.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/receiver.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/receiver.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/receiver.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/receiver.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/receiver.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/receiver.o: /usr/include/pulse/pulseaudio.h
src/receiver.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/receiver.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/receiver.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/receiver.o: /usr/include/pulse/version.h
src/receiver.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/receiver.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/receiver.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/receiver.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/receiver.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/receiver.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/receiver.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/receiver.o: /usr/include/pulse/utf8.h
src/receiver.o: /usr/include/pulse/thread-mainloop.h
src/receiver.o: /usr/include/pulse/mainloop.h
src/receiver.o: /usr/include/pulse/mainloop-signal.h
src/receiver.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/receiver.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/receiver.o: src/band.h src/bandstack.h src/channel.h src/discovered.h
src/receiver.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/receiver.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/receiver.o: /usr/include/SoapySDR/Constants.h
src/receiver.o: /usr/include/SoapySDR/Errors.h src/filter.h src/mode.h
src/receiver.o: src/main.h src/meter.h src/property.h src/mystring.h
src/receiver.o: src/radio.h src/adc.h src/dac.h src/transmitter.h src/vfo.h
src/receiver.o: src/rx_panadapter.h src/zoompan.h src/sliders.h src/actions.h
src/receiver.o: src/waterfall.h src/new_protocol.h src/MacOS.h
src/receiver.o: /usr/include/semaphore.h src/old_protocol.h
src/receiver.o: src/soapy_protocol.h src/ext.h src/client_server.h
src/receiver.o: src/new_menu.h src/message.h
src/rigctl.o: /usr/include/fcntl.h /usr/include/features.h
src/rigctl.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/rigctl.o: /usr/include/string.h /usr/include/strings.h
src/rigctl.o: /usr/include/termios.h /usr/include/unistd.h
src/rigctl.o: /usr/include/stdio.h /usr/include/stdint.h
src/rigctl.o: /usr/include/stdlib.h /usr/include/alloca.h src/receiver.h
src/rigctl.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/rigctl.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/rigctl.o: /usr/include/endian.h /usr/include/alsa/asoundef.h
src/rigctl.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/rigctl.o: /usr/include/time.h /usr/include/alsa/input.h
src/rigctl.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/rigctl.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/rigctl.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/rigctl.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/rigctl.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/rigctl.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/rigctl.o: /usr/include/alsa/seq_midi_event.h
src/rigctl.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/rigctl.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/rigctl.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/rigctl.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/rigctl.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/rigctl.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/rigctl.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/rigctl.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/rigctl.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/rigctl.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/rigctl.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/rigctl.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/rigctl.o: /usr/include/pulse/mainloop.h
src/rigctl.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/rigctl.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/rigctl.o: /usr/include/pulse/simple.h src/toolbar.h src/gpio.h
src/rigctl.o: src/band_menu.h src/sliders.h src/transmitter.h src/actions.h
src/rigctl.o: src/rigctl.h src/radio.h src/adc.h src/dac.h src/discovered.h
src/rigctl.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/rigctl.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/rigctl.o: /usr/include/SoapySDR/Constants.h
src/rigctl.o: /usr/include/SoapySDR/Errors.h src/channel.h src/filter.h
src/rigctl.o: src/mode.h src/band.h src/bandstack.h src/filter_menu.h
src/rigctl.o: src/vfo.h src/agc.h src/store.h src/ext.h src/client_server.h
src/rigctl.o: src/rigctl_menu.h src/noise_menu.h src/new_protocol.h
src/rigctl.o: src/MacOS.h /usr/include/semaphore.h src/old_protocol.h
src/rigctl.o: src/iambic.h src/new_menu.h src/zoompan.h src/exit_menu.h
src/rigctl.o: src/message.h src/mystring.h /usr/include/math.h
src/rigctl.o: /usr/include/arpa/inet.h /usr/include/netinet/tcp.h
src/rigctl_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/rigctl_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/rigctl_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/rigctl_menu.o: /usr/include/string.h /usr/include/strings.h
src/rigctl_menu.o: /usr/include/termios.h /usr/include/unistd.h
src/rigctl_menu.o: src/new_menu.h src/rigctl_menu.h src/rigctl.h src/band.h
src/rigctl_menu.o: src/bandstack.h src/radio.h src/adc.h src/dac.h
src/rigctl_menu.o: src/discovered.h /usr/include/netinet/in.h
src/rigctl_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/rigctl_menu.o: /usr/include/SoapySDR/Config.h
src/rigctl_menu.o: /usr/include/SoapySDR/Types.h
src/rigctl_menu.o: /usr/include/SoapySDR/Constants.h
src/rigctl_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/rigctl_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/rigctl_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/rigctl_menu.o: /usr/include/fcntl.h /usr/include/assert.h
src/rigctl_menu.o: /usr/include/poll.h /usr/include/errno.h
src/rigctl_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/rigctl_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/rigctl_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/rigctl_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/rigctl_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/rigctl_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/rigctl_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/rigctl_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/rigctl_menu.o: /usr/include/alsa/seqmid.h
src/rigctl_menu.o: /usr/include/alsa/seq_midi_event.h
src/rigctl_menu.o: /usr/include/pulse/pulseaudio.h
src/rigctl_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/rigctl_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/rigctl_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/rigctl_menu.o: /usr/include/pulse/version.h
src/rigctl_menu.o: /usr/include/pulse/mainloop-api.h
src/rigctl_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/rigctl_menu.o: /usr/include/pulse/channelmap.h
src/rigctl_menu.o: /usr/include/pulse/context.h
src/rigctl_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/rigctl_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/rigctl_menu.o: /usr/include/pulse/introspect.h
src/rigctl_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/rigctl_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/rigctl_menu.o: /usr/include/pulse/utf8.h
src/rigctl_menu.o: /usr/include/pulse/thread-mainloop.h
src/rigctl_menu.o: /usr/include/pulse/mainloop.h
src/rigctl_menu.o: /usr/include/pulse/mainloop-signal.h
src/rigctl_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/rigctl_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/rigctl_menu.o: src/transmitter.h src/vfo.h src/mode.h src/message.h
src/rigctl_menu.o: src/mystring.h
src/rx_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/rx_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/rx_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/rx_menu.o: /usr/include/string.h /usr/include/strings.h src/audio.h
src/rx_menu.o: src/receiver.h /usr/include/portaudio.h
src/rx_menu.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/rx_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/rx_menu.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/rx_menu.o: /usr/include/errno.h /usr/include/endian.h
src/rx_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/rx_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/rx_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/rx_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/rx_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/rx_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/rx_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/rx_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/rx_menu.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/rx_menu.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/rx_menu.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/rx_menu.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/rx_menu.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/rx_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/rx_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/rx_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/rx_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/rx_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/rx_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/rx_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/rx_menu.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/rx_menu.o: /usr/include/pulse/mainloop.h
src/rx_menu.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/rx_menu.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/rx_menu.o: /usr/include/pulse/simple.h src/new_menu.h src/rx_menu.h
src/rx_menu.o: src/band.h src/bandstack.h src/discovered.h
src/rx_menu.o: /usr/include/netinet/in.h /usr/include/SoapySDR/Device.h
src/rx_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/rx_menu.o: /usr/include/SoapySDR/Constants.h
src/rx_menu.o: /usr/include/SoapySDR/Errors.h src/filter.h src/mode.h
src/rx_menu.o: src/radio.h src/adc.h src/dac.h src/transmitter.h
src/rx_menu.o: src/sliders.h src/actions.h src/new_protocol.h src/MacOS.h
src/rx_menu.o: src/message.h src/mystring.h
src/rx_panadapter.o: /usr/include/math.h /usr/include/unistd.h
src/rx_panadapter.o: /usr/include/features.h /usr/include/features-time64.h
src/rx_panadapter.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/rx_panadapter.o: /usr/include/alloca.h /usr/include/string.h
src/rx_panadapter.o: /usr/include/strings.h /usr/include/semaphore.h
src/rx_panadapter.o: /usr/include/arpa/inet.h /usr/include/netinet/in.h
src/rx_panadapter.o: /usr/include/endian.h src/appearance.h src/agc.h
src/rx_panadapter.o: src/band.h src/bandstack.h src/discovered.h
src/rx_panadapter.o: /usr/include/SoapySDR/Device.h
src/rx_panadapter.o: /usr/include/SoapySDR/Config.h
src/rx_panadapter.o: /usr/include/SoapySDR/Types.h
src/rx_panadapter.o: /usr/include/SoapySDR/Constants.h
src/rx_panadapter.o: /usr/include/SoapySDR/Errors.h src/radio.h src/adc.h
src/rx_panadapter.o: src/dac.h src/receiver.h /usr/include/portaudio.h
src/rx_panadapter.o: /usr/include/alsa/asoundlib.h /usr/include/stdio.h
src/rx_panadapter.o: /usr/include/fcntl.h /usr/include/assert.h
src/rx_panadapter.o: /usr/include/poll.h /usr/include/errno.h
src/rx_panadapter.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/rx_panadapter.o: /usr/include/alsa/global.h /usr/include/time.h
src/rx_panadapter.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/rx_panadapter.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/rx_panadapter.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/rx_panadapter.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/rx_panadapter.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/rx_panadapter.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/rx_panadapter.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/rx_panadapter.o: /usr/include/alsa/seq_midi_event.h
src/rx_panadapter.o: /usr/include/pulse/pulseaudio.h
src/rx_panadapter.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/rx_panadapter.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/rx_panadapter.o: /usr/include/pulse/sample.h
src/rx_panadapter.o: /usr/include/pulse/gccmacro.h
src/rx_panadapter.o: /usr/include/pulse/version.h
src/rx_panadapter.o: /usr/include/pulse/mainloop-api.h
src/rx_panadapter.o: /usr/include/pulse/format.h
src/rx_panadapter.o: /usr/include/pulse/proplist.h
src/rx_panadapter.o: /usr/include/pulse/channelmap.h
src/rx_panadapter.o: /usr/include/pulse/context.h
src/rx_panadapter.o: /usr/include/pulse/operation.h
src/rx_panadapter.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/rx_panadapter.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/rx_panadapter.o: /usr/include/pulse/subscribe.h
src/rx_panadapter.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/rx_panadapter.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/rx_panadapter.o: /usr/include/pulse/thread-mainloop.h
src/rx_panadapter.o: /usr/include/pulse/mainloop.h
src/rx_panadapter.o: /usr/include/pulse/mainloop-signal.h
src/rx_panadapter.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/rx_panadapter.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/rx_panadapter.o: src/transmitter.h src/rx_panadapter.h src/vfo.h
src/rx_panadapter.o: src/mode.h src/actions.h src/gpio.h src/client_server.h
src/rx_panadapter.o: src/ozyio.h
src/saturn_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/saturn_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/saturn_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/saturn_menu.o: /usr/include/string.h /usr/include/strings.h
src/saturn_menu.o: /usr/include/termios.h /usr/include/unistd.h
src/saturn_menu.o: src/new_menu.h src/saturn_menu.h src/saturnserver.h
src/saturn_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/saturn_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/saturn_menu.o: /usr/include/SoapySDR/Device.h
src/saturn_menu.o: /usr/include/SoapySDR/Config.h
src/saturn_menu.o: /usr/include/SoapySDR/Types.h
src/saturn_menu.o: /usr/include/SoapySDR/Constants.h
src/saturn_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/saturn_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/saturn_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/saturn_menu.o: /usr/include/fcntl.h /usr/include/assert.h
src/saturn_menu.o: /usr/include/poll.h /usr/include/errno.h
src/saturn_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/saturn_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/saturn_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/saturn_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/saturn_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/saturn_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/saturn_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/saturn_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/saturn_menu.o: /usr/include/alsa/seqmid.h
src/saturn_menu.o: /usr/include/alsa/seq_midi_event.h
src/saturn_menu.o: /usr/include/pulse/pulseaudio.h
src/saturn_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/saturn_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/saturn_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/saturn_menu.o: /usr/include/pulse/version.h
src/saturn_menu.o: /usr/include/pulse/mainloop-api.h
src/saturn_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/saturn_menu.o: /usr/include/pulse/channelmap.h
src/saturn_menu.o: /usr/include/pulse/context.h
src/saturn_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/saturn_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/saturn_menu.o: /usr/include/pulse/introspect.h
src/saturn_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/saturn_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/saturn_menu.o: /usr/include/pulse/utf8.h
src/saturn_menu.o: /usr/include/pulse/thread-mainloop.h
src/saturn_menu.o: /usr/include/pulse/mainloop.h
src/saturn_menu.o: /usr/include/pulse/mainloop-signal.h
src/saturn_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/saturn_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/saturn_menu.o: src/transmitter.h
src/saturndrivers.o: /usr/include/stdlib.h /usr/include/alloca.h
src/saturndrivers.o: /usr/include/features.h /usr/include/features-time64.h
src/saturndrivers.o: /usr/include/stdc-predef.h /usr/include/math.h
src/saturndrivers.o: src/saturndrivers.h /usr/include/stdint.h
src/saturndrivers.o: src/saturnregisters.h /usr/include/semaphore.h
src/saturndrivers.o: /usr/include/assert.h /usr/include/fcntl.h
src/saturndrivers.o: /usr/include/getopt.h /usr/include/stdio.h
src/saturndrivers.o: /usr/include/string.h /usr/include/strings.h
src/saturndrivers.o: /usr/include/unistd.h /usr/include/errno.h src/message.h
src/saturnmain.o: /usr/include/stdio.h /usr/include/errno.h
src/saturnmain.o: /usr/include/features.h /usr/include/features-time64.h
src/saturnmain.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/saturnmain.o: /usr/include/alloca.h /usr/include/limits.h
src/saturnmain.o: /usr/include/stdint.h /usr/include/string.h
src/saturnmain.o: /usr/include/strings.h /usr/include/unistd.h
src/saturnmain.o: /usr/include/fcntl.h /usr/include/math.h
src/saturnmain.o: /usr/include/pthread.h /usr/include/sched.h
src/saturnmain.o: /usr/include/time.h /usr/include/termios.h
src/saturnmain.o: /usr/include/netinet/in.h /usr/include/endian.h
src/saturnmain.o: /usr/include/arpa/inet.h /usr/include/net/if.h
src/saturnmain.o: /usr/include/semaphore.h src/saturnregisters.h
src/saturnmain.o: src/saturndrivers.h src/saturnmain.h src/saturnserver.h
src/saturnmain.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/saturnmain.o: /usr/include/SoapySDR/Config.h
src/saturnmain.o: /usr/include/SoapySDR/Types.h
src/saturnmain.o: /usr/include/SoapySDR/Constants.h
src/saturnmain.o: /usr/include/SoapySDR/Errors.h src/new_protocol.h
src/saturnmain.o: src/MacOS.h src/receiver.h /usr/include/portaudio.h
src/saturnmain.o: /usr/include/alsa/asoundlib.h /usr/include/assert.h
src/saturnmain.o: /usr/include/poll.h /usr/include/alsa/asoundef.h
src/saturnmain.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/saturnmain.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/saturnmain.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/saturnmain.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/saturnmain.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/saturnmain.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/saturnmain.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/saturnmain.o: /usr/include/alsa/seqmid.h
src/saturnmain.o: /usr/include/alsa/seq_midi_event.h
src/saturnmain.o: /usr/include/pulse/pulseaudio.h
src/saturnmain.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/saturnmain.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/saturnmain.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/saturnmain.o: /usr/include/pulse/version.h
src/saturnmain.o: /usr/include/pulse/mainloop-api.h
src/saturnmain.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/saturnmain.o: /usr/include/pulse/channelmap.h
src/saturnmain.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/saturnmain.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/saturnmain.o: /usr/include/pulse/introspect.h
src/saturnmain.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/saturnmain.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/saturnmain.o: /usr/include/pulse/utf8.h
src/saturnmain.o: /usr/include/pulse/thread-mainloop.h
src/saturnmain.o: /usr/include/pulse/mainloop.h
src/saturnmain.o: /usr/include/pulse/mainloop-signal.h
src/saturnmain.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/saturnmain.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/saturnmain.o: src/message.h src/mystring.h
src/saturnregisters.o: src/saturnregisters.h /usr/include/stdint.h
src/saturnregisters.o: src/message.h /usr/include/stdlib.h
src/saturnregisters.o: /usr/include/alloca.h /usr/include/features.h
src/saturnregisters.o: /usr/include/features-time64.h
src/saturnregisters.o: /usr/include/stdc-predef.h /usr/include/math.h
src/saturnregisters.o: /usr/include/unistd.h /usr/include/semaphore.h
src/saturnserver.o: /usr/include/stdio.h /usr/include/errno.h
src/saturnserver.o: /usr/include/features.h /usr/include/features-time64.h
src/saturnserver.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/saturnserver.o: /usr/include/alloca.h /usr/include/limits.h
src/saturnserver.o: /usr/include/stdint.h /usr/include/string.h
src/saturnserver.o: /usr/include/strings.h /usr/include/unistd.h
src/saturnserver.o: /usr/include/fcntl.h /usr/include/math.h
src/saturnserver.o: /usr/include/pthread.h /usr/include/sched.h
src/saturnserver.o: /usr/include/time.h /usr/include/termios.h
src/saturnserver.o: /usr/include/netinet/in.h /usr/include/endian.h
src/saturnserver.o: /usr/include/arpa/inet.h /usr/include/net/if.h
src/saturnserver.o: /usr/include/semaphore.h src/saturnregisters.h
src/saturnserver.o: src/saturnserver.h src/saturndrivers.h src/saturnmain.h
src/saturnserver.o: src/message.h
src/screen_menu.o: /usr/include/stdio.h src/radio.h src/adc.h src/dac.h
src/screen_menu.o: src/discovered.h /usr/include/netinet/in.h
src/screen_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/screen_menu.o: /usr/include/stdc-predef.h /usr/include/endian.h
src/screen_menu.o: /usr/include/SoapySDR/Device.h
src/screen_menu.o: /usr/include/SoapySDR/Config.h
src/screen_menu.o: /usr/include/SoapySDR/Types.h
src/screen_menu.o: /usr/include/SoapySDR/Constants.h
src/screen_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/screen_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/screen_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/screen_menu.o: /usr/include/alloca.h /usr/include/string.h
src/screen_menu.o: /usr/include/strings.h /usr/include/fcntl.h
src/screen_menu.o: /usr/include/assert.h /usr/include/poll.h
src/screen_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/screen_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/screen_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/screen_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/screen_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/screen_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/screen_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/screen_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/screen_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/screen_menu.o: /usr/include/alsa/seqmid.h
src/screen_menu.o: /usr/include/alsa/seq_midi_event.h
src/screen_menu.o: /usr/include/pulse/pulseaudio.h
src/screen_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/screen_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/screen_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/screen_menu.o: /usr/include/pulse/version.h
src/screen_menu.o: /usr/include/pulse/mainloop-api.h
src/screen_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/screen_menu.o: /usr/include/pulse/channelmap.h
src/screen_menu.o: /usr/include/pulse/context.h
src/screen_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/screen_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/screen_menu.o: /usr/include/pulse/introspect.h
src/screen_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/screen_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/screen_menu.o: /usr/include/pulse/utf8.h
src/screen_menu.o: /usr/include/pulse/thread-mainloop.h
src/screen_menu.o: /usr/include/pulse/mainloop.h
src/screen_menu.o: /usr/include/pulse/mainloop-signal.h
src/screen_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/screen_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/screen_menu.o: src/transmitter.h src/new_menu.h src/main.h
src/screen_menu.o: src/appearance.h src/message.h
src/server_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/server_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/server_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/server_menu.o: /usr/include/string.h /usr/include/strings.h
src/server_menu.o: /usr/include/termios.h /usr/include/unistd.h
src/server_menu.o: src/new_menu.h src/server_menu.h src/radio.h src/adc.h
src/server_menu.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/server_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/server_menu.o: /usr/include/SoapySDR/Config.h
src/server_menu.o: /usr/include/SoapySDR/Types.h
src/server_menu.o: /usr/include/SoapySDR/Constants.h
src/server_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/server_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/server_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/server_menu.o: /usr/include/fcntl.h /usr/include/assert.h
src/server_menu.o: /usr/include/poll.h /usr/include/errno.h
src/server_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/server_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/server_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/server_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/server_menu.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/server_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/server_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/server_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/server_menu.o: /usr/include/alsa/seqmid.h
src/server_menu.o: /usr/include/alsa/seq_midi_event.h
src/server_menu.o: /usr/include/pulse/pulseaudio.h
src/server_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/server_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/server_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/server_menu.o: /usr/include/pulse/version.h
src/server_menu.o: /usr/include/pulse/mainloop-api.h
src/server_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/server_menu.o: /usr/include/pulse/channelmap.h
src/server_menu.o: /usr/include/pulse/context.h
src/server_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/server_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/server_menu.o: /usr/include/pulse/introspect.h
src/server_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/server_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/server_menu.o: /usr/include/pulse/utf8.h
src/server_menu.o: /usr/include/pulse/thread-mainloop.h
src/server_menu.o: /usr/include/pulse/mainloop.h
src/server_menu.o: /usr/include/pulse/mainloop-signal.h
src/server_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/server_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/server_menu.o: src/transmitter.h src/client_server.h
src/sliders.o: /usr/include/semaphore.h /usr/include/features.h
src/sliders.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/sliders.o: /usr/include/stdio.h /usr/include/stdlib.h
src/sliders.o: /usr/include/alloca.h /usr/include/math.h src/appearance.h
src/sliders.o: src/receiver.h /usr/include/portaudio.h
src/sliders.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/sliders.o: /usr/include/string.h /usr/include/strings.h
src/sliders.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/sliders.o: /usr/include/errno.h /usr/include/endian.h
src/sliders.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/sliders.o: /usr/include/alsa/global.h /usr/include/time.h
src/sliders.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/sliders.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/sliders.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/sliders.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/sliders.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/sliders.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/sliders.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/sliders.o: /usr/include/alsa/seq_midi_event.h
src/sliders.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/sliders.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/sliders.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/sliders.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/sliders.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/sliders.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/sliders.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/sliders.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/sliders.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/sliders.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/sliders.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/sliders.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/sliders.o: /usr/include/pulse/mainloop.h
src/sliders.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/sliders.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/sliders.o: /usr/include/pulse/simple.h src/sliders.h src/transmitter.h
src/sliders.o: src/actions.h src/mode.h src/filter.h src/bandstack.h
src/sliders.o: src/band.h src/discovered.h /usr/include/netinet/in.h
src/sliders.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/sliders.o: /usr/include/SoapySDR/Types.h
src/sliders.o: /usr/include/SoapySDR/Constants.h
src/sliders.o: /usr/include/SoapySDR/Errors.h src/new_protocol.h src/MacOS.h
src/sliders.o: src/soapy_protocol.h src/vfo.h src/agc.h src/channel.h
src/sliders.o: src/radio.h src/adc.h src/dac.h src/property.h src/mystring.h
src/sliders.o: src/main.h src/ext.h src/client_server.h src/message.h
src/soapy_discovery.o: /usr/include/stdio.h /usr/include/stdlib.h
src/soapy_discovery.o: /usr/include/alloca.h /usr/include/features.h
src/soapy_discovery.o: /usr/include/features-time64.h
src/soapy_discovery.o: /usr/include/stdc-predef.h /usr/include/string.h
src/soapy_discovery.o: /usr/include/strings.h /usr/include/SoapySDR/Device.h
src/soapy_discovery.o: /usr/include/SoapySDR/Config.h
src/soapy_discovery.o: /usr/include/SoapySDR/Types.h
src/soapy_discovery.o: /usr/include/SoapySDR/Constants.h
src/soapy_discovery.o: /usr/include/SoapySDR/Errors.h
src/soapy_discovery.o: /usr/include/SoapySDR/Formats.h src/discovered.h
src/soapy_discovery.o: /usr/include/netinet/in.h /usr/include/endian.h
src/soapy_discovery.o: src/soapy_discovery.h src/message.h src/mystring.h
src/soapy_protocol.o: /usr/include/stdio.h /usr/include/stdlib.h
src/soapy_protocol.o: /usr/include/alloca.h /usr/include/features.h
src/soapy_protocol.o: /usr/include/features-time64.h
src/soapy_protocol.o: /usr/include/stdc-predef.h /usr/include/unistd.h
src/soapy_protocol.o: /usr/include/signal.h /usr/include/SoapySDR/Constants.h
src/soapy_protocol.o: /usr/include/SoapySDR/Config.h
src/soapy_protocol.o: /usr/include/SoapySDR/Device.h
src/soapy_protocol.o: /usr/include/SoapySDR/Types.h
src/soapy_protocol.o: /usr/include/SoapySDR/Errors.h
src/soapy_protocol.o: /usr/include/SoapySDR/Formats.h
src/soapy_protocol.o: /usr/include/SoapySDR/Version.h
src/soapy_protocol.o: /usr/include/SoapySDR/Logger.h src/band.h
src/soapy_protocol.o: src/bandstack.h src/channel.h src/discovered.h
src/soapy_protocol.o: /usr/include/netinet/in.h /usr/include/endian.h
src/soapy_protocol.o: src/mode.h src/filter.h src/receiver.h
src/soapy_protocol.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/soapy_protocol.o: /usr/include/string.h /usr/include/strings.h
src/soapy_protocol.o: /usr/include/fcntl.h /usr/include/assert.h
src/soapy_protocol.o: /usr/include/poll.h /usr/include/errno.h
src/soapy_protocol.o: /usr/include/alsa/asoundef.h
src/soapy_protocol.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/soapy_protocol.o: /usr/include/time.h /usr/include/alsa/input.h
src/soapy_protocol.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/soapy_protocol.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/soapy_protocol.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/soapy_protocol.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/soapy_protocol.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/soapy_protocol.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/soapy_protocol.o: /usr/include/alsa/seqmid.h
src/soapy_protocol.o: /usr/include/alsa/seq_midi_event.h
src/soapy_protocol.o: /usr/include/pulse/pulseaudio.h
src/soapy_protocol.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/soapy_protocol.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/soapy_protocol.o: /usr/include/pulse/sample.h
src/soapy_protocol.o: /usr/include/pulse/gccmacro.h
src/soapy_protocol.o: /usr/include/pulse/version.h
src/soapy_protocol.o: /usr/include/pulse/mainloop-api.h
src/soapy_protocol.o: /usr/include/pulse/format.h
src/soapy_protocol.o: /usr/include/pulse/proplist.h
src/soapy_protocol.o: /usr/include/pulse/channelmap.h
src/soapy_protocol.o: /usr/include/pulse/context.h
src/soapy_protocol.o: /usr/include/pulse/operation.h
src/soapy_protocol.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/soapy_protocol.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/soapy_protocol.o: /usr/include/pulse/subscribe.h
src/soapy_protocol.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/soapy_protocol.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/soapy_protocol.o: /usr/include/pulse/thread-mainloop.h
src/soapy_protocol.o: /usr/include/pulse/mainloop.h
src/soapy_protocol.o: /usr/include/pulse/mainloop-signal.h
src/soapy_protocol.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/soapy_protocol.o: /usr/include/pulse/rtclock.h
src/soapy_protocol.o: /usr/include/pulse/simple.h src/transmitter.h
src/soapy_protocol.o: src/radio.h src/adc.h src/dac.h src/main.h
src/soapy_protocol.o: src/soapy_protocol.h src/audio.h src/vfo.h src/ext.h
src/soapy_protocol.o: src/client_server.h src/message.h
src/startup.o: /usr/include/stdio.h /usr/include/fcntl.h
src/startup.o: /usr/include/features.h /usr/include/features-time64.h
src/startup.o: /usr/include/stdc-predef.h /usr/include/unistd.h
src/startup.o: /usr/include/stdlib.h /usr/include/alloca.h /usr/include/pwd.h
src/startup.o: src/message.h src/mystring.h /usr/include/string.h
src/startup.o: /usr/include/strings.h
src/stemlab_discovery.o: /usr/include/stdio.h /usr/include/stdlib.h
src/stemlab_discovery.o: /usr/include/alloca.h /usr/include/features.h
src/stemlab_discovery.o: /usr/include/features-time64.h
src/stemlab_discovery.o: /usr/include/stdc-predef.h /usr/include/net/if.h
src/stemlab_discovery.o: /usr/include/arpa/inet.h /usr/include/netinet/in.h
src/stemlab_discovery.o: /usr/include/endian.h /usr/include/string.h
src/stemlab_discovery.o: /usr/include/strings.h /usr/include/unistd.h
src/stemlab_discovery.o: /usr/include/stdint.h src/discovered.h
src/stemlab_discovery.o: /usr/include/SoapySDR/Device.h
src/stemlab_discovery.o: /usr/include/SoapySDR/Config.h
src/stemlab_discovery.o: /usr/include/SoapySDR/Types.h
src/stemlab_discovery.o: /usr/include/SoapySDR/Constants.h
src/stemlab_discovery.o: /usr/include/SoapySDR/Errors.h src/discovery.h
src/stemlab_discovery.o: src/radio.h src/adc.h src/dac.h src/receiver.h
src/stemlab_discovery.o: /usr/include/portaudio.h
src/stemlab_discovery.o: /usr/include/alsa/asoundlib.h /usr/include/fcntl.h
src/stemlab_discovery.o: /usr/include/assert.h /usr/include/poll.h
src/stemlab_discovery.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/stemlab_discovery.o: /usr/include/alsa/version.h
src/stemlab_discovery.o: /usr/include/alsa/global.h /usr/include/time.h
src/stemlab_discovery.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/stemlab_discovery.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/stemlab_discovery.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/stemlab_discovery.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/stemlab_discovery.o: /usr/include/alsa/control.h
src/stemlab_discovery.o: /usr/include/alsa/mixer.h
src/stemlab_discovery.o: /usr/include/alsa/seq_event.h
src/stemlab_discovery.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/stemlab_discovery.o: /usr/include/alsa/seq_midi_event.h
src/stemlab_discovery.o: /usr/include/pulse/pulseaudio.h
src/stemlab_discovery.o: /usr/include/pulse/direction.h
src/stemlab_discovery.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/stemlab_discovery.o: /usr/include/pulse/cdecl.h
src/stemlab_discovery.o: /usr/include/pulse/sample.h
src/stemlab_discovery.o: /usr/include/pulse/gccmacro.h
src/stemlab_discovery.o: /usr/include/pulse/version.h
src/stemlab_discovery.o: /usr/include/pulse/mainloop-api.h
src/stemlab_discovery.o: /usr/include/pulse/format.h
src/stemlab_discovery.o: /usr/include/pulse/proplist.h
src/stemlab_discovery.o: /usr/include/pulse/channelmap.h
src/stemlab_discovery.o: /usr/include/pulse/context.h
src/stemlab_discovery.o: /usr/include/pulse/operation.h
src/stemlab_discovery.o: /usr/include/pulse/stream.h
src/stemlab_discovery.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/stemlab_discovery.o: /usr/include/pulse/introspect.h
src/stemlab_discovery.o: /usr/include/pulse/subscribe.h
src/stemlab_discovery.o: /usr/include/pulse/scache.h
src/stemlab_discovery.o: /usr/include/pulse/error.h
src/stemlab_discovery.o: /usr/include/pulse/xmalloc.h
src/stemlab_discovery.o: /usr/include/pulse/utf8.h
src/stemlab_discovery.o: /usr/include/pulse/thread-mainloop.h
src/stemlab_discovery.o: /usr/include/pulse/mainloop.h
src/stemlab_discovery.o: /usr/include/pulse/mainloop-signal.h
src/stemlab_discovery.o: /usr/include/pulse/util.h
src/stemlab_discovery.o: /usr/include/pulse/timeval.h
src/stemlab_discovery.o: /usr/include/pulse/rtclock.h
src/stemlab_discovery.o: /usr/include/pulse/simple.h src/transmitter.h
src/stemlab_discovery.o: src/message.h src/mystring.h
src/store.o: /usr/include/stdio.h /usr/include/stdlib.h /usr/include/alloca.h
src/store.o: /usr/include/features.h /usr/include/features-time64.h
src/store.o: /usr/include/stdc-predef.h /usr/include/string.h
src/store.o: /usr/include/strings.h src/bandstack.h src/band.h src/filter.h
src/store.o: src/mode.h src/property.h src/mystring.h src/store.h
src/store.o: src/store_menu.h src/radio.h src/adc.h src/dac.h
src/store.o: src/discovered.h /usr/include/netinet/in.h /usr/include/endian.h
src/store.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/store.o: /usr/include/SoapySDR/Types.h /usr/include/SoapySDR/Constants.h
src/store.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/store.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/store.o: /usr/include/unistd.h /usr/include/fcntl.h /usr/include/assert.h
src/store.o: /usr/include/poll.h /usr/include/errno.h
src/store.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/store.o: /usr/include/alsa/global.h /usr/include/time.h
src/store.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/store.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/store.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/store.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/store.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/store.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/store.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/store.o: /usr/include/alsa/seq_midi_event.h
src/store.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/store.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/store.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/store.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/store.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/store.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/store.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/store.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/store.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/store.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/store.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/store.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/store.o: /usr/include/pulse/mainloop.h
src/store.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/store.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/store.o: /usr/include/pulse/simple.h src/transmitter.h src/ext.h
src/store.o: src/client_server.h src/vfo.h src/message.h
src/store_menu.o: /usr/include/stdio.h /usr/include/stdint.h
src/store_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/store_menu.o: /usr/include/features.h /usr/include/features-time64.h
src/store_menu.o: /usr/include/stdc-predef.h /usr/include/string.h
src/store_menu.o: /usr/include/strings.h src/radio.h src/adc.h src/dac.h
src/store_menu.o: src/discovered.h /usr/include/netinet/in.h
src/store_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/store_menu.o: /usr/include/SoapySDR/Config.h
src/store_menu.o: /usr/include/SoapySDR/Types.h
src/store_menu.o: /usr/include/SoapySDR/Constants.h
src/store_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/store_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/store_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/store_menu.o: /usr/include/assert.h /usr/include/poll.h
src/store_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/store_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/store_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/store_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/store_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/store_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/store_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/store_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/store_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/store_menu.o: /usr/include/alsa/seq_midi_event.h
src/store_menu.o: /usr/include/pulse/pulseaudio.h
src/store_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/store_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/store_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/store_menu.o: /usr/include/pulse/version.h
src/store_menu.o: /usr/include/pulse/mainloop-api.h
src/store_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/store_menu.o: /usr/include/pulse/channelmap.h
src/store_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/store_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/store_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/store_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/store_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/store_menu.o: /usr/include/pulse/utf8.h
src/store_menu.o: /usr/include/pulse/thread-mainloop.h
src/store_menu.o: /usr/include/pulse/mainloop.h
src/store_menu.o: /usr/include/pulse/mainloop-signal.h
src/store_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/store_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/store_menu.o: src/transmitter.h src/new_menu.h src/store_menu.h
src/store_menu.o: src/store.h src/bandstack.h src/mode.h src/filter.h
src/store_menu.o: src/message.h
src/switch_menu.o: /usr/include/stdio.h /usr/include/string.h
src/switch_menu.o: /usr/include/strings.h /usr/include/features.h
src/switch_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/switch_menu.o: src/main.h src/new_menu.h src/agc_menu.h src/agc.h
src/switch_menu.o: src/band.h src/bandstack.h src/channel.h src/radio.h
src/switch_menu.o: src/adc.h src/dac.h src/discovered.h
src/switch_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/switch_menu.o: /usr/include/SoapySDR/Device.h
src/switch_menu.o: /usr/include/SoapySDR/Config.h
src/switch_menu.o: /usr/include/SoapySDR/Types.h
src/switch_menu.o: /usr/include/SoapySDR/Constants.h
src/switch_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/switch_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/switch_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/switch_menu.o: /usr/include/alloca.h /usr/include/fcntl.h
src/switch_menu.o: /usr/include/assert.h /usr/include/poll.h
src/switch_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/switch_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/switch_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/switch_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/switch_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/switch_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/switch_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/switch_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/switch_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/switch_menu.o: /usr/include/alsa/seqmid.h
src/switch_menu.o: /usr/include/alsa/seq_midi_event.h
src/switch_menu.o: /usr/include/pulse/pulseaudio.h
src/switch_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/switch_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/switch_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/switch_menu.o: /usr/include/pulse/version.h
src/switch_menu.o: /usr/include/pulse/mainloop-api.h
src/switch_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/switch_menu.o: /usr/include/pulse/channelmap.h
src/switch_menu.o: /usr/include/pulse/context.h
src/switch_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/switch_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/switch_menu.o: /usr/include/pulse/introspect.h
src/switch_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/switch_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/switch_menu.o: /usr/include/pulse/utf8.h
src/switch_menu.o: /usr/include/pulse/thread-mainloop.h
src/switch_menu.o: /usr/include/pulse/mainloop.h
src/switch_menu.o: /usr/include/pulse/mainloop-signal.h
src/switch_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/switch_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/switch_menu.o: src/transmitter.h src/vfo.h src/mode.h src/toolbar.h
src/switch_menu.o: src/gpio.h src/actions.h src/action_dialog.h src/i2c.h
src/toolbar.o: /usr/include/semaphore.h /usr/include/features.h
src/toolbar.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/toolbar.o: /usr/include/stdio.h /usr/include/stdint.h
src/toolbar.o: /usr/include/stdlib.h /usr/include/alloca.h
src/toolbar.o: /usr/include/string.h /usr/include/strings.h src/actions.h
src/toolbar.o: src/gpio.h src/toolbar.h src/mode.h src/filter.h
src/toolbar.o: src/bandstack.h src/band.h src/discovered.h
src/toolbar.o: /usr/include/netinet/in.h /usr/include/endian.h
src/toolbar.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/toolbar.o: /usr/include/SoapySDR/Types.h
src/toolbar.o: /usr/include/SoapySDR/Constants.h
src/toolbar.o: /usr/include/SoapySDR/Errors.h src/new_protocol.h src/MacOS.h
src/toolbar.o: /usr/include/time.h src/receiver.h /usr/include/portaudio.h
src/toolbar.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/toolbar.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/toolbar.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/toolbar.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/toolbar.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/toolbar.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/toolbar.o: /usr/include/alsa/pcm.h /usr/include/alsa/rawmidi.h
src/toolbar.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/toolbar.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/toolbar.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/toolbar.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/toolbar.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/toolbar.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/toolbar.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/toolbar.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/toolbar.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/toolbar.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/toolbar.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/toolbar.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/toolbar.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/toolbar.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/toolbar.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/toolbar.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/toolbar.o: /usr/include/pulse/mainloop.h
src/toolbar.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/toolbar.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/toolbar.o: /usr/include/pulse/simple.h src/old_protocol.h src/vfo.h
src/toolbar.o: src/agc.h src/channel.h src/radio.h src/adc.h src/dac.h
src/toolbar.o: src/transmitter.h src/property.h src/mystring.h src/new_menu.h
src/toolbar.o: src/ext.h src/client_server.h src/message.h
src/toolbar_menu.o: /usr/include/stdio.h /usr/include/string.h
src/toolbar_menu.o: /usr/include/strings.h /usr/include/features.h
src/toolbar_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/toolbar_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/toolbar_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/toolbar_menu.o: /usr/include/SoapySDR/Device.h
src/toolbar_menu.o: /usr/include/SoapySDR/Config.h
src/toolbar_menu.o: /usr/include/SoapySDR/Types.h
src/toolbar_menu.o: /usr/include/SoapySDR/Constants.h
src/toolbar_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/toolbar_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/toolbar_menu.o: /usr/include/unistd.h /usr/include/stdlib.h
src/toolbar_menu.o: /usr/include/alloca.h /usr/include/fcntl.h
src/toolbar_menu.o: /usr/include/assert.h /usr/include/poll.h
src/toolbar_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/toolbar_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/toolbar_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/toolbar_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/toolbar_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/toolbar_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/toolbar_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/toolbar_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/toolbar_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/toolbar_menu.o: /usr/include/alsa/seqmid.h
src/toolbar_menu.o: /usr/include/alsa/seq_midi_event.h
src/toolbar_menu.o: /usr/include/pulse/pulseaudio.h
src/toolbar_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/toolbar_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/toolbar_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/toolbar_menu.o: /usr/include/pulse/version.h
src/toolbar_menu.o: /usr/include/pulse/mainloop-api.h
src/toolbar_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/toolbar_menu.o: /usr/include/pulse/channelmap.h
src/toolbar_menu.o: /usr/include/pulse/context.h
src/toolbar_menu.o: /usr/include/pulse/operation.h
src/toolbar_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/toolbar_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/toolbar_menu.o: /usr/include/pulse/subscribe.h
src/toolbar_menu.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/toolbar_menu.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/toolbar_menu.o: /usr/include/pulse/thread-mainloop.h
src/toolbar_menu.o: /usr/include/pulse/mainloop.h
src/toolbar_menu.o: /usr/include/pulse/mainloop-signal.h
src/toolbar_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/toolbar_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/toolbar_menu.o: src/transmitter.h src/new_menu.h src/actions.h
src/toolbar_menu.o: src/action_dialog.h src/gpio.h src/toolbar.h
src/transmitter.o: /usr/include/math.h /usr/include/stdio.h
src/transmitter.o: /usr/include/stdlib.h /usr/include/alloca.h
src/transmitter.o: /usr/include/features.h /usr/include/features-time64.h
src/transmitter.o: /usr/include/stdc-predef.h src/band.h src/bandstack.h
src/transmitter.o: src/channel.h src/main.h src/receiver.h
src/transmitter.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/transmitter.o: /usr/include/unistd.h /usr/include/string.h
src/transmitter.o: /usr/include/strings.h /usr/include/fcntl.h
src/transmitter.o: /usr/include/assert.h /usr/include/poll.h
src/transmitter.o: /usr/include/errno.h /usr/include/endian.h
src/transmitter.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/transmitter.o: /usr/include/alsa/global.h /usr/include/time.h
src/transmitter.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/transmitter.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/transmitter.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/transmitter.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/transmitter.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/transmitter.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/transmitter.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/transmitter.o: /usr/include/alsa/seq_midi_event.h
src/transmitter.o: /usr/include/pulse/pulseaudio.h
src/transmitter.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/transmitter.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/transmitter.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/transmitter.o: /usr/include/pulse/version.h
src/transmitter.o: /usr/include/pulse/mainloop-api.h
src/transmitter.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/transmitter.o: /usr/include/pulse/channelmap.h
src/transmitter.o: /usr/include/pulse/context.h
src/transmitter.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/transmitter.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/transmitter.o: /usr/include/pulse/introspect.h
src/transmitter.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/transmitter.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/transmitter.o: /usr/include/pulse/utf8.h
src/transmitter.o: /usr/include/pulse/thread-mainloop.h
src/transmitter.o: /usr/include/pulse/mainloop.h
src/transmitter.o: /usr/include/pulse/mainloop-signal.h
src/transmitter.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/transmitter.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/transmitter.o: src/meter.h src/filter.h src/mode.h src/property.h
src/transmitter.o: src/mystring.h src/radio.h src/adc.h src/dac.h
src/transmitter.o: src/discovered.h /usr/include/netinet/in.h
src/transmitter.o: /usr/include/SoapySDR/Device.h
src/transmitter.o: /usr/include/SoapySDR/Config.h
src/transmitter.o: /usr/include/SoapySDR/Types.h
src/transmitter.o: /usr/include/SoapySDR/Constants.h
src/transmitter.o: /usr/include/SoapySDR/Errors.h src/transmitter.h src/vfo.h
src/transmitter.o: src/vox.h src/toolbar.h src/gpio.h src/tx_panadapter.h
src/transmitter.o: src/waterfall.h src/new_protocol.h src/MacOS.h
src/transmitter.o: /usr/include/semaphore.h src/old_protocol.h src/ps_menu.h
src/transmitter.o: src/soapy_protocol.h src/audio.h src/ext.h
src/transmitter.o: src/client_server.h src/sliders.h src/actions.h
src/transmitter.o: src/ozyio.h src/sintab.h src/message.h
src/tx_menu.o: /usr/include/stdio.h /usr/include/string.h
src/tx_menu.o: /usr/include/strings.h /usr/include/features.h
src/tx_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/tx_menu.o: src/audio.h src/receiver.h /usr/include/portaudio.h
src/tx_menu.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/tx_menu.o: /usr/include/stdlib.h /usr/include/alloca.h
src/tx_menu.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/tx_menu.o: /usr/include/errno.h /usr/include/endian.h
src/tx_menu.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/tx_menu.o: /usr/include/alsa/global.h /usr/include/time.h
src/tx_menu.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/tx_menu.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/tx_menu.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/tx_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/tx_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/tx_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/tx_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/tx_menu.o: /usr/include/alsa/seq_midi_event.h
src/tx_menu.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/tx_menu.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/tx_menu.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/tx_menu.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/tx_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/tx_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/tx_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/tx_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/tx_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/tx_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/tx_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/tx_menu.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/tx_menu.o: /usr/include/pulse/mainloop.h
src/tx_menu.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/tx_menu.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/tx_menu.o: /usr/include/pulse/simple.h src/new_menu.h src/radio.h
src/tx_menu.o: src/adc.h src/dac.h src/discovered.h /usr/include/netinet/in.h
src/tx_menu.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/tx_menu.o: /usr/include/SoapySDR/Types.h
src/tx_menu.o: /usr/include/SoapySDR/Constants.h
src/tx_menu.o: /usr/include/SoapySDR/Errors.h src/transmitter.h src/sliders.h
src/tx_menu.o: src/actions.h src/ext.h src/client_server.h src/filter.h
src/tx_menu.o: src/mode.h src/vfo.h src/new_protocol.h src/MacOS.h
src/tx_menu.o: /usr/include/semaphore.h src/message.h src/mystring.h
src/tx_panadapter.o: /usr/include/math.h /usr/include/unistd.h
src/tx_panadapter.o: /usr/include/features.h /usr/include/features-time64.h
src/tx_panadapter.o: /usr/include/stdc-predef.h /usr/include/stdlib.h
src/tx_panadapter.o: /usr/include/alloca.h /usr/include/string.h
src/tx_panadapter.o: /usr/include/strings.h /usr/include/semaphore.h
src/tx_panadapter.o: src/appearance.h src/agc.h src/band.h src/bandstack.h
src/tx_panadapter.o: src/discovered.h /usr/include/netinet/in.h
src/tx_panadapter.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/tx_panadapter.o: /usr/include/SoapySDR/Config.h
src/tx_panadapter.o: /usr/include/SoapySDR/Types.h
src/tx_panadapter.o: /usr/include/SoapySDR/Constants.h
src/tx_panadapter.o: /usr/include/SoapySDR/Errors.h src/radio.h src/adc.h
src/tx_panadapter.o: src/dac.h src/receiver.h /usr/include/portaudio.h
src/tx_panadapter.o: /usr/include/alsa/asoundlib.h /usr/include/stdio.h
src/tx_panadapter.o: /usr/include/fcntl.h /usr/include/assert.h
src/tx_panadapter.o: /usr/include/poll.h /usr/include/errno.h
src/tx_panadapter.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/tx_panadapter.o: /usr/include/alsa/global.h /usr/include/time.h
src/tx_panadapter.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/tx_panadapter.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/tx_panadapter.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/tx_panadapter.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/tx_panadapter.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/tx_panadapter.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/tx_panadapter.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/tx_panadapter.o: /usr/include/alsa/seq_midi_event.h
src/tx_panadapter.o: /usr/include/pulse/pulseaudio.h
src/tx_panadapter.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/tx_panadapter.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/tx_panadapter.o: /usr/include/pulse/sample.h
src/tx_panadapter.o: /usr/include/pulse/gccmacro.h
src/tx_panadapter.o: /usr/include/pulse/version.h
src/tx_panadapter.o: /usr/include/pulse/mainloop-api.h
src/tx_panadapter.o: /usr/include/pulse/format.h
src/tx_panadapter.o: /usr/include/pulse/proplist.h
src/tx_panadapter.o: /usr/include/pulse/channelmap.h
src/tx_panadapter.o: /usr/include/pulse/context.h
src/tx_panadapter.o: /usr/include/pulse/operation.h
src/tx_panadapter.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/tx_panadapter.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/tx_panadapter.o: /usr/include/pulse/subscribe.h
src/tx_panadapter.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/tx_panadapter.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/tx_panadapter.o: /usr/include/pulse/thread-mainloop.h
src/tx_panadapter.o: /usr/include/pulse/mainloop.h
src/tx_panadapter.o: /usr/include/pulse/mainloop-signal.h
src/tx_panadapter.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/tx_panadapter.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/tx_panadapter.o: src/transmitter.h src/rx_panadapter.h
src/tx_panadapter.o: src/tx_panadapter.h src/vfo.h src/mode.h src/actions.h
src/tx_panadapter.o: src/gpio.h src/ext.h src/client_server.h src/new_menu.h
src/tx_panadapter.o: src/message.h
src/vfo.o: /usr/include/math.h /usr/include/semaphore.h
src/vfo.o: /usr/include/features.h /usr/include/features-time64.h
src/vfo.o: /usr/include/stdc-predef.h /usr/include/string.h
src/vfo.o: /usr/include/strings.h /usr/include/stdlib.h /usr/include/alloca.h
src/vfo.o: /usr/include/unistd.h /usr/include/netinet/in.h
src/vfo.o: /usr/include/endian.h /usr/include/arpa/inet.h
src/vfo.o: /usr/include/netdb.h /usr/include/rpc/netdb.h
src/vfo.o: /usr/include/net/if_arp.h /usr/include/stdint.h
src/vfo.o: /usr/include/net/if.h /usr/include/ifaddrs.h src/appearance.h
src/vfo.o: src/discovered.h /usr/include/SoapySDR/Device.h
src/vfo.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/vfo.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/vfo.o: src/main.h src/agc.h src/mode.h src/filter.h src/bandstack.h
src/vfo.o: src/band.h src/property.h src/mystring.h src/radio.h src/adc.h
src/vfo.o: src/dac.h src/receiver.h /usr/include/portaudio.h
src/vfo.o: /usr/include/alsa/asoundlib.h /usr/include/stdio.h
src/vfo.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/vfo.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/vfo.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/vfo.o: /usr/include/time.h /usr/include/alsa/input.h
src/vfo.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/vfo.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/vfo.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/vfo.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/vfo.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/vfo.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/vfo.o: /usr/include/alsa/seq_midi_event.h /usr/include/pulse/pulseaudio.h
src/vfo.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/vfo.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/vfo.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/vfo.o: /usr/include/pulse/version.h /usr/include/pulse/mainloop-api.h
src/vfo.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/vfo.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/vfo.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/vfo.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/vfo.o: /usr/include/pulse/introspect.h /usr/include/pulse/subscribe.h
src/vfo.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/vfo.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/vfo.o: /usr/include/pulse/thread-mainloop.h /usr/include/pulse/mainloop.h
src/vfo.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/vfo.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/vfo.o: /usr/include/pulse/simple.h src/transmitter.h src/new_protocol.h
src/vfo.o: src/MacOS.h src/soapy_protocol.h src/vfo.h src/channel.h
src/vfo.o: src/toolbar.h src/gpio.h src/new_menu.h src/rigctl.h
src/vfo.o: src/client_server.h src/ext.h src/actions.h src/message.h
src/vfo_menu.o: /usr/include/ctype.h /usr/include/features.h
src/vfo_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/vfo_menu.o: /usr/include/stdio.h /usr/include/string.h
src/vfo_menu.o: /usr/include/strings.h /usr/include/stdlib.h
src/vfo_menu.o: /usr/include/alloca.h /usr/include/stdint.h
src/vfo_menu.o: /usr/include/locale.h src/new_menu.h src/band.h
src/vfo_menu.o: src/bandstack.h src/filter.h src/mode.h src/radio.h src/adc.h
src/vfo_menu.o: src/dac.h src/discovered.h /usr/include/netinet/in.h
src/vfo_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/vfo_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/vfo_menu.o: /usr/include/SoapySDR/Constants.h
src/vfo_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/vfo_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/vfo_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/vfo_menu.o: /usr/include/assert.h /usr/include/poll.h
src/vfo_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/vfo_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/vfo_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/vfo_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/vfo_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/vfo_menu.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/vfo_menu.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/vfo_menu.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/vfo_menu.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/vfo_menu.o: /usr/include/alsa/seq_midi_event.h
src/vfo_menu.o: /usr/include/pulse/pulseaudio.h
src/vfo_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/vfo_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/vfo_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/vfo_menu.o: /usr/include/pulse/version.h
src/vfo_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/vfo_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/vfo_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/vfo_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/vfo_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/vfo_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/vfo_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/vfo_menu.o: /usr/include/pulse/utf8.h
src/vfo_menu.o: /usr/include/pulse/thread-mainloop.h
src/vfo_menu.o: /usr/include/pulse/mainloop.h
src/vfo_menu.o: /usr/include/pulse/mainloop-signal.h
src/vfo_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/vfo_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/vfo_menu.o: src/transmitter.h src/vfo.h src/ext.h src/client_server.h
src/vfo_menu.o: src/radio_menu.h
src/vox.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/vox.o: /usr/include/netinet/in.h /usr/include/features.h
src/vox.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/vox.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/vox.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/vox.o: /usr/include/SoapySDR/Constants.h /usr/include/SoapySDR/Errors.h
src/vox.o: src/receiver.h /usr/include/portaudio.h
src/vox.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/vox.o: /usr/include/stdio.h /usr/include/stdlib.h /usr/include/alloca.h
src/vox.o: /usr/include/string.h /usr/include/strings.h /usr/include/fcntl.h
src/vox.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/vox.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/vox.o: /usr/include/alsa/global.h /usr/include/time.h
src/vox.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/vox.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/vox.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/vox.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/vox.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/vox.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/vox.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/vox.o: /usr/include/alsa/seq_midi_event.h /usr/include/pulse/pulseaudio.h
src/vox.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/vox.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/vox.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/vox.o: /usr/include/pulse/version.h /usr/include/pulse/mainloop-api.h
src/vox.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/vox.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/vox.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/vox.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/vox.o: /usr/include/pulse/introspect.h /usr/include/pulse/subscribe.h
src/vox.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/vox.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/vox.o: /usr/include/pulse/thread-mainloop.h /usr/include/pulse/mainloop.h
src/vox.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/vox.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/vox.o: /usr/include/pulse/simple.h src/transmitter.h src/vox.h src/vfo.h
src/vox.o: src/mode.h src/ext.h src/client_server.h
src/vox_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/vox_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/vox_menu.o: /usr/include/stdio.h /usr/include/stdlib.h
src/vox_menu.o: /usr/include/alloca.h /usr/include/string.h
src/vox_menu.o: /usr/include/strings.h src/appearance.h src/led.h
src/vox_menu.o: src/new_menu.h src/radio.h src/adc.h src/dac.h
src/vox_menu.o: src/discovered.h /usr/include/netinet/in.h
src/vox_menu.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/vox_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/vox_menu.o: /usr/include/SoapySDR/Constants.h
src/vox_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/vox_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/vox_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/vox_menu.o: /usr/include/assert.h /usr/include/poll.h
src/vox_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/vox_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/vox_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/vox_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/vox_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/vox_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/vox_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/vox_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/vox_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/vox_menu.o: /usr/include/alsa/seqmid.h /usr/include/alsa/seq_midi_event.h
src/vox_menu.o: /usr/include/pulse/pulseaudio.h
src/vox_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/vox_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/vox_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/vox_menu.o: /usr/include/pulse/version.h
src/vox_menu.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/vox_menu.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/vox_menu.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/vox_menu.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/vox_menu.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/vox_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/vox_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/vox_menu.o: /usr/include/pulse/utf8.h
src/vox_menu.o: /usr/include/pulse/thread-mainloop.h
src/vox_menu.o: /usr/include/pulse/mainloop.h
src/vox_menu.o: /usr/include/pulse/mainloop-signal.h
src/vox_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/vox_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/vox_menu.o: src/transmitter.h src/vfo.h src/mode.h src/vox_menu.h
src/vox_menu.o: src/vox.h src/ext.h src/client_server.h src/message.h
src/waterfall.o: /usr/include/math.h /usr/include/unistd.h
src/waterfall.o: /usr/include/features.h /usr/include/features-time64.h
src/waterfall.o: /usr/include/stdc-predef.h /usr/include/semaphore.h
src/waterfall.o: /usr/include/string.h /usr/include/strings.h src/radio.h
src/waterfall.o: src/adc.h src/dac.h src/discovered.h
src/waterfall.o: /usr/include/netinet/in.h /usr/include/endian.h
src/waterfall.o: /usr/include/SoapySDR/Device.h
src/waterfall.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/waterfall.o: /usr/include/SoapySDR/Constants.h
src/waterfall.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/waterfall.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/waterfall.o: /usr/include/stdio.h /usr/include/stdlib.h
src/waterfall.o: /usr/include/alloca.h /usr/include/fcntl.h
src/waterfall.o: /usr/include/assert.h /usr/include/poll.h
src/waterfall.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/waterfall.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/waterfall.o: /usr/include/time.h /usr/include/alsa/input.h
src/waterfall.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/waterfall.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/waterfall.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/waterfall.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/waterfall.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/waterfall.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/waterfall.o: /usr/include/alsa/seqmid.h
src/waterfall.o: /usr/include/alsa/seq_midi_event.h
src/waterfall.o: /usr/include/pulse/pulseaudio.h
src/waterfall.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/waterfall.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/waterfall.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/waterfall.o: /usr/include/pulse/version.h
src/waterfall.o: /usr/include/pulse/mainloop-api.h
src/waterfall.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/waterfall.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/waterfall.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/waterfall.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/waterfall.o: /usr/include/pulse/introspect.h
src/waterfall.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/waterfall.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/waterfall.o: /usr/include/pulse/utf8.h
src/waterfall.o: /usr/include/pulse/thread-mainloop.h
src/waterfall.o: /usr/include/pulse/mainloop.h
src/waterfall.o: /usr/include/pulse/mainloop-signal.h
src/waterfall.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/waterfall.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/waterfall.o: src/transmitter.h src/vfo.h src/mode.h src/band.h
src/waterfall.o: src/bandstack.h src/waterfall.h src/client_server.h
src/xvtr_menu.o: /usr/include/semaphore.h /usr/include/features.h
src/xvtr_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/xvtr_menu.o: /usr/include/stdio.h /usr/include/stdlib.h
src/xvtr_menu.o: /usr/include/alloca.h /usr/include/string.h
src/xvtr_menu.o: /usr/include/strings.h src/new_menu.h src/band.h
src/xvtr_menu.o: src/bandstack.h src/filter.h src/mode.h src/xvtr_menu.h
src/xvtr_menu.o: src/radio.h src/adc.h src/dac.h src/discovered.h
src/xvtr_menu.o: /usr/include/netinet/in.h /usr/include/endian.h
src/xvtr_menu.o: /usr/include/SoapySDR/Device.h
src/xvtr_menu.o: /usr/include/SoapySDR/Config.h /usr/include/SoapySDR/Types.h
src/xvtr_menu.o: /usr/include/SoapySDR/Constants.h
src/xvtr_menu.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/xvtr_menu.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/xvtr_menu.o: /usr/include/unistd.h /usr/include/fcntl.h
src/xvtr_menu.o: /usr/include/assert.h /usr/include/poll.h
src/xvtr_menu.o: /usr/include/errno.h /usr/include/alsa/asoundef.h
src/xvtr_menu.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/xvtr_menu.o: /usr/include/time.h /usr/include/alsa/input.h
src/xvtr_menu.o: /usr/include/alsa/output.h /usr/include/alsa/error.h
src/xvtr_menu.o: /usr/include/alsa/conf.h /usr/include/alsa/pcm.h
src/xvtr_menu.o: /usr/include/stdint.h /usr/include/alsa/rawmidi.h
src/xvtr_menu.o: /usr/include/alsa/timer.h /usr/include/alsa/hwdep.h
src/xvtr_menu.o: /usr/include/alsa/control.h /usr/include/alsa/mixer.h
src/xvtr_menu.o: /usr/include/alsa/seq_event.h /usr/include/alsa/seq.h
src/xvtr_menu.o: /usr/include/alsa/seqmid.h
src/xvtr_menu.o: /usr/include/alsa/seq_midi_event.h
src/xvtr_menu.o: /usr/include/pulse/pulseaudio.h
src/xvtr_menu.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/xvtr_menu.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/xvtr_menu.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/xvtr_menu.o: /usr/include/pulse/version.h
src/xvtr_menu.o: /usr/include/pulse/mainloop-api.h
src/xvtr_menu.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/xvtr_menu.o: /usr/include/pulse/channelmap.h /usr/include/pulse/context.h
src/xvtr_menu.o: /usr/include/pulse/operation.h /usr/include/pulse/stream.h
src/xvtr_menu.o: /usr/include/pulse/volume.h /usr/include/limits.h
src/xvtr_menu.o: /usr/include/pulse/introspect.h
src/xvtr_menu.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/xvtr_menu.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/xvtr_menu.o: /usr/include/pulse/utf8.h
src/xvtr_menu.o: /usr/include/pulse/thread-mainloop.h
src/xvtr_menu.o: /usr/include/pulse/mainloop.h
src/xvtr_menu.o: /usr/include/pulse/mainloop-signal.h
src/xvtr_menu.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/xvtr_menu.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/xvtr_menu.o: src/transmitter.h src/vfo.h src/message.h src/mystring.h
src/zoompan.o: /usr/include/semaphore.h /usr/include/features.h
src/zoompan.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/zoompan.o: /usr/include/stdio.h /usr/include/stdlib.h
src/zoompan.o: /usr/include/alloca.h /usr/include/math.h src/appearance.h
src/zoompan.o: src/main.h src/receiver.h /usr/include/portaudio.h
src/zoompan.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/zoompan.o: /usr/include/string.h /usr/include/strings.h
src/zoompan.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/zoompan.o: /usr/include/errno.h /usr/include/endian.h
src/zoompan.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/zoompan.o: /usr/include/alsa/global.h /usr/include/time.h
src/zoompan.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/zoompan.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/zoompan.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/zoompan.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/zoompan.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/zoompan.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/zoompan.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/zoompan.o: /usr/include/alsa/seq_midi_event.h
src/zoompan.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/zoompan.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/zoompan.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/zoompan.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/zoompan.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/zoompan.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/zoompan.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/zoompan.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/zoompan.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/zoompan.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/zoompan.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/zoompan.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/zoompan.o: /usr/include/pulse/mainloop.h
src/zoompan.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/zoompan.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/zoompan.o: /usr/include/pulse/simple.h src/radio.h src/adc.h src/dac.h
src/zoompan.o: src/discovered.h /usr/include/netinet/in.h
src/zoompan.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/zoompan.o: /usr/include/SoapySDR/Types.h
src/zoompan.o: /usr/include/SoapySDR/Constants.h
src/zoompan.o: /usr/include/SoapySDR/Errors.h src/transmitter.h src/vfo.h
src/zoompan.o: src/mode.h src/sliders.h src/actions.h src/zoompan.h
src/zoompan.o: src/client_server.h src/ext.h src/message.h
src/MacOS.o: /usr/include/time.h /usr/include/features.h
src/MacOS.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/MacOS.o: /usr/include/semaphore.h
src/audio.o: src/receiver.h /usr/include/portaudio.h
src/audio.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/audio.o: /usr/include/features.h /usr/include/features-time64.h
src/audio.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/audio.o: /usr/include/stdlib.h /usr/include/alloca.h
src/audio.o: /usr/include/string.h /usr/include/strings.h
src/audio.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/audio.o: /usr/include/errno.h /usr/include/endian.h
src/audio.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/audio.o: /usr/include/alsa/global.h /usr/include/time.h
src/audio.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/audio.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/audio.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/audio.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/audio.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/audio.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/audio.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/audio.o: /usr/include/alsa/seq_midi_event.h
src/audio.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/audio.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/audio.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/audio.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/audio.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/audio.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/audio.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/audio.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/audio.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/audio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/audio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/audio.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/audio.o: /usr/include/pulse/mainloop.h
src/audio.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/audio.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/audio.o: /usr/include/pulse/simple.h
src/band.o: src/bandstack.h
src/client_server.o: /usr/include/stdint.h
src/discovered.o: /usr/include/netinet/in.h /usr/include/features.h
src/discovered.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/discovered.o: /usr/include/endian.h /usr/include/SoapySDR/Device.h
src/discovered.o: /usr/include/SoapySDR/Config.h
src/discovered.o: /usr/include/SoapySDR/Types.h
src/discovered.o: /usr/include/SoapySDR/Constants.h
src/discovered.o: /usr/include/SoapySDR/Errors.h
src/ext.o: src/client_server.h /usr/include/stdint.h
src/filter.o: src/mode.h
src/mystring.o: /usr/include/string.h /usr/include/strings.h
src/mystring.o: /usr/include/features.h /usr/include/features-time64.h
src/mystring.o: /usr/include/stdc-predef.h
src/new_protocol.o: src/MacOS.h /usr/include/time.h /usr/include/features.h
src/new_protocol.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/new_protocol.o: /usr/include/semaphore.h src/receiver.h
src/new_protocol.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/new_protocol.o: /usr/include/unistd.h /usr/include/stdio.h
src/new_protocol.o: /usr/include/stdlib.h /usr/include/alloca.h
src/new_protocol.o: /usr/include/string.h /usr/include/strings.h
src/new_protocol.o: /usr/include/fcntl.h /usr/include/assert.h
src/new_protocol.o: /usr/include/poll.h /usr/include/errno.h
src/new_protocol.o: /usr/include/endian.h /usr/include/alsa/asoundef.h
src/new_protocol.o: /usr/include/alsa/version.h /usr/include/alsa/global.h
src/new_protocol.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/new_protocol.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/new_protocol.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/new_protocol.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/new_protocol.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/new_protocol.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/new_protocol.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/new_protocol.o: /usr/include/alsa/seq_midi_event.h
src/new_protocol.o: /usr/include/pulse/pulseaudio.h
src/new_protocol.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/new_protocol.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/new_protocol.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/new_protocol.o: /usr/include/pulse/version.h
src/new_protocol.o: /usr/include/pulse/mainloop-api.h
src/new_protocol.o: /usr/include/pulse/format.h /usr/include/pulse/proplist.h
src/new_protocol.o: /usr/include/pulse/channelmap.h
src/new_protocol.o: /usr/include/pulse/context.h
src/new_protocol.o: /usr/include/pulse/operation.h
src/new_protocol.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/new_protocol.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/new_protocol.o: /usr/include/pulse/subscribe.h
src/new_protocol.o: /usr/include/pulse/scache.h /usr/include/pulse/error.h
src/new_protocol.o: /usr/include/pulse/xmalloc.h /usr/include/pulse/utf8.h
src/new_protocol.o: /usr/include/pulse/thread-mainloop.h
src/new_protocol.o: /usr/include/pulse/mainloop.h
src/new_protocol.o: /usr/include/pulse/mainloop-signal.h
src/new_protocol.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/new_protocol.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/pa_menu.o: /usr/include/stdio.h /usr/include/string.h
src/pa_menu.o: /usr/include/strings.h /usr/include/features.h
src/pa_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/property.o: src/mystring.h /usr/include/string.h /usr/include/strings.h
src/property.o: /usr/include/features.h /usr/include/features-time64.h
src/property.o: /usr/include/stdc-predef.h
src/radio.o: src/adc.h src/dac.h src/discovered.h /usr/include/netinet/in.h
src/radio.o: /usr/include/features.h /usr/include/features-time64.h
src/radio.o: /usr/include/stdc-predef.h /usr/include/endian.h
src/radio.o: /usr/include/SoapySDR/Device.h /usr/include/SoapySDR/Config.h
src/radio.o: /usr/include/SoapySDR/Types.h /usr/include/SoapySDR/Constants.h
src/radio.o: /usr/include/SoapySDR/Errors.h src/receiver.h
src/radio.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/radio.o: /usr/include/unistd.h /usr/include/stdio.h /usr/include/stdlib.h
src/radio.o: /usr/include/alloca.h /usr/include/string.h
src/radio.o: /usr/include/strings.h /usr/include/fcntl.h
src/radio.o: /usr/include/assert.h /usr/include/poll.h /usr/include/errno.h
src/radio.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/radio.o: /usr/include/alsa/global.h /usr/include/time.h
src/radio.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/radio.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/radio.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/radio.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/radio.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/radio.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/radio.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/radio.o: /usr/include/alsa/seq_midi_event.h
src/radio.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/radio.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/radio.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/radio.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/radio.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/radio.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/radio.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/radio.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/radio.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/radio.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/radio.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/radio.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/radio.o: /usr/include/pulse/mainloop.h
src/radio.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/radio.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/radio.o: /usr/include/pulse/simple.h src/transmitter.h
src/receiver.o: /usr/include/portaudio.h /usr/include/alsa/asoundlib.h
src/receiver.o: /usr/include/unistd.h /usr/include/features.h
src/receiver.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/receiver.o: /usr/include/stdio.h /usr/include/stdlib.h
src/receiver.o: /usr/include/alloca.h /usr/include/string.h
src/receiver.o: /usr/include/strings.h /usr/include/fcntl.h
src/receiver.o: /usr/include/assert.h /usr/include/poll.h
src/receiver.o: /usr/include/errno.h /usr/include/endian.h
src/receiver.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/receiver.o: /usr/include/alsa/global.h /usr/include/time.h
src/receiver.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/receiver.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/receiver.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/receiver.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/receiver.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/receiver.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/receiver.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/receiver.o: /usr/include/alsa/seq_midi_event.h
src/receiver.o: /usr/include/pulse/pulseaudio.h
src/receiver.o: /usr/include/pulse/direction.h /usr/include/pulse/def.h
src/receiver.o: /usr/include/inttypes.h /usr/include/pulse/cdecl.h
src/receiver.o: /usr/include/pulse/sample.h /usr/include/pulse/gccmacro.h
src/receiver.o: /usr/include/pulse/version.h
src/receiver.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/receiver.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/receiver.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/receiver.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/receiver.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/receiver.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/receiver.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/receiver.o: /usr/include/pulse/utf8.h
src/receiver.o: /usr/include/pulse/thread-mainloop.h
src/receiver.o: /usr/include/pulse/mainloop.h
src/receiver.o: /usr/include/pulse/mainloop-signal.h
src/receiver.o: /usr/include/pulse/util.h /usr/include/pulse/timeval.h
src/receiver.o: /usr/include/pulse/rtclock.h /usr/include/pulse/simple.h
src/rigctl_menu.o: /usr/include/stdio.h /usr/include/string.h
src/rigctl_menu.o: /usr/include/strings.h /usr/include/features.h
src/rigctl_menu.o: /usr/include/features-time64.h /usr/include/stdc-predef.h
src/saturndrivers.o: /usr/include/stdint.h src/saturnregisters.h
src/saturnmain.o: src/saturnregisters.h /usr/include/stdint.h
src/saturnregisters.o: /usr/include/stdint.h
src/saturnserver.o: /usr/include/stdint.h /usr/include/netinet/in.h
src/saturnserver.o: /usr/include/features.h /usr/include/features-time64.h
src/saturnserver.o: /usr/include/stdc-predef.h /usr/include/endian.h
src/sliders.o: src/receiver.h /usr/include/portaudio.h
src/sliders.o: /usr/include/alsa/asoundlib.h /usr/include/unistd.h
src/sliders.o: /usr/include/features.h /usr/include/features-time64.h
src/sliders.o: /usr/include/stdc-predef.h /usr/include/stdio.h
src/sliders.o: /usr/include/stdlib.h /usr/include/alloca.h
src/sliders.o: /usr/include/string.h /usr/include/strings.h
src/sliders.o: /usr/include/fcntl.h /usr/include/assert.h /usr/include/poll.h
src/sliders.o: /usr/include/errno.h /usr/include/endian.h
src/sliders.o: /usr/include/alsa/asoundef.h /usr/include/alsa/version.h
src/sliders.o: /usr/include/alsa/global.h /usr/include/time.h
src/sliders.o: /usr/include/alsa/input.h /usr/include/alsa/output.h
src/sliders.o: /usr/include/alsa/error.h /usr/include/alsa/conf.h
src/sliders.o: /usr/include/alsa/pcm.h /usr/include/stdint.h
src/sliders.o: /usr/include/alsa/rawmidi.h /usr/include/alsa/timer.h
src/sliders.o: /usr/include/alsa/hwdep.h /usr/include/alsa/control.h
src/sliders.o: /usr/include/alsa/mixer.h /usr/include/alsa/seq_event.h
src/sliders.o: /usr/include/alsa/seq.h /usr/include/alsa/seqmid.h
src/sliders.o: /usr/include/alsa/seq_midi_event.h
src/sliders.o: /usr/include/pulse/pulseaudio.h /usr/include/pulse/direction.h
src/sliders.o: /usr/include/pulse/def.h /usr/include/inttypes.h
src/sliders.o: /usr/include/pulse/cdecl.h /usr/include/pulse/sample.h
src/sliders.o: /usr/include/pulse/gccmacro.h /usr/include/pulse/version.h
src/sliders.o: /usr/include/pulse/mainloop-api.h /usr/include/pulse/format.h
src/sliders.o: /usr/include/pulse/proplist.h /usr/include/pulse/channelmap.h
src/sliders.o: /usr/include/pulse/context.h /usr/include/pulse/operation.h
src/sliders.o: /usr/include/pulse/stream.h /usr/include/pulse/volume.h
src/sliders.o: /usr/include/limits.h /usr/include/pulse/introspect.h
src/sliders.o: /usr/include/pulse/subscribe.h /usr/include/pulse/scache.h
src/sliders.o: /usr/include/pulse/error.h /usr/include/pulse/xmalloc.h
src/sliders.o: /usr/include/pulse/utf8.h /usr/include/pulse/thread-mainloop.h
src/sliders.o: /usr/include/pulse/mainloop.h
src/sliders.o: /usr/include/pulse/mainloop-signal.h /usr/include/pulse/util.h
src/sliders.o: /usr/include/pulse/timeval.h /usr/include/pulse/rtclock.h
src/sliders.o: /usr/include/pulse/simple.h src/transmitter.h src/actions.h
src/store.o: src/bandstack.h
src/toolbar.o: src/gpio.h
src/vfo.o: src/mode.h
