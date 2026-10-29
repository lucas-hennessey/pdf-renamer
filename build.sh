#!/bin/zsh
# Builds "Rename PDFs.app" (drag it to the Dock). Needs Xcode Command Line Tools.
set -e
cd "$(dirname "$0")"
APP="$HOME/Applications/Rename PDFs.app"
swiftc -O rename_pdfs.swift -o rename_pdfs
mkdir -p "$HOME/Applications"
rm -rf "$APP"
osacompile -o "$APP" rename_pdfs.applescript
cp rename_pdfs "$APP/Contents/Resources/rename_pdfs"
codesign --force --deep -s - "$APP"
echo "Built: $APP"
