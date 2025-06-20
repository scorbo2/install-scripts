#!/bin/bash
#
# Enumerates all sc-releases in ~/Releases and installs them.
# Intended for use on a new machine to make setup quick and easy.
#
# ASSUMPTIONS
#  1) ~/Releases exists and has at least one installer package in it
#  2) installer packages follow the format AppName-X.Y.tar.gz
#  3) application launcher scripts are named after the app
#  4) all apps that provide a logo.png want to have a desktop shortcut
#
# All installs will be done with default values:
#  - installation dir is /opt/AppName
#  - symlink to app launcher will be added to /usr/bin
#  - desktop shortcut will be created for all apps that support it
#
# scorbett 2022-03-27

# TODO should also read the extensions dir intelligently per application
#      and auto-install all extensions found for each app if possible.
#      That should be doable if the extensions were versioned diligently.
#      i.e. App-2.0 would have extensions like ext-app-2.0.1 and so on.
#           The first 2 digits of the extension version are the app version.

ME=`basename $0`

# TODO don't hardcode this
RELEASE_DIR=/home/scorbett/Releases

PREVIEW_FILE=`mktemp`
INSTALL_FILE=`mktemp`
UPGRADE_FILE=`mktemp`
NOACTION_FILE=`mktemp`
PKG_FILE=`mktemp`

function die {
  echo "${ME}: $*"
  exit 1
}

# Parameter: application name
# this does nothing if logo.png is not present (eg. for a cmdline app)
function createDesktopShortcut {
  if [ -f /opt/${1}/logo.png ]; then
    SHORTCUT_FILE=`mktemp`
    # TODO this is all kinds of hard coded... how portable is this?
    echo "[Desktop Entry]" > $SHORTCUT_FILE
    echo "Version=1.0" >> $SHORTCUT_FILE
    echo "Type=Application" >> $SHORTCUT_FILE
    echo "Name=$1" >> $SHORTCUT_FILE
    echo "Comment=" >> $SHORTCUT_FILE
    echo "Exec=/opt/${1}/bin/${1}" >> $SHORTCUT_FILE
    echo "Icon=/opt/${1}/logo.png" >> $SHORTCUT_FILE
    echo "Path=/home/scorbett" >> $SHORTCUT_FILE
    echo "Terminal=false" >> $SHORTCUT_FILE
    echo "StartupNotify=false" >> $SHORTCUT_FILE
    chown scorbett:scorbett $SHORTCUT_FILE
    chmod 775 $SHORTCUT_FILE
    # TODO don't hardcode the user directory
    mv $SHORTCUT_FILE /home/scorbett/Desktop/${1}.desktop
  fi
}

# Get sudo access up front, because we'll need it:
if [ $UID -ne 0 ]; then
  sudo $0
  exit $?
fi

if [ ! -d $RELEASE_DIR ]; then
  die "Your Releases directory does not exist."
fi

# Get a unique listing of available application installer packages:
# TODO wow, hard coding everywhere. This whole script feels like a hack.
NAMES=`/bin/ls ${RELEASE_DIR}/*.tar.gz | cut -d \- -f 1 | sed "s/\/home\/scorbett\/Releases\///g" | uniq | sort`
if [ "${NAMES}" = "" ]; then
  die "Your Releases directory does not contain any recognized installer packages."
fi

# Figure out what we need to do, and generate a preview of it for the user:
for NAME in $NAMES; do
  HIGHEST_VERSION=`/bin/ls -v ${RELEASE_DIR}/${NAME}* | tail -1 | cut -d \- -f 2 | sed s/\.tar\.gz//g`

  if [ ! -d /opt/${NAME} ]; then
    echo "  ${NAME} ${HIGHEST_VERSION} will be installed." >> ${INSTALL_FILE}
    echo "${NAME}-${HIGHEST_VERSION}.tar.gz" >> ${PKG_FILE}
  else
    if [ ! -f /opt/${NAME}/.version ]; then
      echo "  ${NAME} (unknown installed version) will be upgraded to ${HIGHEST_VERSION}" >> ${UPGRADE_FILE}
      echo "${NAME}-${HIGHEST_VERSION}.tar.gz" >> ${PKG_FILE}
    else
      EXISTING_VERSION=`cat /opt/${NAME}/.version`
      OUTOFDATE=`echo "${HIGHEST_VERSION}>${EXISTING_VERSION}" | bc`
      if [ $OUTOFDATE -eq 1 ]; then
        echo "  ${NAME} ${EXISTING_VERSION} will be upgraded to ${HIGHEST_VERSION}" >> ${UPGRADE_FILE}
        echo "${NAME}-${HIGHEST_VERSION}.tar.gz" >> ${PKG_FILE}
      else
        echo "  ${NAME} ${EXISTING_VERSION} is already at the latest version." >> ${NOACTION_FILE}
      fi
    fi
  fi
done

# Show a preview of work to be done:
WORKTODO=0
if [ -s ${INSTALL_FILE} ]; then
  echo "To be installed:"
  cat ${INSTALL_FILE}
  WORKTODO=1
  echo
fi
if [ -s ${UPGRADE_FILE} ]; then
  echo "To be upgraded:"
  cat ${UPGRADE_FILE}
  WORKTODO=1
  echo
fi
if [ -s ${NOACTION_FILE} ]; then
  echo "No action needed:"
  cat ${NOACTION_FILE}
  echo
fi

# Prompt and do it:
if [ $WORKTODO -eq 1 ]; then
  echo -n "Proceed as above [Y/n]? "
  read input
  if [ "${input}" = "" -o "${input}" = "y" -o "${input}" = "Y" ]; then
    STARTDIR=`pwd`
    PKGLIST=`cat $PKG_FILE`
    for PKG in $PKGLIST; do
      APPNAME=`echo $PKG | cut -d \- -f 1`
      WORKDIR=`mktemp -d`
      cd $WORKDIR
      tar xf ${RELEASE_DIR}/$PKG
      cd ${APPNAME}*
      ./install.sh --silent
      cd $STARTDIR
      rm -rf $WORKDIR
      createDesktopShortcut $APPNAME
    done
  else
    echo "No action taken."
  fi
fi

# Cleanup:
rm ${INSTALL_FILE}
rm ${UPGRADE_FILE}
rm ${NOACTION_FILE}
rm ${PKG_FILE}

