#!/bin/bash -eu

OUT_DIR="build/desktop"
mkdir -p $OUT_DIR
mkdir -p $OUT_DIR/assets
odin build source/main_desktop -out:$OUT_DIR/keypra.bin -debug
cp -R ./assets/font.ttf ./$OUT_DIR/assets/font.ttf
echo "Desktop build created in ${OUT_DIR}"

