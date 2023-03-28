#!/usr/bin/env bash

# Print the commands being run so that we can see the command that triggers
# an error.  It is also useful for following along as the install occurs.
set -o xtrace

# Make sure custom grep options don't get in the way
unset GREP_OPTIONS

# We also have to unset other variables that might impact LC_ALL
# taking effect.
unset LANG
unset LANGUAGE
LC_ALL=en_US.utf8
export LC_ALL

# Clear all OpenStack related envvars
unset $(env | grep -E '^OS_' | cut -d = -f 1)

# Make sure umask is sane
umask 022

# Not all distros have sbin in PATH for regular users.
# osc will normally be installed at /usr/local/bin/openstack so ensure
# /usr/local/bin is also in the path
PATH=$PATH:/usr/local/bin:/usr/local/sbin:/usr/sbin:/sbin

# Keep track of the DevStack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Check for uninitialized variables, a big cause of bugs
NOUNSET=${NOUNSET:-}
if [[ -n "$NOUNSET" ]]; then
  set -o nounset
fi

# Set start of devstack timestamp
DEVSTACK_START_TIME=$(date +%s)

# Clean up last environment var cache
if [[ -r $TOP_DIR/.stackenv ]]; then
  rm $TOP_DIR/.stackenv
fi

# ``stack.sh`` keeps the list of ``deb`` and ``rpm`` dependencies, config
# templates and other useful files in the ``files`` subdirectory
FILES=$TOP_DIR/files
if [ ! -d $FILES ]; then
  set +o xtrace
  echo "[ERR] missing devstack/files"
  exit 1
fi

# ``stack.sh`` keeps function libraries here
# Make sure ``$TOP_DIR/inc`` directory is present
if [ ! -d $TOP_DIR/inc ]; then
  set +o xtrace
  echo "[ERR] missing devstack/inc"
  exit 1
fi

# ``stack.sh`` keeps project libraries here
# Make sure ``$TOP_DIR/lib`` directory is present
if [ ! -d $TOP_DIR/lib ]; then
  set +o xtrace
  echo "[ERR] missing devstack/lib"
  exit 1
fi

# Check if run in POSIX shell
if [[ "${POSIXLY_CORRECT}" == "y" ]]; then
  set +o xtrace
  echo "[ERR] You are running POSIX compatibility mode, DevStack requires bash 4.2 or newer."
  exit 1
fi

# OpenStack is designed to be run as a non-root user; Horizon will fail to run
# as **root** since Apache will not serve content from **root** user).
# ``stack.sh`` must not be run as **root**.  It aborts and suggests one course of
# action to create a suitable user account.
if [[ $EUID -eq 0 ]]; then # check this user is root, non-root user's EUID is 0
  set +o xtrace
  echo "[ERR] DevStack should be run as a user with sudo permissions, "
  echo "      not root."
  echo "      A \"stack\" user configured correctly can be created with:"
  echo "      $TOP_DIR/tools/create-stack-user.sh"
  exit 1
fi

# OpenStack is designed to run at a system level, with system level
# installation of python packages. It does not support running under a
# virtual env, and will fail in really odd ways if you do this. Make
# this explicit as it has come up on the mailing list.
if [[ -n "$VIRTUAL_ENV" ]]; then # check VIRUTAL_ENV is not empty
  set +o xtrace
  echo "[ERR] You appear to be running under a python virtualenv."
  echo "      DevStack does not support this, as we may break the"
  echo "      virtualenv you are currently in by modifying "
  echo "      external system-level components the virtualenv relies on."
  echo "      We recommend you use a separate virtual-machine if "
  echo "      you are worried about DevStack taking over your system."
  exit 1
fi

# Provide a safety switch for devstack. If you do a lot of devstack,
# on a lot of different environments, you sometimes run it on the
# wrong box. This makes there be a way to prevent that.
if [[ -e $HOME/.no-devstack ]]; then # check this file existed
  set +o xtrace
  echo "[ERR] You've marked this host as a no-devstack host, to save yourself from"
  echo "      running devstack accidentally. If this is in error, please remove the"
  echo "      ~/.no-devstack file"
  exit 1
fi

# Initialize variables:
LAST_SPINNER_PID=""

# Import common functions
source $TOP_DIR/functions

# Import 'public' stack.sh functions
source $TOP_DIR/lib/stack

