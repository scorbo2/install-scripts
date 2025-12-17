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
CATEGORY=CategoryGoesHere
INSTALL_DIR=/opt/${APPLICATION}
SILENT=0

# Parameters: install dir, application name, user home dir
function createDesktopShortcut {
  SHORTCUT_FILE=`mktemp`
  echo "[Desktop Entry]" > $SHORTCUT_FILE
  echo "Version=1.0" >> $SHORTCUT_FILE
  echo "Type=Application" >> $SHORTCUT_FILE
  echo "Categories=${CATEGORY}" >> $SHORTCUT_FILE
  echo "Name=${2}" >> $SHORTCUT_FILE
  echo "Comment=" >> $SHORTCUT_FILE
  echo "Exec=${1}/bin/${2} %F" >> $SHORTCUT_FILE
  echo "Icon=${1}/logo.png" >> $SHORTCUT_FILE
  echo "Path=${3}" >> $SHORTCUT_FILE
  echo "Terminal=false" >> $SHORTCUT_FILE
  echo "StartupNotify=false" >> $SHORTCUT_FILE

  # If we were invoked via sudo, make sure ownership is correct:
  if [ -n "$SUDO_UID" ]; then
    chown ${SUDO_UID}:${SUDO_GID} $SHORTCUT_FILE
  fi
  chmod 775 $SHORTCUT_FILE
  mv $SHORTCUT_FILE ${3}/Desktop/${2}.desktop
}

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
  if [ "${file}" == "INSTALL.txt" ]; then
    continue;
  fi
  if [ -d "$file" ]; then
    cp -r "$file" "$INSTALL_DIR/"
  else
    cp "$file" "$INSTALL_DIR"
  fi
done

# Make note of the version that we just installed:
echo $VERSION > $INSTALL_DIR/.version

# Create a /usr/bin symlink if needed:
if [ $SILENT -eq 1 ]; then
  input="y"
else
  echo "Create a symlink in /usr/bin for easy access?"
  read input
fi
if [ "${input,,}" == "y" -o "${input,,}" == "yes" ]; then
  if [ $UID -ne 0 ]; then
    sudo ln -sf ${INSTALL_DIR}/bin/${APPLICATION} /usr/bin
  else
    ln -sf ${INSTALL_DIR}/bin/${APPLICATION} /usr/bin
  fi
fi

# Create a desktop shortcut if a logo.png was provided:
if [ -f ${INSTALL_DIR}/logo.png ]; then
  HOMEDIR=$HOME
  if [ -n "$SUDO_USER" ]; then
    # We were invoked via sudo, so find the originating user:
    HOMEDIR=$(eval echo ~$SUDO_USER)
  fi
  if [ $SILENT -eq 1 ]; then
    input="y"
  else
    echo "Create a desktop shortcut in ${HOMEDIR}/Desktop and a menu item?"
    read input
  fi
    if [ "${input,,}" == "y" -o "${input,,}" == "yes" ]; then
      createDesktopShortcut $INSTALL_DIR $APPLICATION $HOMEDIR

      # Also create a system menu item for the local user if possible.
      # (This depends on what version of linux we're running)
      if [ -d ${HOMEDIR}/.local/share/applications ]; then
        cp ${HOMEDIR}/Desktop/${APPLICATION}.desktop ${HOMEDIR}/.local/share/applications/
        update-desktop-database ${HOMEDIR}/.local/share/applications/ 2> /dev/null
      fi
    fi
fi

echo "Successfully installed ${APPLICATION} ${VERSION} to ${INSTALL_DIR}"
