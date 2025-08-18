#!/bin/bash -eu

mkdir -p out
odin build source/ -out:out/output -debug
cp resources/DejaVuSansMono.ttf out/font.ttf
echo Build complete!
