#!/bin/sh

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUTPUT_DIR=${1:-"$ROOT_DIR/dist"}
VERSION=$(sed -n 's/^PKG_VERSION:=//p' "$ROOT_DIR/luci-app-openclash/Makefile" | head -n 1)
RELEASE=1
PACKAGE_NAME="luci-i18n-openclash-zh-hant_${VERSION}-${RELEASE}_all.ipk"
APK_PACKAGE_NAME="luci-i18n-openclash-zh-hant-${VERSION}-r${RELEASE}.apk"
APK_BIN=${APK_BIN:-}
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/openclash-i18n.XXXXXX")

cleanup() {
	rm -rf "$WORK_DIR"
}
trap cleanup EXIT INT TERM

mkdir -p "$OUTPUT_DIR"

cc -I"$ROOT_DIR/luci-app-openclash/tools/po2lmo/src" \
	-o "$WORK_DIR/po2lmo" \
	"$ROOT_DIR/luci-app-openclash/tools/po2lmo/src/po2lmo.c" \
	"$ROOT_DIR/luci-app-openclash/tools/po2lmo/src/template_lmo.c"

mkdir -p "$WORK_DIR/control" \
	"$WORK_DIR/data/usr/lib/lua/luci/i18n"

if command -v xattr >/dev/null 2>&1; then
	xattr -rc "$WORK_DIR" 2>/dev/null || true
fi

"$WORK_DIR/po2lmo" \
	"$ROOT_DIR/luci-app-openclash/po/zh_Hant/openclash.zh_Hant.po" \
	"$WORK_DIR/data/usr/lib/lua/luci/i18n/openclash.zh_Hant.lmo"

cat > "$WORK_DIR/control/control" <<EOF
Package: luci-i18n-openclash-zh-hant
Version: ${VERSION}-${RELEASE}
Architecture: all
Section: luci
Priority: optional
Maintainer: OpenClash 正體中文化維護者
Depends: luci-app-openclash
Description: OpenClash LuCI 正體中文語言包（zh_Hant）
EOF

printf '2.0\n' > "$WORK_DIR/debian-binary"
tar -czf "$WORK_DIR/control.tar.gz" -C "$WORK_DIR/control" .
tar -czf "$WORK_DIR/data.tar.gz" -C "$WORK_DIR/data" .

python3 - "$OUTPUT_DIR/$PACKAGE_NAME" \
	"$WORK_DIR/debian-binary" \
	"$WORK_DIR/control.tar.gz" \
	"$WORK_DIR/data.tar.gz" <<'PY'
from pathlib import Path
import sys

output, *members = sys.argv[1:]
with open(output, 'wb') as archive:
    archive.write(b'!<arch>\n')
    for member in members:
        path = Path(member)
        data = path.read_bytes()
        name = path.name + '/'
        header = (
            f'{name:<16}'
            f'{0:<12}'
            f'{0:<6}'
            f'{0:<6}'
            f'{0o100644:<8o}'
            f'{len(data):<10}'
            '`\n'
        ).encode('ascii')
        archive.write(header)
        archive.write(data)
        if len(data) % 2:
            archive.write(b'\n')
PY

if [ -z "$APK_BIN" ]; then
	APK_BIN=$(command -v apk 2>/dev/null || true)
fi

if [ -n "$APK_BIN" ] && [ -x "$APK_BIN" ]; then
	"$APK_BIN" mkpkg \
		--info 'name:luci-i18n-openclash-zh-hant' \
		--info "version:${VERSION}-r${RELEASE}" \
		--info 'description:OpenClash LuCI 正體中文語言包（zh_Hant）' \
		--info 'arch:noarch' \
		--info 'license:MIT' \
		--info 'origin:openclash-zh-tw' \
		--info 'maintainer:OpenClash 正體中文化維護者' \
		--info 'depends:luci-app-openclash' \
		--no-xattrs \
		--files "$WORK_DIR/data" \
		--output "$OUTPUT_DIR/$APK_PACKAGE_NAME"
else
	printf 'APK skipped: set APK_BIN to an apk-tools v3 binary to build %s\n' "$APK_PACKAGE_NAME"
fi

write_checksum() {
	file=$1
	directory=$(dirname "$file")
	name=$(basename "$file")
	if command -v sha256sum >/dev/null 2>&1; then
		(cd "$directory" && sha256sum "$name") > "$file.sha256"
	else
		(cd "$directory" && shasum -a 256 "$name") > "$file.sha256"
	fi
}

write_checksum "$OUTPUT_DIR/$PACKAGE_NAME"
[ -f "$OUTPUT_DIR/$APK_PACKAGE_NAME" ] && write_checksum "$OUTPUT_DIR/$APK_PACKAGE_NAME"

printf 'Built %s\n' "$OUTPUT_DIR/$PACKAGE_NAME"
[ -f "$OUTPUT_DIR/$APK_PACKAGE_NAME" ] && printf 'Built %s\n' "$OUTPUT_DIR/$APK_PACKAGE_NAME"
