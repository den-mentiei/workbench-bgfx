#!/usr/bin/env bash

OUT="dist"
INCLUDE_OUT="$OUT/include/bgfx"

cp bgfx/include/bgfx/c99/bgfx.h $INCLUDE_OUT/bgfx.h

# sed -i '.bak' 's/^\#include \"\.\.\/defines\.h\"/\#include "defines.h"/g'  $INCLUDE_OUT/bgfx.h

sed -i '.bak' 's/^\#include \"\.\.\/defines\.h\"/\#include "defines.h"/g'  $INCLUDE_OUT/bgfx.h
sed -i '.bak' 's/^\#include <bx\/platform\.h>/\#include "bx_platform.h"/g' $INCLUDE_OUT/bgfx.h
rm -rf $INCLUDE_OUT/*.bak
