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

VERSION=VersionGoesHere
APPLICATION=ApplicationGoesHere
INSTALL_DIR=/opt/${APPLICATION}
SILENT=0

# Silent running if requested:
if [ "$1" == "--silent" ]; then
  SILENT=1
  shift
fi

# Find out where we were launched from and make sure
# that our application jar file lives there.
# This is the minimum we can check here.
SRCDIR=`realpath $0`
SRCDIR=`dirname ${SRCDIR}`
if [ ! -f ${SRCDIR}/${APPLICATION}.jar ]; then
  echo "${APPLICATION} not found in installer directory; aborting."
  exit 1
fi
PREVDIR=`pwd`
cd ${SRCDIR}

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
    # That seems contrary to the nature of silent mode.
    # not much we can do about that though, as we need the root password here.
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
      # Need to make sure any old dependency jars or whatever are gone:
      rm -rf ${INSTALL_DIR}/*
    else
      echo "Aborting."
      exit 1
    fi
  fi
fi


# install:
for file in `/bin/ls` ; do
  if [ -d $file ]; then
    cp -r $file $INSTALL_DIR
  else
    cp $file $INSTALL_DIR
  fi
done

# Make note of the version that we just installed:
echo $VERSION > $INSTALL_DIR/.version

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
