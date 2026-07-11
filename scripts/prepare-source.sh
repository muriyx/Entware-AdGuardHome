#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v sha256sum >/dev/null 2>&1 || { echo "sha256sum is required" >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar is required" >&2; exit 1; }

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/downloads"

echo "Cloning AdGuard Home $ADGUARDHOME_VERSION"
git clone \
    --depth 1 \
    --branch "$ADGUARDHOME_VERSION" \
    --single-branch \
    https://github.com/AdguardTeam/AdGuardHome.git \
    "$SOURCE_DIR"

actual_tag=$(git -C "$SOURCE_DIR" describe --tags --exact-match)
if [ "$actual_tag" != "$ADGUARDHOME_VERSION" ]; then
    echo "Checked-out tag mismatch: expected $ADGUARDHOME_VERSION, got $actual_tag" >&2
    exit 1
fi

release_base="https://github.com/AdguardTeam/AdGuardHome/releases/download/$ADGUARDHOME_VERSION"
frontend="$WORK_DIR/downloads/AdGuardHome_frontend.tar.gz"
checksums="$WORK_DIR/downloads/checksums.txt"

curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$frontend" \
    "$release_base/AdGuardHome_frontend.tar.gz"

curl --fail --location --proto '=https' --tlsv1.2 \
    --output "$checksums" \
    "$release_base/checksums.txt"

expected_sha=$(awk '
    $2 == "AdGuardHome_frontend.tar.gz" || $2 == "./AdGuardHome_frontend.tar.gz" {
        print $1
    }
' "$checksums")

if [ -z "$expected_sha" ]; then
    echo "Frontend checksum was not found in checksums.txt" >&2
    exit 1
fi

actual_sha=$(sha256sum "$frontend" | awk '{print $1}')
if [ "$actual_sha" != "$expected_sha" ]; then
    echo "Frontend checksum mismatch" >&2
    echo "Expected: $expected_sha" >&2
    echo "Actual:   $actual_sha" >&2
    exit 1
fi

echo "Frontend SHA-256 verified: $actual_sha"

# The official frontend archive contains one top-level AdGuardHome directory,
# exactly as expected by the Entware package recipe.
tar -xzf "$frontend" --strip-components=1 -C "$SOURCE_DIR"

# Used by the build and deterministic package archives.
git -C "$SOURCE_DIR" show -s --format=%ct HEAD > "$WORK_DIR/source-date-epoch"
git -C "$SOURCE_DIR" rev-parse HEAD > "$WORK_DIR/source-commit"
