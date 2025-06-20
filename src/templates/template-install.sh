#!/bin/bash

# ApplicationGoesHere installation script.
#
# USAGE: install.sh [--silent] [installPath]
#
# If --silent is specified, default answers will be
# assumed for all questions. Otherwise, the script
# will behave more interactively, prompting the user
# where needed.
#
# Note that the default behaviour in silent mode is to
# overwrite an existing install dir if needed!
# Use carefully.
#
# If installPath is not specified, you will be prompted
# for one (default value /opt/ApplicationGoesHere will
# be used in silent mode).
#
# If the target dir already exists, you'll get a chance to
# back out of the install. Proceeding means that any existing
# installation in that directory is overwritten.
#
# If you don't start this script as root, and you're trying
# to install to a non-regular-writable directory like /opt,
# then the script will prompt for a sudo password automatically.
#
# 2017-11-27 scorbett (copied from LogoGenerator and generified)
# 2022-05-05 scorbett Added silent mode for batch installs.

VERSION=VersionGoesHere
APPLICATION=ApplicationGoesHere
INSTALL_DIR=/opt/${APPLICATION}
SILENT=0

# Silent running if requested:
if [ "$1" == "--silent" ]; then
  SILENT=1
  shift
fi

# safety check, make sure we're running from dist/
if [ ! -f ./${APPLICATION}.jar -o ! -d ./lib ]; then
  echo "${APPLICATION} not found in current directory; aborting."
  exit 1
fi

# Prompt for installation dir if not provided.
if [ "$1" == "" ]; then
  if [ $SILENT -eq 0 ]; then
    echo "${APPLICATION} ${VERSION} installation"
      echo
      echo -n "Installation dir (default=${INSTALL_DIR}): "
      read newdir
      if [ ! "$newdir" == "" ]; then
        INSTALL_DIR=$newdir
      fi
  fi
else
  # or take it from the command line if it was provided:
  INSTALL_DIR=$1
fi

# Make sure we're running as root if the target dir isn't writable:
PARENT_DIR=`dirname $INSTALL_DIR`
if [ ! -w $PARENT_DIR ]; then
  if [ $UID -ne 0 ]; then
    SILENT_OPT=
    if [ $SILENT -eq 1 ]; then
      SILENT_OPT="--silent"
    fi
    # note this will prompt the user even if silent mode is activated...
    # not much we can do about that though
    sudo $0 ${SILENT_OPT} ${INSTALL_DIR}
    exit $?
  fi
fi

# Overwrite prompt:
if [ -d $INSTALL_DIR ]; then
  if [ $SILENT -eq 0 ]; then
    echo "${INSTALL_DIR} already exists, overwrite it?"
    read input;
    if [ "${input,,}" == "y" -o "${input,,}" == "yes" ]; then
      echo "Existing installation will be overwritten."
    else
      echo "Aborting."
      exit 1
    fi
  fi
fi


# install:
mkdir -p $INSTALL_DIR/lib
mkdir -p $INSTALL_DIR/bin
cp ${APPLICATION}.jar $INSTALL_DIR
cp -r lib/* $INSTALL_DIR/lib
cp -r bin/* $INSTALL_DIR/bin
cp logging.properties $INSTALL_DIR
cp logo.png $INSTALL_DIR
cp ReleaseNotes.txt $INSTALL_DIR
rm -f $INSTALL_DIR/.version
echo $VERSION >> $INSTALL_DIR/.version

# Create a /usr/bin symlink if needed:
if [ $SILENT -eq 1 ]; then
  input="y"
else
  echo "Installation complete. Create a symlink in /usr/bin for easy access?"
  read input
fi
if [ "${input,,}" == "y" -o "${input,,}" == "yes" ]; then
  if [ $UID -ne 0 ]; then
    sudo ln -sf ${INSTALL_DIR}/bin/${APPLICATION} /usr/bin
  else
    ln -sf ${INSTALL_DIR}/bin/${APPLICATION} /usr/bin
  fi
fi

echo "Successfully installed ${APPLICATION} ${VERSION} to ${INSTALL_DIR}"
