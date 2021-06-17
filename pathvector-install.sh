#!/usr/bin/bash
# fail in a sane manner
set -eo pipefail

if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

echo "Changing to home directory"
cd $HOME/
echo "Cloning pathvector GitHub repository"
git clone https://github.com/natesales/pathvector.git
echo "Changing into the pathvector source directory"
cd $HOME/pathvector/
echo "Generating code"
go generate
echo "Building pathvector"
go build
echo "Copying pathvector executable for systenm-wide use"
${SUDO} cp $HOME/pathvector/pathvector /usr/local/sbin
echo "Deleting temp build directory"
cd $HOME/
rm -rf $HOME/pathvector
echo "pathvector installation completed successfully!"
exit