# Determine what system we are running on.  This provides ``os_VENDOR``,
# ``os_RELEASE``, ``os_PACKAGE``, ``os_CODENAME``
# and ``DISTRO``
GetDistro

# Phase: local
rm -f $TOP_DIR/.localrc.auto
extract_localrc_section $TOP_DIR/local.conf $TOP_DIR/localrc $TOP_DIR/.localrc.auto

# DevStack distributes ``stackrc`` which contains locations for the OpenStack
# repositories, branches to configure, and other configuration defaults.
# ``stackrc`` sources the ``localrc`` section of ``local.conf`` to allow you to
# safely override those settings.
if [[ ! -r $TOP_DIR/stackrc ]]; then
  die $LINENO "missing $TOP_DIR/stackrc - did you grab more than just stack.sh?"
fi
source $TOP_DIR/stackrc # read the stackrc file

# write /etc/devstack-version
write_devstack_version

# Warn users who aren't on an explicitly supported distro, but allow them to
# override check and attempt installation with ``FORCE=yes ./stack``
SUPPORTED_DISTROS="bullseye|focal|jammy|f36|opensuse-15.2|opensuse-tumbleweed|rhel8|rhel9|openEuler-22.03"

if [[ ! ${DISTRO} =~ $SUPPORTED_DISTROS ]]; then
  echo "WARNING: this script has not been tested on $DISTRO"
  if [[ "$FORCE" != "yes" ]]; then
    die $LINENO "If you wish to run this script anyway run with FORCE=yes"
  fi
fi

# Make sure the proxy config is visible to sub-processes
export_proxy_variables

# Remove services which were negated in ``ENABLED_SERVICES``
# using the "-" prefix (e.g., "-rabbit") instead of
# calling disable_service().
disable_negated_services

# We're not as **root** so make sure ``sudo`` is available
is_package_installed sudo || is_package_installed sudo-ldap || install_package sudo

# UEC images ``/etc/sudoers`` does not have a ``#includedir``, add one
sudo grep -q "^#includedir.*/etc/sudoers.d" /etc/sudoers ||
  echo "#includedir /etc/sudoers.d" | sudo tee -a /etc/sudoers

# Conditionally setup detailed logging for sudo
if [[ -n "$LOG_SUDO" ]]; then
  TEMPFILE=$(mktemp)
  echo "Defaults log_output" >$TEMPFILE
  chmod 0440 $TEMPFILE
  sudo chown root:root $TEMPFILE
  sudo mv $TEMPFILE /etc/sudoers.d/00_logging
fi

# Set up DevStack sudoers
TEMPFILE=$(mktemp)
echo "$STACK_USER ALL=(root) NOPASSWD:ALL" >$TEMPFILE

# Some binaries might be under ``/sbin`` or ``/usr/sbin``, so make sure sudo will
# see them by forcing ``PATH``
echo "Defaults:$STACK_USER secure_path=/sbin:/usr/sbin:/usr/bin:/bin:/usr/local/sbin:/usr/local/bin" >>$TEMPFILE
echo "Defaults:$STACK_USER !requiretty" >>$TEMPFILE
chmod 0440 $TEMPFILE
sudo chown root:root $TEMPFILE
sudo mv $TEMPFILE /etc/sudoers.d/50_stack_sh

# For Debian/Ubuntu make apt attempt to retry network ops on it's own
if is_ubuntu; then
  echo 'APT::Acquire::Retries "20";' | sudo tee /etc/apt/apt.conf.d/80retry >/dev/null
fi

# Some distros need to add repos beyond the defaults provided by the vendor
# to pick up required packages.
function _install_epel {
  # epel-release is in extras repo which is enabled by default
  install_package epel-release

  # RDO repos are not tested with epel and may have incompatibilities so
  # let's limit the packages fetched from epel to the ones not in RDO repos.
  sudo dnf config-manager --save --setopt=includepkgs=debootstrap,dpkg epel
}

function _install_rdo {
  if [[ $DISTRO == "rhel8" ]]; then
    if [[ "$TARGET_BRANCH" == "master" ]]; then
      # rdo-release.el8.rpm points to latest RDO release, use that for master
      sudo dnf -y install https://rdoproject.org/repos/rdo-release.el8.rpm
    else
      # For stable branches use corresponding release rpm
      rdo_release=$(echo $TARGET_BRANCH | sed "s|stable/||g")
      sudo dnf -y install https://rdoproject.org/repos/openstack-${rdo_release}/rdo-release-${rdo_release}.el8.rpm
    fi
  elif [[ $DISTRO == "rhel9" ]]; then
    sudo curl -L -o /etc/yum.repos.d/delorean-deps.repo http://trunk.rdoproject.org/centos9-master/delorean-deps.repo
  fi
  sudo dnf -y update
}

