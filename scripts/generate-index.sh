#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

for tool in tar gzip sha256sum stat awk sort; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "$tool is required" >&2
        exit 1
    }
done

mkdir -p "$REPO_DIR"
packages_file="$REPO_DIR/Packages"
: > "$packages_file"

found=0
for package_path in $(find "$REPO_DIR" -maxdepth 1 -type f -name '*.ipk' | sort); do
    found=1
    package_file=$(basename "$package_path")
    package_size=$(stat -c '%s' "$package_path")
    package_sha=$(sha256sum "$package_path" | awk '{print $1}')

    control_text=$(
      tar -xzOf "$package_path" ./control.tar.gz |
        tar -xzO ./control
    )

    printf '%s\n' "$control_text" >> "$packages_file"
    printf 'Filename: %s\n' "$package_file" >> "$packages_file"
    printf 'Size: %s\n' "$package_size" >> "$packages_file"
    printf 'SHA256sum: %s\n\n' "$package_sha" >> "$packages_file"
done

if [ "$found" -ne 1 ]; then
    echo "No .ipk packages found in $REPO_DIR" >&2
    exit 1
fi

gzip -9n -c "$packages_file" > "$REPO_DIR/Packages.gz"
cp "$packages_file" "$REPO_DIR/Packages.manifest"

package_name=$(awk -F ': ' '$1 == "Package" {print $2; exit}' "$packages_file")
package_version=$(awk -F ': ' '$1 == "Version" {print $2; exit}' "$packages_file")
package_filename=$(awk -F ': ' '$1 == "Filename" {print $2; exit}' "$packages_file")
package_sha=$(awk -F ': ' '$1 == "SHA256sum" {print $2; exit}' "$packages_file")

cat > "$REPO_DIR/index.html" <<EOF_HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AdGuard Home Entware repository</title>
</head>
<body>
  <h1>AdGuard Home Entware repository</h1>
  <dl>
    <dt>Package</dt><dd>$package_name</dd>
    <dt>Version</dt><dd>$package_version</dd>
    <dt>Architecture</dt><dd>$PACKAGE_ARCH</dd>
    <dt>SHA-256</dt><dd><code>$package_sha</code></dd>
  </dl>
  <ul>
    <li><a href="$package_filename">$package_filename</a></li>
    <li><a href="Packages">Packages</a></li>
    <li><a href="Packages.gz">Packages.gz</a></li>
  </ul>
</body>
</html>
EOF_HTML

cat > "$PUBLIC_DIR/index.html" <<EOF_HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Entware package repositories</title>
</head>
<body>
  <h1>Entware package repositories</h1>
  <ul><li><a href="$PACKAGE_ARCH/">$PACKAGE_ARCH</a></li></ul>
</body>
</html>
EOF_HTML

: > "$PUBLIC_DIR/.nojekyll"
