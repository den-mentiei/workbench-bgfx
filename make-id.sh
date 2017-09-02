#!/usr/bin/env bash

pushd() {
    command pushd "$@" &> /dev/null
}

popd() {
    command popd "$@" &> /dev/null
}

head8() {
    git rev-parse HEAD | cut -c 1-8
}

id() {
    pushd bimg
    local BIMG_HEAD=$(head8)
    popd

    pushd bx
    local BX_HEAD=$(head8)
    popd

    pushd bgfx
    local BGFX_HEAD=$(head8)
    popd

    echo $BIMG_HEAD$BX_HEAD$BGFX_HEAD
}

id
