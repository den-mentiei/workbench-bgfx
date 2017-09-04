#!/usr/bin/env bash

set -e

VERSION_ID=$(./make-id.sh)

# TODO: other platforms handling.

OUT="dist"
INFO_OUT="$OUT/README.md"
TOOLS_OUT="$OUT/bin"
INCLUDE_OUT="$OUT/include"
LIB_OUT="$OUT/lib/linux64"
TARGET_DIR="bgfx/.build/linux64_gcc/bin"

# To publish releases to.
OWNER="den-mentiei"
REPO="workbench-bgfx"
TOKEN=$(cat .secret-token)

pushd() {
    command pushd "$@" &> /dev/null
}

popd() {
    command popd "$@" &> /dev/null
}

# GitHub API.

GH_API="https://api.github.com"
GH_REPO="$GH_API/repos/$OWNER/$REPO"
AUTH="Authorization: token $TOKEN"
WGET_ARGS="--content-disposition --auth-no-challenge --no-cookie"
CURL_ARGS="-LJO#"

check_auth() {
    curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "error: Invalid repo, token or network issue!";  exit 1; }
}

get_release_id() {
    if [ -z "$1" ]
    then
	echo "error: Pass a tag."
	exit 1
    fi

    local GH_TAGS="$GH_REPO/releases/tags/$1"
    local RESPONSE=$(curl -sH "$AUTH" $GH_TAGS)
    local PARSED=$(echo "$RESPONSE" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
    local RELEASE_ID=${PARSED:3}
    
    if [ -z "$RELEASE_ID" ]
    then
	echo ""
    else
	echo $RELEASE_ID
    fi
}

create_release() {
    if [ -z "$1" ] || [ -z "$2" ];
    then
	echo "error: Pass a release name & description."
	exit 1
    fi

    echo "Creating release..."
    check_auth

    local DESCRIPTION=$(echo "$2" | sed ':a;N;$!ba;s/\n/\\n/g')

    local DATA=$(printf '{"tag_name": "%s", "name": "%s", "body": "%s"}' $1 $1 "$DESCRIPTION")
    local GH_CREATE="$GH_REPO/releases"
    curl -o /dev/null --data "$DATA" -X POST -sH "$AUTH" $GH_CREATE || { echo "error: Can not create release :("; exit 1; }
}

upload_asset() {
    if [ -z "$1" ] || [ -z "$2" ];
    then
	echo "error: Pass a tag & asset file to upload."
	exit 1
    fi

    local GH_TAGS="$GH_REPO/releases/tags/$1"
    local RESPONSE=$(curl -sH "$AUTH" $GH_TAGS)
    local PARSED=$(echo "$RESPONSE" | grep -m 1 "id.:" | grep -w id | tr : = | tr -cd '[[:alnum:]]=')
    local RELEASE_ID=${PARSED:3}
    
    if [ -z "$RELEASE_ID" ]
    then
	echo "error: Failed to get a release id for tag: $1"
	exit 1
    fi

    echo "Uploading asset... $2"
    local GH_ASSET="https://uploads.github.com/repos/$OWNER/$REPO/releases/$RELEASE_ID/assets?name=$(basename $2)"

    curl -o /dev/null --data-binary @"$2" -sH "$AUTH" -H "Content-Type: application/octet-stream" $GH_ASSET
}

# Tarballing build output.

package() {
    if [ -z "$1" ] || [ -z "$2" ];
    then
	echo "error: Specify a package name & output."
	exit 1
    fi

    pushd $1
    tar czf ../$2 .
    popd

    rm -rf $1
}

echo "Building library & tools..."

pushd bgfx

# make clean

# ../bx/tools/bin/linux/genie --gcc=linux-gcc gmake
# make -j$(nproc) -R -C .build/projects/gmake-linux config=debug64

# ../bx/tools/bin/linux/genie --with-tools --gcc=linux-gcc gmake
# make -j$(nproc) -R -C .build/projects/gmake-linux config=release64

popd

rm -rf   $OUT
mkdir -p $OUT

rm -rf   $INCLUDE_OUT
mkdir -p $INCLUDE_OUT

rm -rf   $LIB_OUT
mkdir -p $LIB_OUT

rm -rf   $TOOLS_OUT
mkdir -p $TOOLS_OUT

echo "Making built tools distribution..."
cp $TARGET_DIR/shadercRelease   $TOOLS_OUT
cp $TARGET_DIR/texturecRelease  $TOOLS_OUT
cp $TARGET_DIR/texturevRelease  $TOOLS_OUT
cp $TARGET_DIR/geometrycRelease $TOOLS_OUT

echo "Making built lib distribution..."
cp bgfx/include/bgfx/defines.h      $INCLUDE_OUT/defines.h
cp bgfx/include/bgfx/c99/bgfx.h     $INCLUDE_OUT/bgfx.h
cp bgfx/include/bgfx/c99/platform.h $INCLUDE_OUT/platform.h
cp bx/include/bx/platform.h         $INCLUDE_OUT/bx_platform.h

sed -i 's/^\#include\s\"\.\.\/defines\.h\"/\#include "defines.h"/g'  $INCLUDE_OUT/bgfx.h
sed -i 's/^\#include\s<bx\/platform\.h>/\#include "bx_platform.h"/g' $INCLUDE_OUT/bgfx.h
sed -i 's/^\#include\s<bx\/platform\.h>/\#include "bx_platform.h"/g' $INCLUDE_OUT/platform.h

cp $TARGET_DIR/libbxDebug.a     $LIB_OUT
cp $TARGET_DIR/libbimgDebug.a   $LIB_OUT
cp $TARGET_DIR/libbgfxDebug.a   $LIB_OUT
cp $TARGET_DIR/libbxRelease.a   $LIB_OUT
cp $TARGET_DIR/libbimgRelease.a $LIB_OUT
cp $TARGET_DIR/libbgfxRelease.a $LIB_OUT

cp template.md $INFO_OUT
git submodule >> $INFO_OUT

# TODO: Move out to a separate script.

# TODO: Package things accrodingly.
# package $TOOLS_OUT $TOOLS_ARCHIVE
# package $LIB_OUT $LIB_ARCHIVE

# if [ -z $(get_release_id $VERSION_ID) ]
# then
#     echo "Making a new release..."
#     create_release $VERSION_ID "$(git submodule)"
# else
#     echo "Adding assets to the existing release..."
# fi

# upload_asset $VERSION_ID $TOOLS_ARCHIVE
# upload_asset $VERSION_ID $LIB_ARCHIVE

# rm -f $TOOLS_ARCHIVE
# rm -f $LIB_ARCHIVE

# rm -rf $OUT
