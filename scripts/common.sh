#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERSION_FILE="$ROOT_DIR/package/adguardhome/version.env"

if [ ! -f "$VERSION_FILE" ]; then
    echo "Version file not found: $VERSION_FILE" >&2
    exit 1
fi

# This file is part of this trusted repository and contains only assignments.
# shellcheck disable=SC1090
. "$VERSION_FILE"

: "${ADGUARDHOME_VERSION:?ADGUARDHOME_VERSION is required}"
: "${PACKAGE_RELEASE:?PACKAGE_RELEASE is required}"
: "${PACKAGE_NAME:?PACKAGE_NAME is required}"
: "${PACKAGE_ARCH:?PACKAGE_ARCH is required}"

WORK_DIR="$ROOT_DIR/.work"
SOURCE_DIR="$WORK_DIR/AdGuardHome"
PUBLIC_DIR="$ROOT_DIR/public"
REPO_DIR="$PUBLIC_DIR/$PACKAGE_ARCH"

export ROOT_DIR VERSION_FILE WORK_DIR SOURCE_DIR PUBLIC_DIR REPO_DIR
export ADGUARDHOME_VERSION PACKAGE_RELEASE PACKAGE_NAME PACKAGE_ARCH
