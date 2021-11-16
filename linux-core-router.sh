#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

main() {
        if [ "$(whoami)" != "root" ]; then
            SUDO=sudo
        fi

        GO_PACKAGE="go1.17.3.linux-amd64.tar.gz"

        # Step 1: detect the current linux distro, version, and packaging system.
        #
        # We rely on a combination of 'uname' and /etc/os-release to find
        # an OS name and version, and from there work out what
        # installation method we should be using.
        #
        # The end result of this step is that the following three
        # variables are populated, if detection was successful.
        OS=""
        VERSION=""
        PACKAGETYPE=""

        if [ -f /etc/os-release ]; then
                # /etc/os-release populates a number of shell variables. We care about the following:
                #  - ID: the short name of the OS (e.g. "debian", "freebsd")
                #  - VERSION_ID: the numeric release version for the OS, if any (e.g. "18.04")
                #  - VERSION_CODENAME: the codename of the OS release, if any (e.g. "buster")
                source /etc/os-release
                case "$ID" in
                        ubuntu)
                                OS="$ID"
                                VERSION="$VERSION_CODENAME"
                                PACKAGETYPE="apt"
                        debian)
                                OS="$ID"
                                VERSION="$VERSION_CODENAME"
                                PACKAGETYPE="apt"
                        centos)
                                OS="$ID"
                                VERSION="$VERSION_ID"
                                PACKAGETYPE="dnf"
                                if [ "$VERSION" = "7" ]; then
                                        PACKAGETYPE="yum"
                                fi
                                ;;
                        rhel)
                                OS="$ID"
                                VERSION="$(echo "$VERSION_ID" | cut -f1 -d.)"
                                PACKAGETYPE="dnf"
                                ;;
                esac
        fi

        # If we failed to detect something through os-release, consult
        # uname and try to infer things from that.
        if [ -z "$OS" ]; then
                if type uname >/dev/null 2>&1; then
                        case "$(uname)" in
                                Linux)
                                        OS="other-linux"
                                        VERSION=""
                                        PACKAGETYPE=""
                                        ;;
                        esac
                fi
        fi

        # Step 2: having detected an OS we support, is it one of the
        # versions we support?
        OS_UNSUPPORTED=
        case "$OS" in
                ubuntu)
                        if [ "$VERSION" != "bionic" ] && \
                           [ "$VERSION" != "focal" ]
                        then
                                OS_UNSUPPORTED=1
                        fi
                ;;
                debian)
                        if [ "$VERSION" != "buster" ] && \
                           [ "$VERSION" != "bullseye" ]
                        then
                                OS_UNSUPPORTED=1
                        fi
                ;;
                raspbian)
                        if [ "$VERSION" != "buster" ] && \
                           [ "$VERSION" != "bullseye" ]
                        then
                                OS_UNSUPPORTED=1
                        fi
                ;;
                centos)
                        if [ "$VERSION" != "7" ] && \
                           [ "$VERSION" != "8" ]
                        then
                                OS_UNSUPPORTED=1
                        fi
                ;;
                rhel)
                        if [ "$VERSION" != "8" ]
                        then
                                OS_UNSUPPORTED=1
                        fi
                ;;
                other-linux)
                        OS_UNSUPPORTED=1
                        ;;
                *)
                        OS_UNSUPPORTED=1
                        ;;
        esac
        if [ "$OS_UNSUPPORTED" = "1" ]; then
                echo "$OS $VERSION isn't supported by this script yet."
                exit
        fi

        if [ "$VERSION" = "buster" ]; then
            echo "Starting Go install"
            echo "Changing directory to /tmp"
            cd /tmp
            echo "Downloading go binary"
            wget https://golang.org/dl/$GO_PACKAGE
            echo "Removing previous go installations"
            ${SUDO} rm -rf /usr/local/go
            echo "Extracting go binary"
            ${SUDO} tar -C /usr/local -xzf /tmp/$GO_PACKAGE
            echo "Adding /usr/local/go/bin to the PATH environment variable"
            ${SUDO} sh -c 'echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile'
            echo "Removing tarball"
            cd /tmp
            rm -rf /tmp/$GO_PACKAGE
            source /etc/profile
            echo "Go installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Adding BIRD2 package repository to system..."
            ${SUDO} sh -c 'echo "deb [arch=amd64] http://provo-mirror.opensuse.org/repositories/home:/CZ-NIC:/bird-latest/Debian_10/  ./" > /etc/apt/sources.list.d/bird2.list'
            ${SUDO} bash -c 'cat << EOF > /etc/apt/preferences.d/bird2
            Package: bird*
            Pin: origin provo-mirror.opensuse.org
            Pin-Priority: 600
            EOF'
            echo "Installing prerequisite packages..."
            ${SUDO} apt install -y gnupg2
            echo "Adding repo signing keys..."
            ${SUDO} apt-key adv --fetch-keys 'https://download.opensuse.org/repositories/home:/CZ-NIC:/bird-latest/Debian_10/Release.key'
            echo "Updating system package cache..."
            ${SUDO} apt update
            echo "Installing BIRD2..."
            ${SUDO} apt install -y bird2
            echo "Enabling BIRD2 systemd service..."
            ${SUDO} systemctl enable bird
            echo "Starting BIRD2 systemd service..."
            ${SUDO} systemctl start bird
            echo "BIRD2 installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Starting bgpq4 install"
            echo "Installing prerequisite packages"
            ${SUDO} apt install -y m4 libtool
            echo "Changing directory to /tmp"
            cd /tmp
            echo "Cloning bgpq4 GitHub repository"
            git clone https://github.com/bgp/bgpq4.git
            echo "Changing into the bgpq4 source directory"
            cd /tmp/bgpq4/
            echo "Preparing the build system"
            ./bootstrap
            echo "Compiling the software: Step 1/3  - Configure"
            ./configure
            echo "Compiling the software: Step 2/3 - Creating install file"
            make
            echo "Compiling the software: Step 3/3 - Installing software"
            ${SUDO} make install
            echo "Deleting temp build directory"
            cd /tmp
            rm -rf /tmp/bgpq4/
            echo "bgpq4 installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Starting Pathvector install"
            ${SUDO} bash -c "curl https://repo.pathvector.io/pgp.asc > /usr/share/keyrings/pathvector.asc"
            ${SUDO} bash -c "echo 'deb [signed-by=/usr/share/keyrings/pathvector.asc] https://repo.pathvector.io/apt/ stable main' > /etc/apt/sources.list.d/pathvector.list"
            ${SUDO} apt update
            ${SUDO} apt install -y pathvector
            source /etc/profile
            echo "Pathvector installation completed successfully!"
            exit
        fi

        if [ "$VERSION" = "bullseye" ]; then
            echo "Starting Go install"
            echo "Changing directory to /tmp"
            cd /tmp
            echo "Downloading go binary"
            wget https://golang.org/dl/$GO_PACKAGE
            echo "Removing previous go installations"
            ${SUDO} rm -rf /usr/local/go
            echo "Extracting go binary"
            ${SUDO} tar -C /usr/local -xzf /tmp/$GO_PACKAGE
            echo "Adding /usr/local/go/bin to the PATH environment variable"
            ${SUDO} sh -c 'echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile'
            echo "Removing tarball"
            cd /tmp
            rm -rf /tmp/$GO_PACKAGE
            source /etc/profile
            echo "Go installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Adding Bullseye-Backports repository..."
            ${SUDO} bash -c 'cat << EOF > /etc/apt/sources.list.d/bullseye-backports.list
            deb http://deb.debian.org/debian bullseye-backports main contrib non-free
            deb-src http://deb.debian.org/debian bullseye-backports main contrib non-free
            EOF'
            echo "Updating system package cache..."
            ${SUDO} apt update
            echo "Installing BIRD2..."
            ${SUDO} apt -t bullseye-backports install -y bird2
            echo "Enabling BIRD2 systemd service..."
            ${SUDO} systemctl enable bird
            echo "Starting BIRD2 systemd service..."
            ${SUDO} systemctl start bird
            echo "BIRD2 installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Starting bgpq4 install"
            echo "Installing prerequisite packages"
            ${SUDO} apt install -y m4 libtool
            echo "Changing directory to /tmp"
            cd /tmp
            echo "Cloning bgpq4 GitHub repository"
            git clone https://github.com/bgp/bgpq4.git
            echo "Changing into the bgpq4 source directory"
            cd /tmp/bgpq4/
            echo "Preparing the build system"
            ./bootstrap
            echo "Compiling the software: Step 1/3  - Configure"
            ./configure
            echo "Compiling the software: Step 2/3 - Creating install file"
            make
            echo "Compiling the software: Step 3/3 - Installing software"
            ${SUDO} make install
            echo "Deleting temp build directory"
            cd /tmp
            rm -rf /tmp/bgpq4/
            echo "bgpq4 installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Starting Pathvector install"
            ${SUDO} bash -c "curl https://repo.pathvector.io/pgp.asc > /usr/share/keyrings/pathvector.asc"
            ${SUDO} bash -c "echo 'deb [signed-by=/usr/share/keyrings/pathvector.asc] https://repo.pathvector.io/apt/ stable main' > /etc/apt/sources.list.d/pathvector.list"
            ${SUDO} apt update
            ${SUDO} apt install -y pathvector
            source /etc/profile
            echo "Pathvector installation completed successfully!"
            exit
        fi
    
        if [ "$VERSION" = "bionic" ] || [ "$VERSION" = "focal" ]; then
            echo "Starting Go install"
            echo "Changing directory to /tmp"
            cd /tmp
            echo "Downloading go binary"
            wget https://golang.org/dl/$GO_PACKAGE
            echo "Removing previous go installations"
            ${SUDO} rm -rf /usr/local/go
            echo "Extracting go binary"
            ${SUDO} tar -C /usr/local -xzf /tmp/$GO_PACKAGE
            echo "Adding /usr/local/go/bin to the PATH environment variable"
            ${SUDO} sh -c 'echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile'
            echo "Removing tarball"
            cd /tmp
            rm -rf /tmp/$GO_PACKAGE
            source /etc/profile
            echo "Go installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Adding BIRD2 package repository to system..."
            ${SUDO} add-apt-repository -y ppa:cz.nic-labs/bird
            ${SUDO} apt-get update
            echo "Installing BIRD2..."
            ${SUDO} apt-get install -y bird2
            echo "Enabling BIRD2 systemd service..."
            ${SUDO} systemctl enable bird
            echo "Starting BIRD2 systemd service..."
            ${SUDO} systemctl start bird
            echo "BIRD2 installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Starting bgpq4 install"
            echo "Installing prerequisite packages"
            ${SUDO} apt-get install -y m4 libtool
            echo "Changing directory to /tmp"
            cd /tmp
            echo "Cloning bgpq4 GitHub repository"
            git clone https://github.com/bgp/bgpq4.git
            echo "Changing into the bgpq4 source directory"
            cd /tmp/bgpq4/
            echo "Preparing the build system"
            ./bootstrap
            echo "Compiling the software: Step 1/3  - Configure"
            ./configure
            echo "Compiling the software: Step 2/3 - Creating install file"
            make
            echo "Compiling the software: Step 3/3 - Installing software"
            ${SUDO} make install
            echo "Deleting temp build directory"
            cd /tmp
            rm -rf /tmp/bgpq4/
            echo "bgpq4 installation completed successfully!"
            echo "Sleeping for 5 seconds before proceeding"
            sleep 5
            echo "Starting Pathvector install"
            ${SUDO} bash -c "curl https://repo.pathvector.io/pgp.asc > /usr/share/keyrings/pathvector.asc"
            ${SUDO} bash -c "echo 'deb [signed-by=/usr/share/keyrings/pathvector.asc] https://repo.pathvector.io/apt/ stable main' > /etc/apt/sources.list.d/pathvector.list"
            ${SUDO} apt-get update
            ${SUDO} apt-get install -y pathvector
            source /etc/profile
            echo "Pathvector installation completed successfully!"
            exit
        fi
}

main