# Destination path for installation ``DEST``
DEST=${DEST:-/opt/stack}

# Create the destination directory and ensure it is writable by the user
# and read/executable by everybody for daemons (e.g. apache run for horizon)
# If directory exists do not modify the permissions.
if [[ ! -d $DEST ]]; then
  sudo mkdir -p $DEST
  safe_chown -R $STACK_USER $DEST
  safe_chmod 0755 $DEST
fi

# Destination path for devstack logs
if [[ -n ${LOGDIR:-} ]]; then
  mkdir -p $LOGDIR
fi

# Destination path for service data
DATA_DIR=${DATA_DIR:-${DEST}/data}
if [[ ! -d $DATA_DIR ]]; then
  sudo mkdir -p $DATA_DIR
  safe_chown -R $STACK_USER $DATA_DIR
  safe_chmod 0755 $DATA_DIR
fi

# Create and/or clean the async state directory
async_init

# Configure proper hostname
# Certain services such as rabbitmq require that the local hostname resolves
# correctly.  Make sure it exists in /etc/hosts so that is always true.
LOCAL_HOSTNAME=$(hostname -s)
if ! fgrep -qwe "$LOCAL_HOSTNAME" /etc/hosts; then
  sudo sed -i "s/\(^127.0.0.1.*\)/\1 $LOCAL_HOSTNAME/" /etc/hosts
fi

# If you have all the repos installed above already setup (e.g. a CI
# situation where they are on your image) you may choose to skip this
# to speed things up
SKIP_EPEL_INSTALL=$(trueorfalse False SKIP_EPEL_INSTALL)

if [[ $DISTRO == "rhel8" ]]; then
  # If we have /etc/ci/mirror_info.sh assume we're on a OpenStack CI
  # node, where EPEL is installed (but disabled) and already
  # pointing at our internal mirror
  if [[ -f /etc/ci/mirror_info.sh ]]; then
    SKIP_EPEL_INSTALL=True
    sudo dnf config-manager --set-enabled epel
  fi

  # PowerTools repo provides libyaml-devel required by devstack itself and
  # EPEL packages assume that the PowerTools repository is enable.
  sudo dnf config-manager --set-enabled PowerTools

  # CentOS 8.3 changed the repository name to lower case.
  sudo dnf config-manager --set-enabled powertools

  if [[ ${SKIP_EPEL_INSTALL} != True ]]; then
    _install_epel
  fi
  # Along with EPEL, CentOS (and a-likes) require some packages only
  # available in RDO repositories (e.g. OVS, or later versions of
  # kvm) to run.
  _install_rdo

  # NOTE(cgoncalves): workaround RHBZ#1154272
  # dnf fails for non-privileged users when expired_repos.json doesn't exist.
  # RHBZ: https://bugzilla.redhat.com/show_bug.cgi?id=1154272
  # Patch: https://github.com/rpm-software-management/dnf/pull/1448
  echo "[]" | sudo tee /var/cache/dnf/expired_repos.json
elif [[ $DISTRO == "rhel9" ]]; then
  sudo dnf config-manager --set-enabled crb
  # rabbitmq and other packages are provided by RDO repositories.
  _install_rdo

  # Some distributions (Rocky Linux 9) provide curl-minimal instead of curl,
  # it triggers a conflict when devstack wants to install "curl".
  # Swap curl-minimal with curl.
  if is_package_installed curl-minimal; then
    sudo dnf swap -y curl-minimal curl
  fi
elif [[ $DISTRO == "openEuler-22.03" ]]; then
  # There are some problem in openEuler. We should fix it first. Some required
  # package/action runs before fixup script. So we can't fix there.
  #
  # 1. the hostname package is not installed by default
  # 2. Some necessary packages are in openstack repo, for example liberasurecode-devel
  # 3. python3-pip can be uninstalled by `get_pip.py` automaticly.
  install_package hostname openstack-release-wallaby
  uninstall_package python3-pip
fi

# Ensure python is installed
# --------------------------
install_python

echo "FINISH"
