#!/bin/bash

set -e

BUNDLE_VERSION=0.2.0
UNAME=$(uname)
ARCH=$(uname -m)

if [ "$UNAME" == "Linux" ] ; then
    if [ "$ARCH" != "i686" -a "$ARCH" != "x86_64" ] ; then
        echo "Unsupported architecture: $ARCH"
        echo "Meteor only supports i686 and x86_64 for now."
        exit 1
    fi
    MONGO_NAME="mongodb-linux-${ARCH}-2.2.0"
    MONGO_URL="http://fastdl.mongodb.org/linux/${MONGO_NAME}.tgz"
elif [ "$UNAME" == "Darwin" ] ; then
    SYSCTL_64BIT=$(sysctl -n hw.cpu64bit_capable 2>/dev/null || echo 0)
    if [ "$ARCH" == "i386" -a "1" != "$SYSCTL_64BIT" ] ; then
        # some older macos returns i386 but can run 64 bit binaries.
        # Probably should distribute binaries built on these machines,
        # but it should be OK for users to run.
        ARCH="x86_64"
    fi

    if [ "$ARCH" != "x86_64" ] ; then
        echo "Unsupported architecture: $ARCH"
        echo "Meteor only supports x86_64 for now."
        exit 1
    fi

    MONGO_NAME="mongodb-osx-${ARCH}-2.2.0"
    MONGO_URL="http://fastdl.mongodb.org/osx/${MONGO_NAME}.tgz"
else
    echo "This OS not yet supported"
    exit 1
fi


# save off meteor checkout dir as final target
cd `dirname $0`/..
TARGET_DIR=`pwd`

DIR=`mktemp -d -t generate-dev-bundle-XXXXXXXX`
trap 'rm -rf "$DIR" >/dev/null 2>&1' 0

echo BUILDING IN "$DIR"

cd "$DIR"
chmod 755 .
umask 022
mkdir build
cd build

git clone git://github.com/joyent/node.git
cd node
git checkout v0.8.8

./configure --prefix="$DIR"
make -j4
make install

# export path so we use our new node for later builds
export PATH="$DIR/bin:$PATH"

which node

which npm

cd "$DIR/lib/node_modules"
npm install connect@1.9.2 # not 2.x yet. sockjs doesn't work w/ new connect
npm install gzippo@0.1.7
npm install optimist@0.3.4
npm install coffee-script@1.3.3
npm install less@1.3.0
npm install sass@0.5.0
npm install stylus@0.29.0
npm install nib@0.8.2
npm install mime@1.2.7
npm install semver@1.0.14
npm install handlebars@1.0.6-2
npm install mongodb@1.1.5
npm install uglify-js@1.3.3
npm install clean-css@0.6.0
npm install progress@0.0.5
npm install fibers@0.6.8
npm install useragent@1.1.0
npm install request@2.11.0
npm install http-proxy@0.8.2
npm install simplesmtp@0.1.20
npm install mailcomposer@0.1.17
npm install stream-buffers@0.2.3
npm install keypress@0.1.0

# Sockjs has a broken optional dependancy, and npm optional dependancies
# don't seem to quite work. Fake it out with a checkout.
git clone http://github.com/akdubya/rbytes.git
npm install sockjs@0.3.1
rm -rf rbytes


cd "$DIR"
curl "$MONGO_URL" | tar -xz
mv "$MONGO_NAME" mongodb

# don't ship a number of mongo binaries. they are big and unused. these
# could be deleted from git dev_bundle but not sure which we'll end up
# needing.
cd mongodb/bin
rm bsondump mongodump mongoexport mongofiles mongoimport mongorestore mongos mongosniff mongostat mongotop
cd ../..



echo BUNDLING

cd "$DIR"
echo "${BUNDLE_VERSION}" > .bundle_version.txt
rm -rf build

tar czf "${TARGET_DIR}/dev_bundle_${UNAME}_${ARCH}_${BUNDLE_VERSION}.tar.gz" .

echo DONE
