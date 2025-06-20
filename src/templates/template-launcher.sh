#!/bin/bash

# Shorthand wrapper script for invoking ApplicationGoesHere.

APPLICATION=ApplicationGoesHere

# We need to find the directory where ApplicationGoesHere is installed,
# and the name of the script that was invoked.
# (We're assuming here that this wrapper script will always be named
# after the application that it launches).
# Note readlink -f is used to disambiguate things in case we were
# invoked from a symlink  in /usr/bin or something.
APPLICATION_HOME=`readlink -f $0`
APPLICATION_HOME=`dirname $APPLICATION_HOME`
APPLICATION_HOME=`dirname $APPLICATION_HOME`
# (two dirnames in a row - first gets the bin directory, second gets bin's parent,
# which by convention should be the actual application home directory).

if [ ! -f ${APPLICATION_HOME}/${APPLICATION}.jar ]; then
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

# TODO we could put Xmx options here if the application requires more memory...

# TODO we need to set the extensions directory here also, because the application
#      shouldn't assume it will always be under APPLICATION_HOME

# TODO APPLICATION_HOME is actually wrong here. This is holdover code froom
#      old sc-util. We used to distinguish between the directory where the application
#      was installed (/opt/ApplicationGoesHere) and the user directory where
#      mutable settings could be stored (typically ~/.ApplicationGoesHere).
#      Since the migration from sc-util, applications basically don't care about
#      APPLICATION_HOME anymore and only want the user home.

# Invoke ApplicationGoesHere with our home property set:
$JAVA -D${APPLICATION}_HOME=${APPLICATION_HOME} -jar ${APPLICATION_HOME}/${APPLICATION}.jar $*
