#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

package_path=$(find "$REPO_DIR" -maxdepth 1 -type f -name '*.ipk' | head -n 1)
if [ -z "$package_path" ]; then
    echo "Package not found" >&2
    exit 1
fi

echo "Testing package: $package_path"

gzip -t "$package_path"
tar -tzf "$package_path" > /dev/null

for expected in debian-binary control.tar.gz data.tar.gz; do
    tar -tzf "$package_path" | grep -qx "./$expected" || {
        echo "Missing $expected in package" >&2
        exit 1
    }
done

control_text=$(
    tar -xzOf "$package_path" ./control.tar.gz |
        tar -xzO ./control
)
printf '%s\n' "$control_text" | grep -qx "Package: $PACKAGE_NAME"
printf '%s\n' "$control_text" | grep -qx "Version: ${ADGUARDHOME_VERSION}-${PACKAGE_RELEASE}"
printf '%s\n' "$control_text" | grep -qx "Architecture: $PACKAGE_ARCH"

package_tmp=$(mktemp -d)
trap 'rm -rf "$package_tmp"' EXIT HUP INT TERM
tar -xzOf "$package_path" ./data.tar.gz | tar -xzf - -C "$package_tmp"

[ -x "$package_tmp/opt/bin/AdGuardHome" ]
[ -x "$package_tmp/opt/etc/init.d/S99adguardhome" ]
[ -f "$package_tmp/opt/etc/AdGuardHome/adguardhome.conf" ]

machine=$(readelf -h "$package_tmp/opt/bin/AdGuardHome" | awk -F: '$1 ~ /Machine/ {gsub(/^[ \t]+/, "", $2); print $2}')
case "$machine" in
    AArch64*) ;;
    *)
        echo "Unexpected ELF machine: $machine" >&2
        exit 1
        ;;
esac

filename=$(awk -F ': ' '$1 == "Filename" {print $2; exit}' "$REPO_DIR/Packages")
expected_sha=$(awk -F ': ' '$1 == "SHA256sum" {print $2; exit}' "$REPO_DIR/Packages")
actual_sha=$(sha256sum "$REPO_DIR/$filename" | awk '{print $1}')
[ "$expected_sha" = "$actual_sha" ]

gzip -t "$REPO_DIR/Packages.gz"

echo "Repository validation passed"
