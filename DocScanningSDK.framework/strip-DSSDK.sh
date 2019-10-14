#! /bin/sh
mkdir -p $(dirname "$2")
lipo -remove i386 "$1" -o "$2"
lipo -remove x86_64 "$2" -o "$2"
