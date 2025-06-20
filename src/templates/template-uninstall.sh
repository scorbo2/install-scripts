#!/bin/bash

# ApplicationGoesHere uninstall script
#
# Will prompt for sudo access to do the removal.
#
# 2017-11-27 scorbett (copied from LogoGenerator and generified)

APPLICATION=ApplicationGoesHere

# Figure out where this script lives:
INSTALL_DIR=`dirname $0`

# If we got back a useless ".", convert to absolute path:
INSTALL_DIR=`readlink -e $INSTALL_DIR`

# Now look for the parent (because we're probably in bin):
INSTALL_DIR=`dirname $INSTALL_DIR`

# Make sure we're root:
if [ ${UID} -ne 0 ]; then
  sudo $0
  exit $?
fi

# Give user a chance to back out:
echo -n "Remove ${APPLICATION} from $INSTALL_DIR? "
read input
if [ "${input,,}" != "y" -a "${input,,}" != "yes" ]; then
  echo "Aborting."
  exit 1;
fi

# Remove symlink if one was added:
rm -f /usr/bin/${APPLICATION}

# Remove installation dir:
rm -rf $INSTALL_DIR

echo "${APPLICATION} successfully uninstalled. Goodbye."

