#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$SCRIPT_DIR/build-package.sh"
"$SCRIPT_DIR/generate-index.sh"
