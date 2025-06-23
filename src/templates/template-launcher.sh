#!/bin/bash

# Invokes ApplicationGoesHere with default options.
APPLICATION=ApplicationGoesHere

# Figure out where the application configuration
# and extensions should be stored. You can alter
# these paths if you wish to store them elsewhere.
USER_HOME=`realpath ~`
APPLICATION_HOME="${USER_HOME}/.${APPLICATION}"
EXTENSIONS_DIR="${APPLICATION_HOME}/extensions"
JAVA_MEM="JavaMemGoesHere"

# We need to find the directory where ApplicationGoesHere is installed,
# and the name of the script that was invoked.
# Note readlink -f is used to disambiguate things in case we were
# invoked from a symlink  in /usr/bin or something.
INSTALL_DIR=`readlink -f $0`
INSTALL_DIR=`dirname $INSTALL_DIR`
INSTALL_DIR=`dirname $INSTALL_DIR`
# (two dirnames in a row - first gets the bin directory, second gets bin's parent,
# which by convention should be the actual application home directory).

if [ ! -f ${INSTALL_DIR}/${APPLICATION}.jar ]; then
  echo "${APPLICATION} does not seem to be installed."
  exit 1;
fi

# Try to find java on the current user's path:
JAVA=`which java`

# If this script was invoked via a desktop shortcut or panel launcher,
# then java may not be on the path. If so, fallback to looking in
# a conventional location:
if [ "${JAVA}" == "" ]; then
  JAVA=/opt/java/bin/java
  if [ ! -f $JAVA ]; then
    # Well, I don't know where it is.
    echo "Can't find java on your path."
    exit 1;
  fi
fi

# Invoke ApplicationGoesHere with home and extensions dirs:
$JAVA ${JAVA_MEM} \
  -DAPPLICATION_HOME=${APPLICATION_HOME} \
  -DEXTENSIONS_DIR=${EXTENSIONS_DIR} \
  -jar ${INSTALL_DIR}/${APPLICATION}.jar $*
