#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

if [ ! -d "$SOURCE_DIR/.git" ]; then
    echo "Source tree is missing. Run scripts/prepare-source.sh first." >&2
    exit 1
fi

for tool in make go tar gzip sha256sum awk find sort; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "$tool is required" >&2
        exit 1
    }
done

SOURCE_DATE_EPOCH=$(cat "$WORK_DIR/source-date-epoch")
export SOURCE_DATE_EPOCH

rm -rf "$SOURCE_DIR/dist-entware" "$WORK_DIR/package"
mkdir -p "$WORK_DIR/package/root/opt/bin"
mkdir -p "$WORK_DIR/package/root/opt/etc/init.d"
mkdir -p "$WORK_DIR/package/root/opt/etc/AdGuardHome"
mkdir -p "$WORK_DIR/package/control"
mkdir -p "$REPO_DIR"

echo "Building AdGuard Home $ADGUARDHOME_VERSION for linux/arm64"
make -C "$SOURCE_DIR" build-release \
    FRONTEND_PREBUILT=1 \
    SIGN=0 \
    CHANNEL=release \
    VERSION="$ADGUARDHOME_VERSION" \
    ARCH=arm64 \
    OS=linux \
    DIST_DIR=dist-entware

release_archive="$SOURCE_DIR/dist-entware/AdGuardHome_linux_arm64.tar.gz"
if [ ! -f "$release_archive" ]; then
    echo "Expected release archive was not created: $release_archive" >&2
    exit 1
fi

mkdir -p "$WORK_DIR/package/release"
tar -xzf "$release_archive" -C "$WORK_DIR/package/release"

binary="$WORK_DIR/package/release/AdGuardHome/AdGuardHome"
if [ ! -x "$binary" ]; then
    echo "Built binary was not found: $binary" >&2
    exit 1
fi

install -m 0755 "$binary" "$WORK_DIR/package/root/opt/bin/AdGuardHome"
install -m 0755 \
    "$ROOT_DIR/package/adguardhome/files/S99adguardhome" \
    "$WORK_DIR/package/root/opt/etc/init.d/S99adguardhome"
install -m 0644 \
    "$ROOT_DIR/package/adguardhome/files/adguardhome.conf" \
    "$WORK_DIR/package/root/opt/etc/AdGuardHome/adguardhome.conf"

package_version="${ADGUARDHOME_VERSION}-${PACKAGE_RELEASE}"
installed_size=$(du -ks "$WORK_DIR/package/root" | awk '{print $1}')
source_commit=$(cat "$WORK_DIR/source-commit")

cat > "$WORK_DIR/package/control/control" <<EOF_CONTROL
Package: $PACKAGE_NAME
Version: $package_version
Depends: ca-bundle
Provides: adguardhome
Source: https://github.com/AdguardTeam/AdGuardHome/commit/$source_commit
Section: net
Architecture: $PACKAGE_ARCH
Maintainer: Yury Makarov
Priority: optional
Installed-Size: $installed_size
Description: Network-wide ads and trackers blocking DNS server.
EOF_CONTROL

cat > "$WORK_DIR/package/control/conffiles" <<'EOF_CONFFILES'
/opt/etc/AdGuardHome/adguardhome.conf
EOF_CONFFILES

# Create deterministic archives.  Numeric ownership is important because the
# package is assembled on a GitHub-hosted runner but installed as root.
tar_common="--sort=name --mtime=@$SOURCE_DATE_EPOCH --owner=0 --group=0 --numeric-owner"

# shellcheck disable=SC2086
tar $tar_common -czf "$WORK_DIR/package/control.tar.gz" \
    -C "$WORK_DIR/package/control" .
# shellcheck disable=SC2086
tar $tar_common -czf "$WORK_DIR/package/data.tar.gz" \
    -C "$WORK_DIR/package/root" .

printf '2.0\n' > "$WORK_DIR/package/debian-binary"
touch -d "@$SOURCE_DATE_EPOCH" \
    "$WORK_DIR/package/debian-binary" \
    "$WORK_DIR/package/control.tar.gz" \
    "$WORK_DIR/package/data.tar.gz"

package_file="${PACKAGE_NAME}_${package_version}_${PACKAGE_ARCH}.ipk"
package_path="$REPO_DIR/$package_file"
rm -f "$package_path"

(
    cd "$WORK_DIR/package"
    tar \
        --format=gnu \
        --numeric-owner \
        --sort=name \
        --mtime="@$SOURCE_DATE_EPOCH" \
        -cf - \
        ./debian-binary \
        ./data.tar.gz \
        ./control.tar.gz |
        gzip -9n > "$package_path"
)

sha256sum "$package_path" > "$package_path.sha256"
echo "Created $package_path"
