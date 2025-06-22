#/bin/bash

# TODO TODO TODO
# This code is old and will not work with the new structure.
# Basically needs a rewrite.
# I'm just copying it here for use as a reference / starting point.
# TODO TODO TODO


# This script will set up an application with an
# installation script, launcher script, and uninstall
# script. This saves manual copying and faffing about
# with editing properties once the files are in place.
# Can be run again for the same app to update the
# launcher/installer/uninstaller if needed.
#
# scorbett 2022-05-05

# Make sure we have installer props set up:
# The project root directory should contain installer.props)
if [ ! -f installer.props ]; then
  echo "make-installer: no installer.props found in this directory."
  exit 1
fi
source ./installer.props



# TODO everything below here is still old and wrong
exit 1
###################################



if [ $# -ne 3 ]; then
  echo "USAGE: copy_installer.sh <destination_dir> <app_name> <app_version>"
  exit 1
fi

DEST_DIR=$1
APPLICATION=$2
VERSION=$3

# Make sure we were given a writable destination:
if [ ! -d $DEST_DIR -o ! -w $DEST_DIR ]; then
  echo "Destination directory does not exist or is not writable."
  exit 1
fi

# Create the bin directory if it's not already there:
mkdir -p ${DEST_DIR}/bin

# Copy files with variable substitution:
cat templates/template-install.sh | sed s/ApplicationGoesHere/${APPLICATION}/g | sed s/VersionGoesHere/${VERSION}/g > ${DEST_DIR}/install.sh
cat templates/templaete=launcher.sh | sed s/ApplicationGoesHere/${APPLICATION}/g | sed s/JavaMemGoesHere/${JAVA_MEM}/g > > ${DEST_DIR}/bin/${APPLICATION}
cat templates/template-uninstall.sh | sed s/ApplicationGoesHere/${APPLICATION}/g > ${DEST_DIR}/bin/uninstall.sh

echo "Updated ${APPLICATION} in ${DEST_DIR} with latest install/uninstall/launcher scripts."

